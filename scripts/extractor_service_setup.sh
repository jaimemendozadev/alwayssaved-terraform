#!/bin/bash
set -e

echo "==== Logging all output to file and EC2 console ===="
exec > >(tee /var/log/always_saved_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating base system packages ===="
sudo apt-get update -y
sudo apt-get install -y unzip curl gnupg lsb-release software-properties-common

# nvidia-container-toolkit lets Docker pass the host GPU (provided by the Deep
# Learning AMI's NVIDIA drivers) into containers via --gpus all.
echo "==== Installing nvidia-container-toolkit ===="
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker

echo "==== Restarting Docker (nvidia runtime now configured) ===="
sudo systemctl daemon-reexec
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

echo "==== Logging into AWS ECR and Running Extractor ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}
sudo docker pull ${ECR_URL}
sudo docker run \
  --gpus all \
  --restart unless-stopped \
  -d \
  --name always-saved-extractor \
  ${ECR_URL}

echo "==== Verifying GPU inside Docker container ===="
sleep 5
sudo docker exec always-saved-extractor nvidia-smi || echo "nvidia-smi failed inside container"
sudo docker exec always-saved-extractor uv run python -c "import torch; print('GPU available:', torch.cuda.is_available())"

echo "==== Verifying GPU inside Docker container ===="
sleep 5
sudo docker exec always-saved-extractor nvidia-smi || echo "nvidia-smi failed inside container"
sudo docker exec always-saved-extractor uv run python -c "import torch; print('GPU available:', torch.cuda.is_available())"

echo "==== Installing CloudWatch Agent ===="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
    -O /tmp/amazon-cloudwatch-agent.deb
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

echo "==== Creating CloudWatch Agent Config ===="
# Single-quoted heredoc prevents bash from expanding {instance_id},
# which is a CloudWatch agent template token, not a shell variable.
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