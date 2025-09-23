#!/bin/bash
# Script d'initialisation EC2 pour Hello World DevOps
# Installe Node.js, git, clone l'app et la démarre

set -e

# Installer les dépendances
sudo yum update -y
sudo yum install -y git

# Installer Node.js (Amazon Linux 2023)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Cloner le dépôt de l'application (à personnaliser)
git clone https://github.com/votre-utilisateur/hello-world-devops.git /home/ec2-user/app
cd /home/ec2-user/app

# Installer les dépendances Node.js
npm install

# Démarrer l'application (adapter si besoin)
npm run start &

echo "Application Hello World DevOps déployée et démarrée !"