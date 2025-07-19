#!/bin/bash
set -e

# Log to file and console
exec > >(tee /var/log/always_saved_frontend_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

# Wait for apt to be available
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt lock to release..."
  sleep 5
done

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y unzip curl gnupg lsb-release

# Install AWS CLI
if ! command -v aws &>/dev/null; then
  cd /tmp
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  sudo ln -s /usr/local/bin/aws /usr/bin/aws || true
fi

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Wait for Docker daemon
sleep 10

# Login to ECR
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}

# Pull the Docker image
sudo docker pull ${ECR_URL}

# Run the container with the Clerk Secret
echo "==== Fetching Clerk Secret from SSM ===="
CLERK_SECRET_KEY=$(aws ssm get-parameter --name "/alwayssaved/CLERK_SECRET_KEY" --with-decryption --query "Parameter.Value" --output text)

echo "==== Running Docker Container with CLERK_SECRET_KEY ===="
sudo docker run -d \
  -e CLERK_SECRET_KEY=$CLERK_SECRET_KEY \
  --name always-saved-frontend \
  -p 80:3000 \
  ${ECR_URL}
