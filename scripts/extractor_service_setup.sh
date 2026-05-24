#!/bin/bash
set -e

echo "==== Logging all output to file and EC2 console ===="
exec > >(tee /var/log/always_saved_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

# The Deep Learning AMI (ami-0260c4d597dcc8641) ships with:
#   - Docker (already running)
#   - nvidia-container-toolkit (already installed)
#   - AWS CLI v2
#   - NVIDIA drivers
# So we skip installing those and go straight to configuring them.

echo "==== Configuring NVIDIA container runtime for Docker ===="
sudo nvidia-ctk runtime configure --runtime=docker

echo "==== Restarting Docker (applies NVIDIA runtime config) ===="
sudo systemctl restart docker

echo "==== Waiting for Docker to fully initialize ===="
for i in {1..10}; do
  if sudo docker info > /dev/null 2>&1; then
    echo "Docker is ready."
    break
  fi
  echo "Waiting for Docker... ($i/10)"
  sleep 3
done

echo "==== Docker GPU Support Status ===="
sudo docker info | grep -i runtime || echo "No runtime info found"

echo "==== Verify GPU visibility on EC2 host ===="
nvidia-smi

# ECR_URL = full image URI, e.g.:
#   123456789.dkr.ecr.us-east-1.amazonaws.com/alwayssaved-extractor:latest
# We extract just the registry host for docker login.
ECR_REGISTRY=$(echo "${ECR_URL}" | cut -d'/' -f1)

echo "==== Logging into AWS ECR ===="
aws ecr get-login-password --region us-east-1 | \
  sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "==== Pulling Docker image ===="
sudo docker pull "${ECR_URL}"

echo "==== Running Extractor Service ===="
sudo docker run \
  --gpus all \
  --restart unless-stopped \
  -d \
  --name always-saved-extractor \
  "${ECR_URL}"

echo "==== Verifying GPU inside Docker container ===="
sleep 5
sudo docker exec always-saved-extractor nvidia-smi || echo "nvidia-smi failed inside container"
sudo docker exec always-saved-extractor uv run python -c "import torch; print('GPU available:', torch.cuda.is_available())"

echo "==== Installing CloudWatch Agent ===="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
    -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

echo "==== Creating CloudWatch Agent Config ===="
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/alwayssaved/extractor",
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

echo "==== Extractor Service Ready ===="