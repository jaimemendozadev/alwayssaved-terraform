resource "aws_instance" "audio_extractor" {
  ami                         = var.aws_ami_id        # Replace with your preferred AMI
  instance_type               = var.aws_instance_type # Change based on service needs
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.notecasts_sg.id]
  associate_public_ip_address = true # ✅ Ensure a public IP is assigned.
  iam_instance_profile        = aws_iam_instance_profile.notecasts_instance_profile.name
  key_name                    = var.aws_pub_key_name # ✅ Assign the key to the instance
  user_data                   = <<EOF
#!/bin/bash
set -e

# Install dependencies
sudo yum update -y
sudo yum install -y python3.11 unzip aws-cli systemd

# Define S3 bucket & filename
BUCKET_NAME="${var.aws_s3_code_bucket_name}"
ZIP_FILE="notecasts-extractor-service.zip"
APP_DIR="/home/ec2-user/notecasts-extractor-service"

# Ensure old app directory is gone
sudo rm -rf $APP_DIR
mkdir -p $APP_DIR

# Wait for IAM role to propagate (sometimes takes a few seconds)
echo "==== Waiting 30 seconds for IAM role to sync ===="
sleep 30

# Download and extract the latest code
aws s3 cp s3://$BUCKET_NAME/$ZIP_FILE /tmp/$ZIP_FILE
unzip /tmp/$ZIP_FILE -d $APP_DIR

# Change ownership & permissions
sudo chmod -R 755 $APP_DIR
sudo chown -R ec2-user:ec2-user $APP_DIR

echo "==== Installing Python dependencies ===="
# Install Python dependencies
cd $APP_DIR
if [ -f "Pipfile" ]; then
    echo "Using pipenv for dependencies..."
    pip3.11 install pipenv
    pipenv shell
    pipenv --python 3.11
    pipenv install 

else
    echo "Using requirements.txt for dependencies..."
    pip3 install --no-cache-dir -r requirements.txt
fi

# Define the systemd service
echo "[Unit]
Description=Notecasts Extractor Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 $APP_DIR/service.py
Restart=always
RestartSec=5
StandardOutput=append:/var/log/notecasts.log
StandardError=append:/var/log/notecasts_error.log

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/notecasts-extractor.service

echo "==== Enabling and starting the Notecasts Extractor service ===="
# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable notecasts-extractor
sudo systemctl start notecasts-extractor

echo "Deployment complete!"
EOF

  tags = {
    Name = "notecasts-audio-extractor"
  }
}



