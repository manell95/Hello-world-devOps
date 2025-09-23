#!/bin/bash

# Script de déploiement Hello World DevOps sur AWS EC2
# Région: eu-west-1
# Usage: ./deploy-to-aws.sh

set -e

# Configuration - MODIFIE CES VALEURS
INSTANCE_NAME="hello-world-devops"
KEY_PAIR_NAME="hello-world-key"
SECURITY_GROUP_NAME="hello-world-sg"
INSTANCE_TYPE="t3.micro"
AWS_REGION="eu-west-1"

# AMI Amazon Linux 2023 pour eu-west-1 (vérifié le 2024)
AMI_ID="ami-0905a3c97561e0b69"  # Amazon Linux 2023

echo "🚀 Déploiement Hello World DevOps sur AWS EC2"
echo "==============================================="
echo "📍 Région: $AWS_REGION"
echo "🔑 Clé: $KEY_PAIR_NAME"
echo "🖥️  Instance: $INSTANCE_TYPE"
echo "==============================================="

# Fonction pour afficher les étapes
log_step() {
    echo ""
    echo "📋 $1"
    echo "---"
}

# Vérification des prérequis
log_step "Vérification des prérequis"

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI n'est pas installé"
    echo "💡 Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI n'est pas configuré"
    echo "💡 Exécuter: aws configure"
    exit 1
fi

# Vérification de la clé
if ! aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME --region $AWS_REGION &> /dev/null; then
    echo "❌ La paire de clés '$KEY_PAIR_NAME' n'existe pas"
    echo "💡 Créer avec: aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --region $AWS_REGION --query 'KeyMaterial' --output text > ~/.ssh/$KEY_PAIR_NAME.pem"
    exit 1
fi

if [ ! -f ~/.ssh/$KEY_PAIR_NAME.pem ]; then
    echo "❌ Le fichier de clé ~/.ssh/$KEY_PAIR_NAME.pem n'existe pas"
    exit 1
fi

echo "✅ Prérequis OK"

# Création du groupe de sécurité
log_step "Configuration du groupe de sécurité"

if aws ec2 describe-security-groups --group-names $SECURITY_GROUP_NAME --region $AWS_REGION &> /dev/null; then
    echo "ℹ️  Groupe de sécurité '$SECURITY_GROUP_NAME' existe déjà"
else
    echo "🔒 Création du groupe de sécurité..."
    aws ec2 create-security-group \
        --group-name $SECURITY_GROUP_NAME \
        --description "Security group for Hello World DevOps application" \
        --region $AWS_REGION
    echo "✅ Groupe de sécurité créé"
fi

# Configuration des règles du groupe de sécurité
echo "🔧 Configuration des règles de sécurité..."

# SSH (port 22)
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NAME \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION 2>/dev/null || echo "   → Règle SSH existe déjà"

# Application (port 3000)
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NAME \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION 2>/dev/null || echo "   → Règle port 3000 existe déjà"

echo "✅ Règles de sécurité configurées"

# Vérification que le script user-data existe
if [ ! -f "scripts/user-data.sh" ]; then
    echo "❌ Le script scripts/user-data.sh n'existe pas"
    exit 1
fi

# Lancement de l'instance EC2
log_step "Lancement de l'instance EC2"

echo "🖥️  Création de l'instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_PAIR_NAME \
    --security-groups $SECURITY_GROUP_NAME \
    --user-data file://scripts/user-data.sh \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=HelloWorldDevOps}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "❌ Erreur lors de la création de l'instance"
    exit 1
fi

echo "✅ Instance créée: $INSTANCE_ID"

# Attendre que l'instance soit en cours d'exécution
log_step "Démarrage de l'instance"
echo "⏳ Attente du démarrage (cela peut prendre 2-3 minutes)..."

aws ec2 wait instance-running \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION

echo "✅ Instance démarrée"

# Récupérer les informations de l'instance
log_step "Récupération des informations"

INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $AWS_REGION \
    --query 'Reservations[0].Instances[0]')

PUBLIC_IP=$(echo $INSTANCE_INFO | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo $INSTANCE_INFO | jq -r '.PrivateIpAddress')

# Attendre que l'application soit prête
log_step "Vérification de l'application"
echo "⏳ Attente de l'installation de l'application (5-10 minutes)..."
echo "📝 L'installation se fait via le script user-data en arrière-plan"

# Test de l'application avec retry
test_app() {
    local max_attempts=20
    local attempt=1
    
    echo "🧪 Test de l'application sur http://$PUBLIC_IP:3000"
    
    while [ $attempt -le $max_attempts ]; do
        echo "   Tentative $attempt/$max_attempts..."
        
        if curl -s -f http://$PUBLIC_IP:3000/api/health > /dev/null 2>&1; then
            echo "✅ Application accessible!"
            return 0
        fi
        
        sleep 30
        ((attempt++))
    done
    
    echo "⚠️  Application pas encore accessible (normal, installation en cours)"
    echo "📋 Vérifier les logs avec: ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$PUBLIC_IP"
    return 1
}

# Test optionnel (ne fait pas échouer le déploiement)
test_app || true

# Résumé final
log_step "Déploiement terminé!"
echo ""
echo "🎉 Instance EC2 déployée avec succès!"
echo ""
echo "📋 INFORMATIONS DE CONNEXION"
echo "==============================================="
echo "🆔 Instance ID: $INSTANCE_ID"
echo "🌍 IP Publique: $PUBLIC_IP"
echo "🏠 IP Privée: $PRIVATE_IP"
echo "🔗 Application: http://$PUBLIC_IP:3000"
echo "🔑 SSH: ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$PUBLIC_IP"
echo ""
echo "📋 COMMANDES UTILES"
echo "==============================================="
echo "# Se connecter en SSH"
echo "ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$PUBLIC_IP"
echo ""
echo "# Vérifier les logs d'installation"
echo "sudo tail -f /var/log/user-data.log"
echo ""
echo "# Vérifier l'application"
echo "curl http://$PUBLIC_IP:3000/api/health"
echo ""
echo "# Arrêter l'instance (économiser les coûts)"
echo "aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo ""
echo "# Supprimer l'instance"
echo "aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"
echo ""

# Sauvegarde des informations
cat > deployment-info.txt << EOL
Hello World DevOps - Déploiement AWS EC2
========================================
Date: $(date)
Instance ID: $INSTANCE_ID
IP Publique: $PUBLIC_IP
IP Privée: $PRIVATE_IP
Région: $AWS_REGION
Application: http://$PUBLIC_IP:3000
SSH: ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$PUBLIC_IP
EOL

echo "💾 Informations sauvegardées dans deployment-info.txt"
echo ""
echo "⏰ L'application sera disponible dans 5-10 minutes à l'adresse:"
echo "   🔗 http://$PUBLIC_IP:3000"