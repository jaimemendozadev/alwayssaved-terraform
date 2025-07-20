#!/bin/bash
set -e

echo "==== Logging setup to CloudWatch and EC2 console ===="
exec > >(tee /var/log/always_saved_frontend_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Waiting for any automatic apt processes to finish ===="
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt lock to release..."
  sleep 5
done

echo "==== Installing Dependencies ===="
sudo apt-get update -y
sudo apt-get install -y unzip curl gnupg lsb-release jq

echo "==== Installing AWS CLI ===="
if ! command -v aws &>/dev/null; then
  cd /tmp
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  sudo ln -s /usr/local/bin/aws /usr/bin/aws || true
fi

echo "==== Installing Docker ===="
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sleep 10

echo "==== Authenticating Docker with AWS ECR ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}

echo "==== Pulling Frontend Docker Image ===="
sudo docker pull ${ECR_URL}

echo "==== Discovering LLM (FastAPI) Private IP from EC2 tag ===="
LLM_PRIVATE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=always-saved-llm-service" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text \
  --region us-east-1)

echo "Discovered LLM IP: $LLM_PRIVATE_IP"

echo "==== Fetching SQS URL from tag ===="
EXTRACTOR_PUSH_QUEUE_URL=$(aws sqs list-queues \
  --query "QueueUrls[?contains(@, 'always-saved-extractor-push-queue')]" \
  --output text \
  --region us-east-1)

echo "Retrieved EXTRACTOR_PUSH_QUEUE_URL: $EXTRACTOR_PUSH_QUEUE_URL"


echo "==== Fetching Clerk Secret from SSM ===="
CLERK_SECRET_KEY=$(aws ssm get-parameter --name "/alwayssaved/CLERK_SECRET_KEY" --with-decryption --query "Parameter.Value" --output text)

echo "Retrieved CLERK_SECRET_KEY: $CLERK_SECRET_KEY"


echo "==== Creating .env.production file ===="
sudo tee /home/ubuntu/.env.production > /dev/null <<EOF
PRODUCTION_BACKEND_BASE_URL=http://${LLM_PRIVATE_IP}:8000
CLERK_SECRET_KEY=${CLERK_SECRET_KEY}
EXTRACTOR_PUSH_QUEUE_URL=${EXTRACTOR_PUSH_QUEUE_URL}
EOF

echo "==== Waiting for FastAPI server at $LLM_PRIVATE_IP:8000 to become available ===="
MAX_RETRIES=20
RETRY_DELAY=5
COUNTER=0

until curl -s --connect-timeout 2 http://${LLM_PRIVATE_IP}:8000/health >/dev/null; do
  echo "FastAPI not up yet... retrying ($((COUNTER + 1))/$MAX_RETRIES)"
  sleep $RETRY_DELAY
  COUNTER=$((COUNTER + 1))
  if [ $COUNTER -ge $MAX_RETRIES ]; then
    echo "❌ FastAPI did not become available in time. Aborting setup."
    exit 1
  fi
done

echo "✅ FastAPI is available! Proceeding..."

echo "==== Running Frontend Container ===="
sudo docker run -d \
  --env-file /home/ubuntu/.env.production \
  -p 80:3000 \
  --name always-saved-frontend \
  ${ECR_URL}