#!/bin/bash
# Setup script for Pi Zero 2 W - run from server/ directory in cloned repo

set -e

INSTALL_DIR="/opt/leaderboard"
SERVICE_NAME="leaderboard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐟 Setting up Leaderboard Server for Pi Zero 2 W..."
echo "📂 Running from: $SCRIPT_DIR"

# Check running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo ./setup.sh)"
    exit 1
fi

# Check if files exist
if [ ! -f "$SCRIPT_DIR/app.py" ]; then
    echo "❌ Error: Cannot find app.py. Run this script from the server/ directory."
    exit 1
fi

# Create install directory
echo "📁 Creating directory $INSTALL_DIR..."
mkdir -p $INSTALL_DIR
mkdir -p /var/lib/leaderboard

# Copy files from repo
echo "📋 Copying files from repo..."
cp "$SCRIPT_DIR/app.py" $INSTALL_DIR/
cp "$SCRIPT_DIR/requirements.txt" $INSTALL_DIR/

# Create virtual environment
echo "🐍 Creating Python virtual environment..."
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Set permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data $INSTALL_DIR
chown -R www-data:www-data /var/lib/leaderboard

# Install systemd service
echo "⚙️  Installing systemd service..."
sed "s|WorkingDirectory=/opt/leaderboard|WorkingDirectory=$INSTALL_DIR|g" "$SCRIPT_DIR/leaderboard.service" > /etc/systemd/system/$SERVICE_NAME.service
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# Setup Caddy
echo "🌐 Setting up Caddy..."
if [ -f "$SCRIPT_DIR/Caddyfile" ]; then
    echo ""
    echo "Add this to /etc/caddy/Caddyfile:"
    echo "======================================"
    cat "$SCRIPT_DIR/Caddyfile"
    echo "======================================"
    echo ""
    echo "Run: sudo nano /etc/caddy/Caddyfile"
    echo "Then: sudo systemctl restart caddy"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Add Caddy config (see above)"
echo "  2. Restart Caddy: sudo systemctl restart caddy"
echo "  3. Start the leaderboard: sudo systemctl start leaderboard"
echo "  4. Check status: sudo systemctl status leaderboard"
echo "  5. View logs: sudo journalctl -u leaderboard -f"
echo ""
echo "To update later: cd /path/to/repo/server && sudo ./update.sh"
echo ""
