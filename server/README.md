# Leaderboard Server

Lightweight leaderboard server for Pi Zero 2 W behind Caddy proxy.
**Full CORS support** - works with itch.io, web builds, desktop, and mobile.

## Quick Deploy (from repo clone)

```bash
# 1. Clone repo on Pi
ssh pi@your-pi
git clone <your-repo-url> ~/game
cd ~/game/server

# 2. Run setup (installs everything)
sudo chmod +x setup.sh update.sh
sudo ./setup.sh

# 3. Configure Caddy
sudo nano /etc/caddy/Caddyfile
# Paste contents of Caddyfile from this directory
sudo systemctl restart caddy

# 4. Start service
sudo systemctl start leaderboard
sudo systemctl status leaderboard
```

## Updating Later

```bash
cd ~/game/server
git pull
sudo ./update.sh
```

## View Leaderboard

Just open in browser: **https://save.temp.olio.ovh/leaderboard**

Simple HTML view - no in-game UI needed!

## CORS Features

- ✅ Preflight OPTIONS handling
- ✅ All origins accepted (`*`) for web builds
- ✅ Proper headers for itch.io / web exports
- ✅ Timeout handling for slow connections
- ✅ Automatic fallback on network errors

## Usage in Godot

### Add to AutoLoad
Project Settings → AutoLoad → Add `res://scripts/leaderboard.gd` as `Leaderboard`

### Submit score when player dies
In `player.gd`, update the death code:
```gdscript
if AIR <= 0 and not dying:
    dying = true
    var final_time = level_time
    Leaderboard.submit_score("Player", final_time)
    $Die.play()
    set_physics_process(false)
    visible = false
    await $Die.finished
    get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)
```

### Display leaderboard
Create a leaderboard scene:
```gdscript
extends Control

@onready var score_list = $VBoxContainer/ScoreList

func _ready():
    Leaderboard.get_scores()

func _on_leaderboard_scores_received(scores):
    for i in range(scores.size()):
        var score = scores[i]
        var text = "%d. %s - %.2fs" % [i+1, score.name, score.time]
        score_list.add_item(text)

Leaderboard.scores_received.connect(_on_leaderboard_scores_received)
```

## Testing

### Basic tests
```bash
# Health check
curl https://save.temp.olio.ovh/health

# Submit score (python)
python3 -c "
import base64, json, urllib.request
data = {'name': 'Test', 'time': 45.2}
obscured = base64.b64encode(b'underwater_' + json.dumps(data).encode()).decode()
urllib.request.urlopen('https://save.temp.olio.ovh/submit',
    data=json.dumps({'data': obscured}).encode(),
    headers={'Content-Type': 'application/json'})
"

# Get scores
curl https://save.temp.olio.ovh/scores
```

### CORS Test (from browser console)
```javascript
// Test from https://your-game.itch.io or any origin
fetch('https://save.temp.olio.ovh/scores', {
    method: 'GET',
    headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
    }
})
.then(r => r.json())
.then(console.log)
.catch(console.error)

// Test POST (submit score)
fetch('https://save.temp.olio.ovh/submit', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
    },
    body: JSON.stringify({
        data: 'und2VydmF0ZXJfbmFtZToidGVzdCIsInRpbWUiOjQ1LjJ9'
    })
})
.then(r => r.json())
.then(console.log)
.catch(console.error)
```

## Files

- `app.py` - Flask server
- `Caddyfile` - Caddy proxy configuration
- `requirements.txt` - Python dependencies
- `setup.sh` - Installation script for Pi
- `leaderboard.service` - Systemd service file

## Optimizations for Pi Zero 2W

- Only 2 worker threads (keeps memory low)
- File locking for thread safety
- Atomic writes (prevents corruption)
- Simple data structures (no database overhead)
- Score limit of 100 (keeps file small)
