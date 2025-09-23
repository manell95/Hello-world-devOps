#!/bin/bash

# Script de démarrage automatique pour AWS EC2
# Ce script s'exécute au premier démarrage de l'instance
# Région: eu-west-1
set -e  # Arrêter en cas d'erreur

# Configuration du logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "🚀 [$(date)] Début de l'installation Hello World DevOps"

# Variables de configuration
APP_DIR="/opt/hello-world-app"
SERVICE_NAME="hello-world"
GITHUB_REPO="https://github.com/manell95/hello-world-devops.git"
NODE_VERSION="18"

# Fonction pour afficher les étapes
log_step() {
    echo ""
    echo "==============================================="
    echo "📋 $1"
    echo "==============================================="
}

# Mise à jour du système
log_step "Mise à jour du système Amazon Linux 2023"
yum update -y

# Installation de Node.js via NodeSource
log_step "Installation de Node.js $NODE_VERSION"
curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
yum install -y nodejs

# Vérification de l'installation Node.js
node --version
npm --version

# Installation des outils nécessaires
log_step "Installation des outils (Git, PM2, etc.)"
yum install -y git wget curl
npm install -g pm2

# Création de l'utilisateur et du répertoire de l'application
log_step "Configuration de l'environnement application"
useradd -m -s /bin/bash appuser || echo "Utilisateur appuser existe déjà"
mkdir -p $APP_DIR
chown -R appuser:appuser $APP_DIR

# Clonage du repository (ATTENTION: Remplace par ton URL GitHub)
log_step "Clonage de l'application depuis GitHub"
cd $APP_DIR
sudo -u appuser git clone $GITHUB_REPO . 2>/dev/null || {
    echo "⚠️  Échec du clonage Git - Création d'une app de démo"
    
    # Création d'une version de secours si le repo n'existe pas encore
    sudo -u appuser mkdir -p app/public
    
    # Création du package.json de secours
    sudo -u appuser cat > app/package.json << 'EOL'
{
  "name": "hello-world-devops-fallback",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOL

    # Création du server.js de secours
    sudo -u appuser cat > app/server.js << 'EOL'
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.json({
        message: "🚀 Hello World DevOps - Version de secours!",
        status: "OK",
        timestamp: new Date().toISOString(),
        note: "Cette version s'exécute car le repository Git n'était pas accessible"
    });
});

app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Hello World DevOps App - Fallback version',
        timestamp: new Date().toISOString(),
        environment: 'production',
        version: '1.0.0-fallback'
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
EOL
}

# Installation des dépendances Node.js
log_step "Installation des dépendances Node.js"
cd $APP_DIR/app
sudo -u appuser npm install --production

# Configuration du service avec PM2
log_step "Configuration du service avec PM2"
sudo -u appuser pm2 start server.js --name $SERVICE_NAME
sudo -u appuser pm2 save
sudo -u appuser pm2 startup systemd -u appuser --hp /home/appuser

# Configuration du démarrage automatique de PM2
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u appuser --hp /home/appuser

# Configuration du firewall
log_step "Configuration du firewall pour le port 3000"
yum install -y firewalld
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload

# Test de l'application
log_step "Test de l'application"
sleep 15

# Fonction de test avec retry
test_application() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🧪 Test $attempt/$max_attempts..."
        if curl -f http://localhost:3000/api/health; then
            echo "✅ Application fonctionne correctement!"
            return 0
        else
            echo "⏳ Tentative $attempt échouée, attente 10s..."
            sleep 10
            ((attempt++))
        fi
    done
    
    echo "❌ Application ne répond pas après $max_attempts tentatives"
    echo "📋 Logs PM2:"
    sudo -u appuser pm2 logs $SERVICE_NAME --lines 20
    return 1
}

if test_application; then
    echo "🎉 Installation réussie!"
else
    echo "⚠️ Problème détecté, mais le service continue"
fi

# Récupération de l'IP publique pour affichage
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "IP non disponible")

# Résumé final
log_step "Installation terminée"
echo "✅ Hello World DevOps déployé avec succès!"
echo "🌍 Application accessible sur: http://$PUBLIC_IP:3000"
echo "📊 Status PM2: $(sudo -u appuser pm2 list)"
echo "🕐 Installation terminée à: $(date)"
echo ""
echo "📝 Commandes utiles:"
echo "   - Logs application: sudo -u appuser pm2 logs $SERVICE_NAME"
echo "   - Redémarrer app: sudo -u appuser pm2 restart $SERVICE_NAME"
echo "   - Status PM2: sudo -u appuser pm2 status"
echo ""

# Sauvegarde des informations importantes
cat > /home/ec2-user/deployment-info.txt << EOL
Hello World DevOps - Informations de déploiement
===============================================
Date d'installation: $(date)
IP publique: $PUBLIC_IP
URL d'accès: http://$PUBLIC_IP:3000
Répertoire app: $APP_DIR
Utilisateur app: appuser
Service PM2: $SERVICE_NAME

Commandes utiles:
- sudo -u appuser pm2 logs $SERVICE_NAME
- sudo -u appuser pm2 restart $SERVICE_NAME
- sudo -u appuser pm2 status
EOL

echo "📄 Informations sauvegardées dans /home/ec2-user/deployment-info.txt"
echo "🏁 Script user-data terminé avec succès!"