#!/bin/bash
# Deploy to Pi Zero 2 W

PI_USER="pi"
PI_HOST="your-pi-hostname"  # Change this
PI_DIR="/home/pi/leaderboard"

echo "📤 Deploying to $PI_HOST..."

# Copy server files
scp -r server/* $PI_USER@$PI_HOST:$PI_DIR/

# SSH and run setup
ssh $PI_USER@$PI_HOST << 'ENDSSH'
cd ~/leaderboard
sudo chmod +x setup.sh
sudo ./setup.sh
ENDSSH

echo "✅ Deploy complete!"
echo "Don't forget to:"
echo "  1. Add Caddy config: sudo nano /etc/caddy/Caddyfile"
echo "  2. Restart Caddy: sudo systemctl restart caddy"
echo "  3. Start service: sudo systemctl start leaderboard"
