#!/bin/bash
# Script déploiement AWS Observability Project
# Free Tier friendly + étape par étape
# Mise à jour si le stack existe déjà

set -e

function deploy_stack {
  STACK_NAME=$1
  TEMPLATE_FILE=$2

  echo "➡️ Déploiement $STACK_NAME..."
  
  # Vérifie si le stack existe
  if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
    echo "⚠️ $STACK_NAME existe déjà, mise à jour..."
    aws cloudformation update-stack \
      --stack-name $STACK_NAME \
      --template-body file://$TEMPLATE_FILE \
      --capabilities CAPABILITY_NAMED_IAM || echo "🔹 Rien à mettre à jour pour $STACK_NAME"
  else
    aws cloudformation create-stack \
      --stack-name $STACK_NAME \
      --template-body file://$TEMPLATE_FILE \
      --capabilities CAPABILITY_NAMED_IAM
  fi

  echo "✅ $STACK_NAME stack traitée."
  read -p "Appuyez sur [Entrée] une fois $STACK_NAME actif..."
}

echo "=== Début du déploiement AWS Observability Project ==="

deploy_stack "vpc-stack" "cloudformation/vpc.yml"
deploy_stack "iam-stack" "cloudformation/iam.yml"
deploy_stack "s3-stack" "cloudformation/s3.yml"
deploy_stack "ec2-stack" "cloudformation/ec2.yml"
deploy_stack "sns-stack" "cloudformation/sns.yml"
deploy_stack "lambda-stack" "cloudformation/lambda.yml"
deploy_stack "cloudtrail-stack" "cloudformation/cloudtrail.yml"
deploy_stack "eventbridge-stack" "cloudformation/eventbridge.yml"
deploy_stack "opensearch-stack" "cloudformation/opensearch.yml"

echo "=== Déploiement terminé, vérifiez chaque stack dans la console AWS ==="
echo "💡 Astuce Free Tier : STOP EC2 si pas utilisé, évitez snapshots automatiques pour OpenSearch."
