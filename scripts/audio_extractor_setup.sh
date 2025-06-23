#!/bin/bash
set -e

echo "==== Logging all output to file and EC2 console ===="
exec > >(tee /var/log/always_saved_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating base system packages ===="
sudo apt-get update -y
sudo apt-get install -y unzip curl gnupg lsb-release software-properties-common

echo "==== Installing Docker ===="
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

echo "==== Installing NVIDIA Container Toolkit ===="
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

echo "==== Configuring Docker to use NVIDIA runtime ===="
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF

echo "==== Restarting Docker ===="
sudo systemctl daemon-reexec
sudo systemctl restart docker
sleep 5

echo "==== Docker GPU Support Status ===="
docker info | grep -i runtime

echo "==== Logging into AWS ECR and Running Extractor ===="
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin ${ECR_URL}
sudo docker pull ${ECR_URL}
sudo docker run --gpus all -d --name always-saved-extractor ${ECR_URL}

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
            "log_group_name": "/alwayssaved/transcriber",
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

echo "==== ✅ Deployment Complete ===="