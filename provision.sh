#!/bin/bash

# WARNING: script vulnérable pour usage pédagogique uniquement

AWS_ACCESS_KEY="AKIA123456789-EXEMPLE"
AWS_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCY-EXEMPLE"
REGION="eu-west-3"
BUCKET_NAME="tp-insecure-logs-$(date +%s)"
TOKEN="123456-SECRET-TOKEN"

# Configuration du profil AWS CLI
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$REGION

# Création d’un bucket
aws s3 mb s3://$BUCKET_NAME

# Configura
aws s3api put-bucket-acl --bucket $BUCKET_NAME --acl public-read

# Création d’un rôle IAM avec permissions très larges
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role --role-name InsecureEC2Role --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name InsecureEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Création d’une instance EC2 avec user_data injectant le token
USER_DATA=$(cat <<EOF
#!/bin/bash
echo "Starting app..."
echo "TOKEN=$TOKEN" > /etc/app_config.env
aws s3 cp /etc/app_config.env s3://$BUCKET_NAME/config-$(date +%s).txt
EOF
)

aws ec2 run-instances \
  --image-id ami-0323c3dd2da7fb37d \
  --count 1 \
  --instance-type t2.micro \
  --iam-instance-profile Name=InsecureEC2Role \
  --user-data "$USER_DATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TP-Insecure}]'

echo "Instance lancée. Bucket créé : $BUCKET_NAME"
