#!/bin/bash
set -e

LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=========================================="
echo "🚀 Début installation Amazon Linux"
echo "📅 $(date)"
echo "=========================================="

# Mise à jour du système
echo "📦 Mise à jour du système..."
dnf update -y

# Installer Node.js 20.x
echo "📥 Installation de Node.js..."
dnf install -y nodejs npm git

echo "✅ Node.js: $(node --version)"
echo "✅ NPM: $(npm --version)"

# Installer PM2 globalement
echo "📥 Installation de PM2..."
npm install -g pm2

# Créer l'utilisateur nodeapp
echo "👤 Création utilisateur nodeapp..."
useradd -m -s /bin/bash nodeapp || echo "Utilisateur déjà existant"

# Cloner le repository
echo "📂 Clonage du repository..."
rm -rf /home/nodeapp/app
git clone https://github.com/manell95/Hello-world-devOps.git /home/nodeapp/app

# Donner les permissions
chown -R nodeapp:nodeapp /home/nodeapp/app

# Installer les dépendances npm
echo "📦 Installation des dépendances..."
cd /home/nodeapp/app/app
sudo -u nodeapp npm install --production

# Vérifier que server.js existe
if [ ! -f "server.js" ]; then
    echo "❌ ERREUR: server.js introuvable!"
    exit 1
fi

# Démarrer l'application avec PM2
echo "⚙️ Démarrage de l'application..."
sudo -u nodeapp pm2 delete hello-world-app 2>/dev/null || true
sudo -u nodeapp pm2 start server.js --name hello-world-app

# Sauvegarder la config PM2
sudo -u nodeapp pm2 save

# Configurer PM2 au démarrage
env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u nodeapp --hp /home/nodeapp

# Ouvrir le port 3000 dans le firewall (si activé)
if systemctl is-active --quiet firewalld; then
    echo "🔓 Configuration du firewall..."
    firewall-cmd --permanent --add-port=3000/tcp
    firewall-cmd --reload
fi

# Afficher le statut
echo ""
echo "📊 Statut de l'application:"
sudo -u nodeapp pm2 status

# Afficher l'IP publique
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo ""
echo "=========================================="
echo "✅ Installation terminée avec succès!"
echo "=========================================="
echo ""
echo "🌐 URL: http://${PUBLIC_IP}:3000"
echo ""
echo "📝 Commandes utiles:"
echo "   Logs: sudo -u nodeapp pm2 logs hello-world-app"
echo "   Statut: sudo -u nodeapp pm2 status"
echo "   Redémarrer: sudo -u nodeapp pm2 restart hello-world-app"
echo ""
echo "📅 $(date)"
echo "=========================================="
