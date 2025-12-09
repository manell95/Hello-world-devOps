#!/bin/bash
set -e
LOG="/var/log/user-data.log"
exec > >(tee -a $LOG) 2>&1

echo "🚀 Installation EC2 - $(date)"

# Mise à jour
dnf update -y

# Node.js 20
dnf install -y nodejs npm git

# PM2
npm install -g pm2

# Utilisateur
useradd -m -s /bin/bash nodeapp 2>/dev/null || true

# Clone
rm -rf /home/nodeapp/app
git clone https://github.com/manell95/Hello-world-devOps.git /home/nodeapp/app
chown -R nodeapp:nodeapp /home/nodeapp/app

# Installation
cd /home/nodeapp/app/app
sudo -u nodeapp npm ci --production

# Démarrage
sudo -u nodeapp pm2 delete hello-world-app 2>/dev/null || true
sudo -u nodeapp pm2 start server.js --name hello-world-app
sudo -u nodeapp pm2 save

# Startup
env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u nodeapp --hp /home/nodeapp

# IP
IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "✅ Installation terminée - http://${IP}:3000"