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


echo "==== Fetching SQS URL from tag ===="
EXTRACTOR_PUSH_QUEUE_URL=$(aws sqs list-queues \
  --query "QueueUrls[?contains(@, 'always-saved-extractor-push-queue')]" \
  --output text \
  --region us-east-1)

echo "Retrieved EXTRACTOR_PUSH_QUEUE_URL: $EXTRACTOR_PUSH_QUEUE_URL"

echo "==== Fetching Clerk Secret from SSM ===="
CLERK_SECRET_KEY=$(aws ssm get-parameter --name "/alwayssaved/CLERK_SECRET_KEY" --with-decryption --query "Parameter.Value" --output text)

echo "Retrieved CLERK_SECRET_KEY"

# TODO: Need to manually add LLM_BASE_URL to Parameter Store
# LLM_BASE_URL=http://$LLM_PRIVATE_IP:8000

echo "==== Creating .env.production file ===="
sudo tee /home/ubuntu/.env.production > /dev/null <<EOF
CLERK_SECRET_KEY=$CLERK_SECRET_KEY
EXTRACTOR_PUSH_QUEUE_URL=$EXTRACTOR_PUSH_QUEUE_URL
EOF



echo "==== Running Frontend Container ===="
sudo docker run -d \
  --env-file /home/ubuntu/.env.production \
  -p 80:3000 \
  --network="host" \
  --name always-saved-frontend \
  ${ECR_URL}


echo "==== Installing CloudWatch Agent ===="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

echo "==== Creating CloudWatch Agent Config ===="
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/alwayssaved/frontend",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 14
          }
        ]
      }
    }
  }
}
EOF

echo "==== Starting CloudWatch Agent ===="
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "==== ✅ Next.js Frontend Deployment Complete ===="
