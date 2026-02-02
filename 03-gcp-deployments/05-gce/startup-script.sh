#!/bin/bash

# Startup script for Compute Engine instance
# This script will be executed when the VM starts

echo "Starting CNN Image Classifier setup on Compute Engine..."

# Update system
apt-get update -y

# Install Python and pip
apt-get install -y python3 python3-pip python3-venv git

# Clone the repository (if not pre-installed)
if [ ! -d "/opt/cnn-classifier" ]; then
    git clone https://github.com/your-username/ia_image_classifier.git /opt/cnn-classifier
    cd /opt/cnn-classifier
else
    cd /opt/cnn-classifier
    git pull origin main
fi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create necessary directories
mkdir -p /var/log/cnn-classifier
mkdir -p /tmp/uploads

# Setup systemd service
cat > /etc/systemd/system/cnn-classifier.service << EOF
[Unit]
Description=CNN Image Classifier API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cnn-classifier
Environment="PATH=/opt/cnn-classifier/venv/bin"
ExecStart=/opt/cnn-classifier/venv/bin/python src/api/app.py
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cnn-classifier

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable cnn-classifier.service
systemctl start cnn-classifier.service

# Configure firewall (if needed)
ufw allow 8080/tcp

echo "Setup complete! Service is running on port 8080"
echo "To check status: systemctl status cnn-classifier.service"