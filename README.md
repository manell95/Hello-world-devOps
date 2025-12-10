📋 Table des Matières

Vue d'ensemble
Fonctionnalités
Architecture
Technologies Utilisées
Prérequis
Installation
Déploiement
Configuration CI/CD
Structure du Projet
Utilisation
Sécurité
Roadmap
Contribuer
Auteur


🎯 Vue d'ensemble
Ce projet démontre la mise en place d'une infrastructure DevOps complète avec :

✅ Déploiement automatisé sur AWS EC2
✅ CI/CD avec GitHub Actions
✅ Infrastructure as Code avec scripts Shell
✅ Configuration automatique via User Data
✅ Application Node.js minimale mais fonctionnelle

🎬 Démonstration
Code Push → GitHub Actions → Déploiement AWS → Application Live
    ↓              ↓                ↓                  ↓
  Git push    Tests & Build    SSH Deploy       http://your-ip:3000
Temps de déploiement : ~2 minutes de bout en bout

✨ Fonctionnalités
🤖 Automatisation Complète

Pipeline CI/CD : Déploiement automatique à chaque push sur master
Configuration EC2 : Instance configurée automatiquement au démarrage
Zero Downtime : Redémarrage intelligent du serveur

🏗️ Infrastructure as Code

Scripts Shell réutilisables et modulaires
Configuration centralisée
Gestion des dépendances automatisée

🔒 Sécurité

Gestion des secrets via GitHub Secrets
Connexion SSH sécurisée
Variables d'environnement isolées


🏛️ Architecture
┌─────────────────┐
│   Developer     │
│   (Git Push)    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│    GitHub Repository        │
│  ┌─────────────────────┐   │
│  │  GitHub Actions     │   │
│  │  - Build            │   │
│  │  - Test (future)    │   │
│  │  - Deploy           │   │
│  └──────────┬──────────┘   │
└─────────────┼───────────────┘
              │ SSH
              ▼
┌─────────────────────────────┐
│       AWS EC2 Instance      │
│                             │
│  ┌────────────────────┐    │
│  │  User Data Script  │    │
│  │  - Install Node.js │    │
│  │  - Clone Repo      │    │
│  │  - Start Server    │    │
│  └────────────────────┘    │
│                             │
│  ┌────────────────────┐    │
│  │   Node.js Server   │    │
│  │   Port: 3000       │    │
│  └────────────────────┘    │
└──────────────┬──────────────┘
               │
               ▼
         ┌─────────┐
         │  Users  │
         └─────────┘
🔄 Flux de Déploiement

Push du code sur GitHub
Déclenchement du workflow GitHub Actions
Connexion SSH à l'instance EC2
Pull du nouveau code
Installation des dépendances (npm install)
Redémarrage du serveur Node.js
Application live accessible sur http://[EC2-IP]:3000


🛠️ Technologies Utilisées
Backend

Node.js v18+ - Runtime JavaScript
Express.js (optionnel) - Framework web minimal

Cloud & Infrastructure

AWS EC2 - Instance de calcul (t2.micro)
AWS CLI - Gestion programmatique d'AWS
Ubuntu 20.04 LTS - Système d'exploitation

DevOps

GitHub Actions - CI/CD
Shell Scripts - Automatisation
SSH - Déploiement sécurisé
PM2 (recommandé) - Process manager Node.js

Outils de Développement

Git - Gestion de versions
npm - Gestionnaire de paquets


⚙️ Prérequis
Avant de commencer, assurez-vous d'avoir :
Sur votre machine locale
bash# Node.js et npm
node --version  # v18.0.0 ou supérieur
npm --version   # v9.0.0 ou supérieur

# Git
git --version

# AWS CLI (optionnel mais recommandé)
aws --version
Compte AWS

✅ Compte AWS actif
✅ Accès à EC2
✅ Paire de clés SSH créée
✅ Groupe de sécurité configuré (ports 22, 80, 3000)

GitHub

✅ Repository créé
✅ Accès aux GitHub Actions
✅ Secrets configurés (voir Configuration CI/CD)


📦 Installation
1️⃣ Cloner le Repository
bashgit clone https://github.com/manell95/Hello-world-devOps.git
cd Hello-world-devOps
2️⃣ Installer les Dépendances
bashnpm install
3️⃣ Configuration Locale
Créez un fichier .env basé sur .env.example :
bashcp .env.example .env
Éditez .env avec vos valeurs :
envNODE_ENV=development
PORT=3000
AWS_REGION=eu-west-3
4️⃣ Lancer en Local
bash# Mode développement
npm run dev

# Mode production
npm start
Ouvrez votre navigateur : http://localhost:3000

🚀 Déploiement
Déploiement Manuel sur EC2
Étape 1 : Créer une Instance EC2
bash# Via AWS CLI
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key-name \
  --security-groups your-security-group \
  --user-data file://user-data.sh
Étape 2 : Configurer le Groupe de Sécurité
Autoriser les ports suivants :
PortProtocoleSourceDescription22TCPVotre IPSSH80TCP0.0.0.0/0HTTP3000TCP0.0.0.0/0Node.js
Étape 3 : Connexion SSH et Déploiement
bash# Connexion à l'instance
ssh -i your-key.pem ubuntu@[EC2-PUBLIC-IP]

# Cloner le projet
git clone https://github.com/manell95/Hello-world-devOps.git
cd Hello-world-devOps

# Installer et lancer
npm install
npm start
Déploiement Automatique via GitHub Actions
Voir la section Configuration CI/CD ci-dessous.

🔧 Configuration CI/CD
Configurer GitHub Secrets

Allez dans Settings → Secrets and variables → Actions
Ajoutez les secrets suivants :

SecretDescriptionExempleAWS_ACCESS_KEY_IDClé d'accès AWSAKIAIOSFODNN7EXAMPLEAWS_SECRET_ACCESS_KEYClé secrète AWSwJalrXUtnFEMI/K7MDENG/...EC2_PRIVATE_KEYContenu de votre fichier .pem-----BEGIN RSA PRIVATE KEY-----...EC2_HOSTIP publique de l'instance54.123.45.67EC2_USERUtilisateur SSHubuntu
Workflow GitHub Actions
Le fichier .github/workflows/deploy.yml est automatiquement déclenché sur chaque push vers master.
yaml# Exemple simplifié
name: Deploy to AWS EC2

on:
  push:
    branches: [ master ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to EC2
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_PRIVATE_KEY }}
          script: |
            cd Hello-world-devOps
            git pull origin master
            npm install
            pm2 restart all || npm start

📁 Structure du Projet
Hello-world-devOps/
│
├── .github/
│   └── workflows/
│       └── deploy.yml          # Workflow CI/CD
│
├── scripts/
│   ├── deploy-to-aws.sh        # Script de déploiement
│   └── setup-ec2.sh            # Configuration EC2
│
├── src/                         # Code source (à créer)
│   └── server.js               # Serveur Node.js
│
├── public/                      # Fichiers statiques (à créer)
│   └── index.html              # Page HTML
│
├── tests/                       # Tests unitaires (à créer)
│
├── .env.example                 # Template variables d'environnement
├── .gitignore                   # Fichiers ignorés par Git
├── package.json                 # Dépendances Node.js
├── README.md                    # Ce fichier
├── server.js                    # Point d'entrée
└── user-data.sh                # Script d'initialisation EC2

🎮 Utilisation
Commandes Disponibles
bash# Démarrer le serveur
npm start

# Mode développement avec rechargement auto
npm run dev

# Lancer les tests (à implémenter)
npm test

# Vérifier le code (linting)
npm run lint

# Déployer manuellement
./scripts/deploy-to-aws.sh
API Endpoints
MéthodeEndpointDescriptionGET/Page d'accueilGET/healthHealth checkGET/api/statusStatut de l'application
Exemple d'Utilisation
bash# Test local
curl http://localhost:3000

# Test sur EC2
curl http://[EC2-IP]:3000

# Health check
curl http://[EC2-IP]:3000/health

🔒 Sécurité
Bonnes Pratiques Implémentées
✅ Secrets GitHub : Credentials stockés de manière sécurisée
✅ Fichier .gitignore : Exclusion des fichiers sensibles
✅ .env : Variables d'environnement isolées
✅ Connexions SSH : Authentification par clé privée
⚠️ Points d'Attention

Ne jamais commiter de clés privées (.pem)
Restreindre les groupes de sécurité AWS aux IPs nécessaires
Utiliser IAM roles pour les permissions AWS
Activer MFA sur votre compte AWS
Logs de sécurité : Surveiller les tentatives de connexion

Checklist de Sécurité
bash# Vérifier qu'aucun secret n'est exposé
git secrets --scan

# Analyser les dépendances
npm audit

# Mettre à jour les packages
npm update

# Vérifier les permissions
ls -la *.pem  # Ne doit PAS apparaître

🗺️ Roadmap
✅ Version 1.0 (Actuelle)

 Serveur Node.js minimal
 Déploiement manuel sur EC2
 CI/CD avec GitHub Actions
 User data script

🚧 Version 2.0 (En cours)

 Tests unitaires et d'intégration
 Monitoring avec CloudWatch
 Logs centralisés
 Health checks automatiques

🔮 Version 3.0 (Futur)

 Migration vers Terraform/CloudFormation
 Load Balancer + Auto Scaling
 Conteneurisation avec Docker
 Déploiement sur Kubernetes (EKS)
 Multi-région AWS
 Blue/Green deployment


🤝 Contribuer
Les contributions sont les bienvenues ! Voici comment participer :
1. Fork le projet
bashgit clone https://github.com/votre-username/Hello-world-devOps.git
2. Créer une branche
bashgit checkout -b feature/ma-nouvelle-fonctionnalite
3. Commiter vos changements
bashgit commit -m "feat: ajout de la fonctionnalité X"
4. Pusher vers la branche
bashgit push origin feature/ma-nouvelle-fonctionnalite
5. Ouvrir une Pull Request
Suivez le template de PR fourni.

📝 License
Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

👤 Auteur
manell95

GitHub: @manell95
LinkedIn: www.linkedin.com/in/nick-manell-louocdom-724798280
Email: louocdomkamdem@gmail.com


🙏 Remerciements

AWS Documentation
GitHub Actions Documentation
Node.js Documentation


📚 Resources Utiles

Guide AWS EC2
GitHub Actions Best Practices
Node.js Best Practices
DevOps Roadmap


❓ FAQ
<details>
<summary><strong>Comment changer le port du serveur ?</strong></summary>
Modifiez la variable PORT dans votre fichier .env :
envPORT=8080
Puis redémarrez le serveur.
</details>
<details>
<summary><strong>Le déploiement échoue, que faire ?</strong></summary>

Vérifiez les logs GitHub Actions
Testez la connexion SSH manuellement
Vérifiez que les secrets GitHub sont corrects
Consultez les logs EC2 : sudo journalctl -u your-service

</details>
<details>
<summary><strong>Comment ajouter HTTPS ?</strong></summary>
Utilisez Let's Encrypt avec Certbot :
bashsudo apt install certbot
sudo certbot --nginx -d votre-domaine.com
</details>
<details>
<summary><strong>Comment monitorer l'application ?</strong></summary>
Installez PM2 pour les logs et le monitoring :
bashnpm install -g pm2
pm2 start server.js
pm2 monit
</details>

<div align="center">
⭐ Si ce projet vous aide, n'hésitez pas à lui donner une étoile !
Made with ❤️ by manell95
⬆ Retour en haut
</div>
