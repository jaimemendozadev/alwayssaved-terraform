resource "aws_instance" "audio_extractor" {
  ami                         = var.ubuntu_ami_id # Ubuntu AMI (Replace in `variables.tf`)
  instance_type               = "t3.large" # Equivalent to t2.large
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = var.aws_pub_key_name

  user_data = <<EOF
#!/bin/bash
set -e

exec > >(tee /var/log/notecasts_setup.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==== Updating System & Installing Dependencies ===="
sudo apt-get -y update
sudo apt-get -y install unzip 
sudo apt-get -y install systemd
sudo snap install aws-cli --classic



echo "==== Installing Pip and Pipenv ===="
sudo apt-get install -y python3-pip python3-venv pipx

# Ensure pipx is in the PATH
export PATH="$HOME/.local/bin:$PATH"

# Install Pipenv using pipx (recommended)
pipx install pipenv



# Define S3 bucket & filename
BUCKET_NAME="${var.aws_s3_code_bucket_name}"
ZIP_FILE="notecasts-extractor-service.zip"
APP_DIR="/home/ubuntu/notecasts-extractor-service"

echo "==== Removing Old Files ===="
sudo rm -rf $APP_DIR
mkdir -p $APP_DIR

echo "==== Waiting for IAM Role to Sync ===="
sleep 60

echo "==== Downloading Code from S3 ===="
attempt=1
max_attempts=3
while [ $attempt -le $max_attempts ]; do
    echo "Download attempt $attempt of $max_attempts..."
    if aws s3 cp s3://$BUCKET_NAME/$ZIP_FILE /tmp/$ZIP_FILE; then
        echo "Download successful!"
        break
    fi
    echo "Download failed. Retrying in 10 seconds..."
    sleep 10
    attempt=$((attempt+1))
done

if [ ! -f /tmp/$ZIP_FILE ]; then
    echo "S3 file not found after multiple attempts. Exiting."
    exit 1
fi

echo "==== Extracting Code ===="
unzip /tmp/$ZIP_FILE -d $APP_DIR

echo "==== Changing Ownership & Permissions ===="
sudo chmod -R 755 $APP_DIR
sudo chown -R ubuntu:ubuntu $APP_DIR

echo "==== Installing Dependencies in Virtual Environment ===="
cd $APP_DIR
pipenv --python 3.11
pipenv install

echo "==== Creating Systemd Service ===="
echo "[Unit]
Description=Notecasts Extractor Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=/home/ubuntu/.local/bin/pipenv run python $APP_DIR/service.py
Restart=always
RestartSec=5
StandardOutput=append:/var/log/notecasts.log
StandardError=append:/var/log/notecasts_error.log

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/notecasts-extractor.service

echo "==== Enabling & Starting the Service ===="
sudo systemctl daemon-reload
sudo systemctl enable notecasts-extractor
sudo systemctl start notecasts-extractor

echo "Deployment complete!"
EOF

  tags = {
    Name = "notecasts-audio-extractor"
  }
}




