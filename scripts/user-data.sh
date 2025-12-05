#!/bin/bash

# ============================================================================
# Script de démarrage automatique pour instance EC2
# Installe Node.js, clone le repo GitHub et lance l'application
# ============================================================================

set -e  # Arrêter en cas d'erreur

# Configuration des logs
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=========================================="
echo "🚀 Début du script User Data"
echo "📅 Date: $(date)"
echo "=========================================="

# Mise à jour du système
echo ""
echo "📦 Mise à jour des paquets système..."
apt-get update -y
apt-get upgrade -y

# Installation de Node.js (version LTS 20.x)
echo ""
echo "📥 Installation de Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Vérification des versions installées
echo ""
echo "✅ Vérification des installations:"
echo "   Node.js version: $(node --version)"
echo "   NPM version: $(npm --version)"

# Installation de Git
echo ""
echo "📥 Installation de Git..."
apt-get install -y git

# Installation de PM2 (Process Manager pour Node.js)
echo ""
echo "📥 Installation de PM2 globalement..."
npm install -g pm2

# Créer un utilisateur dédié pour l'application (bonne pratique de sécurité)
echo ""
echo "👤 Création de l'utilisateur 'nodeapp'..."
if ! id -u nodeapp > /dev/null 2>&1; then
    useradd -m -s /bin/bash nodeapp
    echo "   ✅ Utilisateur 'nodeapp' créé"
else
    echo "   ℹ️  Utilisateur 'nodeapp' existe déjà"
fi

# Définir le répertoire de l'application
APP_DIR="/home/nodeapp/app"

# Supprimer l'ancien dossier s'il existe
if [ -d "$APP_DIR" ]; then
    echo ""
    echo "🗑️  Suppression de l'ancien répertoire..."
    rm -rf $APP_DIR
fi

# Cloner le repository GitHub
echo ""
echo "📂 Clonage du repository GitHub..."
sudo -u nodeapp git clone https://github.com/manell95/Hello-world-devOps.git $APP_DIR

# Vérifier que le clonage a réussi
if [ ! -d "$APP_DIR" ]; then
    echo "❌ ERREUR: Le clonage du repository a échoué!"
    exit 1
fi

# Se placer dans le dossier de l'application
cd $APP_DIR/app

# Vérifier que le dossier app existe
if [ ! -f "package.json" ]; then
    echo "❌ ERREUR: package.json non trouvé dans app/!"
    ls -la
    exit 1
fi

# Installation des dépendances npm
echo ""
echo "📦 Installation des dépendances npm..."
sudo -u nodeapp npm install --production

# Vérifier que server.js existe
if [ ! -f "server.js" ]; then
    echo "❌ ERREUR: server.js non trouvé!"
    ls -la
    exit 1
fi

# Arrêter l'ancienne instance PM2 si elle existe
echo ""
echo "🛑 Arrêt des anciennes instances PM2..."
sudo -u nodeapp pm2 delete hello-world-app 2>/dev/null || true

# Démarrer l'application avec PM2
echo ""
echo "⚙️  Démarrage de l'application avec PM2..."
sudo -u nodeapp pm2 start server.js --name "hello-world-app"

# Sauvegarder la configuration PM2
sudo -u nodeapp pm2 save

# Configurer PM2 pour démarrer automatiquement au boot
echo ""
echo "🔧 Configuration du démarrage automatique..."
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u nodeapp --hp /home/nodeapp

# Vérifier le statut de l'application
echo ""
echo "📊 Statut de l'application:"
sudo -u nodeapp pm2 status
sudo -u nodeapp pm2 logs hello-world-app --lines 20 --nostream

# Ouvrir le port 3000 dans le firewall (si UFW est activé)
if command -v ufw &> /dev/null; then
    echo ""
    echo "🔓 Configuration du firewall..."
    ufw allow 3000/tcp
    ufw allow 22/tcp
fi

# Afficher les informations de connexion
echo ""
echo "=========================================="
echo "✅ Installation terminée avec succès!"
echo "=========================================="
echo ""
echo "📍 Informations de connexion:"
echo "   URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "   Port: 3000"
echo ""
echo "📝 Commandes utiles:"
echo "   Voir les logs: sudo -u nodeapp pm2 logs hello-world-app"
echo "   Voir le statut: sudo -u nodeapp pm2 status"
echo "   Redémarrer: sudo -u nodeapp pm2 restart hello-world-app"
echo ""
echo "📅 Date de fin: $(date)"
echo "=========================================="