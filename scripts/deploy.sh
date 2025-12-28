#!/bin/bash
# Script déploiement AWS Observability Project
# Free Tier friendly + étape par étape
# Assurez-vous d'avoir configuré AWS CLI avec vos credentials

set -e

echo "=== Début du déploiement AWS Observability Project ==="

# 1️⃣ VPC
echo "➡️ Déploiement VPC..."
aws cloudformation create-stack \
  --stack-name vpc-stack \
  --template-body file://cloudformation/vpc.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ VPC stack lancée. Vérifiez dans la console CloudFormation."
read -p "Appuyez sur [Entrée] une fois le VPC créé et actif..."

# 2️⃣ IAM
echo "➡️ Déploiement IAM..."
aws cloudformation create-stack \
  --stack-name iam-stack \
  --template-body file://cloudformation/iam.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ IAM stack lancée."
read -p "Appuyez sur [Entrée] une fois IAM terminé..."

# 3️⃣ S3
echo "➡️ Déploiement S3..."
aws cloudformation create-stack \
  --stack-name s3-stack \
  --template-body file://cloudformation/s3.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ S3 stack lancée."
read -p "Appuyez sur [Entrée] une fois S3 terminé..."

# 4️⃣ EC2
echo "➡️ Déploiement EC2..."
aws cloudformation create-stack \
  --stack-name ec2-stack \
  --template-body file://cloudformation/ec2.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ EC2 stack lancée."
read -p "Appuyez sur [Entrée] une fois EC2 lancé (pensez à STOP après test)..."

# 5️⃣ SNS
echo "➡️ Déploiement SNS..."
aws cloudformation create-stack \
  --stack-name sns-stack \
  --template-body file://cloudformation/sns.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ SNS stack lancée."
read -p "Appuyez sur [Entrée] une fois SNS créé..."

# 6️⃣ Lambda
echo "➡️ Déploiement Lambda..."
aws cloudformation create-stack \
  --stack-name lambda-stack \
  --template-body file://cloudformation/lambda.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ Lambda stack lancée."
read -p "Appuyez sur [Entrée] une fois Lambda créée..."

# 7️⃣ CloudTrail
echo "➡️ Déploiement CloudTrail..."
aws cloudformation create-stack \
  --stack-name cloudtrail-stack \
  --template-body file://cloudformation/cloudtrail.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ CloudTrail stack lancée."
read -p "Appuyez sur [Entrée] une fois CloudTrail actif..."

# 8️⃣ EventBridge
echo "➡️ Déploiement EventBridge..."
aws cloudformation create-stack \
  --stack-name eventbridge-stack \
  --template-body file://cloudformation/eventbridge.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ EventBridge stack lancée."
read -p "Appuyez sur [Entrée] une fois EventBridge créé..."

# 9️⃣ OpenSearch
echo "➡️ Déploiement OpenSearch (1 node, Free Tier)..."
aws cloudformation create-stack \
  --stack-name opensearch-stack \
  --template-body file://cloudformation/opensearch.yml \
  --capabilities CAPABILITY_NAMED_IAM
echo "✅ OpenSearch stack lancée. Une fois active, on pourra créer l'index."

echo "=== Déploiement terminé, vérifiez chaque stack dans la console AWS ==="
echo "💡 Astuce Free Tier : STOP EC2 si pas utilisé, évitez snapshots automatiques pour OpenSearch."
