#!/bin/bash
# Update script - run from server/ directory to update existing installation

set -e

INSTALL_DIR="/opt/leaderboard"
SERVICE_NAME="leaderboard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Updating Leaderboard Server..."

# Check running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo ./update.sh)"
    exit 1
fi

# Check if files exist
if [ ! -f "$SCRIPT_DIR/app.py" ]; then
    echo "❌ Error: Cannot find app.py. Run this script from the server/ directory."
    exit 1
fi

# Check if installation exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ Installation not found. Run setup.sh first."
    exit 1
fi

# Backup current version
echo "💾 Backing up current version..."
cp "$INSTALL_DIR/app.py" "$INSTALL_DIR/app.py.backup"

# Copy updated files
echo "📋 Copying updated files..."
cp "$SCRIPT_DIR/app.py" $INSTALL_DIR/
cp "$SCRIPT_DIR/requirements.txt" $INSTALL_DIR/

# Update dependencies
echo "📦 Updating Python dependencies..."
cd $INSTALL_DIR
source venv/bin/activate
pip install -r requirements.txt --quiet

# Update systemd service
echo "⚙️  Updating systemd service..."
sed "s|WorkingDirectory=/opt/leaderboard|WorkingDirectory=$INSTALL_DIR|g" "$SCRIPT_DIR/leaderboard.service" > /etc/systemd/system/$SERVICE_NAME.service
systemctl daemon-reload

# Restart service
echo "🔄 Restarting service..."
systemctl restart $SERVICE_NAME

# Check if service started successfully
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Update complete! Service is running."
    echo ""
    echo "Check status: sudo systemctl status leaderboard"
    echo "View logs: sudo journalctl -u leaderboard -n 50"
else
    echo "⚠️  Service failed to start. Check logs:"
    echo "   sudo journalctl -u leaderboard -n 50"
    echo ""
    echo "Backup saved to: $INSTALL_DIR/app.py.backup"
    exit 1
fi
