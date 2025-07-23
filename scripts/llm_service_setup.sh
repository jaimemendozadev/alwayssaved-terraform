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
sudo docker run -d -p 8000:8000 --name always-saved-llm ${ECR_URL}

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
