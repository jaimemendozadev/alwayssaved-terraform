#!/bin/bash
set -e

exec > >(tee /var/log/always_saved_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== System Setup ===="
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt..."
  sleep 5
done

sudo apt-get update -y
sudo apt-get install -y unzip systemd curl gnupg lsb-release

echo "==== Installing AWS CLI ===="
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
fi
aws --version

echo "==== Installing Docker ===="
curl -fsSL https://get.docker.com | sh
sudo systemctl daemon-reexec
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "==== Docker Auth and App Launch ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}
sudo docker pull ${ECR_URL}


echo "==== Waiting for Next.js Frontend EC2 instance to enter 'running' state ===="
while true; do
  FRONTEND_STATE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=always-saved-frontend-service" \
    --query "Reservations[0].Instances[0].State.Name" \
    --output text \
    --region us-east-1)

  echo "Next.js Frontend instance state: $FRONTEND_STATE"

  if [ "$FRONTEND_STATE" == "running" ]; then
    break
  fi

  echo "Waiting for Next.js Frontend instance to start..."
  sleep 5
done


echo "==== Discovering Next.js Frontend Private IP from EC2 tag ===="
FRONTEND_PRIVATE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=always-saved-frontend-service" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text \
  --region us-east-1)

if [ -z "$FRONTEND_PRIVATE_IP" ] || [ "$FRONTEND_PRIVATE_IP" == "None" ]; then
  echo "❌ Could not retrieve Next.js Frontend instance private IP. Aborting."
  exit 1
fi

echo "Discovered Next.js Frontend IP: $FRONTEND_PRIVATE_IP"

echo "==== Creating .env.production file ===="
sudo tee /home/ubuntu/.env > /dev/null <<EOF
PRODUCTION_APP_DOMAIN=http://$FRONTEND_PRIVATE_IP
PYTHON_MODE=PRODUCTION
QDRANT_COLLECTION_NAME=alwayssaved_user_files
LLM_COMPANY=MistralAI
LLM_MODEL=open-mistral-7b
EOF


echo "==== Waiting for Next.js Frontend app at $FRONTEND_PRIVATE_IP to become available ===="
MAX_RETRIES=100
RETRY_DELAY=10
COUNTER=0

until curl -s --connect-timeout 2 http://$FRONTEND_PRIVATE_IP/health >/dev/null; do
  echo "Next.js Frontend not up yet... retrying ($((COUNTER + 1))/$MAX_RETRIES)"
  sleep $RETRY_DELAY
  COUNTER=$((COUNTER + 1))
  if [ $COUNTER -ge $MAX_RETRIES ]; then
    echo "❌ Next.js Frontend did not become available in time. Aborting setup."
    exit 1
  fi
done

echo "✅ Next.js Frontend is available! Proceeding..."


echo "==== Running LLM Container ===="
sudo docker run -d -p 8000:8000 \
  --env-file /home/ubuntu/.env \
  --name always-saved-llm ${ECR_URL}


echo "==== Installing CloudWatch Agent ===="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [{
          "file_path": "/var/lib/docker/containers/*/*.log",
          "log_group_name": "/alwayssaved/llm",
          "log_stream_name": "{instance_id}",
          "retention_in_days": 14
        }]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "==== ✅  LLM Service Ready ===="
