#!/usr/bin/env python3
"""
Lightweight leaderboard server for Pi Zero 2 W
Save scores and retrieve top times
"""

from flask import Flask, request, jsonify, abort
from flask_cors import CORS
import base64
import json
import os
from datetime import datetime
import fcntl

app = Flask(__name__)
# Enable CORS for all routes - works with itch.io, web builds, etc.
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "max_age": 86400
    }
})

# Configuration
SCORES_FILE = "/var/lib/leaderboard/scores.json"
SECRET = "underwater_"
MAX_SCORES = 100

# Ensure scores directory exists
os.makedirs(os.path.dirname(SCORES_FILE), exist_ok=True)

def obscure(data):
    """Obscure data with base64 + prefix"""
    return base64.b64encode((SECRET + data).encode()).decode()

def reveal(data):
    """Reveal obscured data"""
    try:
        decoded = base64.b64decode(data).decode()
        if decoded.startswith(SECRET):
            return decoded[len(SECRET):]
    except:
        pass
    return None

def read_scores():
    """Thread-safe score reading with file locking"""
    if not os.path.exists(SCORES_FILE):
        return []

    try:
        with open(SCORES_FILE, 'r') as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_SH)
            data = json.load(f)
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
            return data
    except (json.JSONDecodeError, IOError):
        return []

def write_scores(scores):
    """Thread-safe score writing with file locking"""
    # Sort by time (lower is better) and keep top MAX_SCORES
    scores.sort(key=lambda x: x.get('time', 999999))
    scores = scores[:MAX_SCORES]

    with open(SCORES_FILE + '.tmp', 'w') as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        json.dump(scores, f)
        f.flush()
        os.fsync(f.fileno())
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)

    os.rename(SCORES_FILE + '.tmp', SCORES_FILE)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'service': 'leaderboard'})

@app.route('/submit', methods=['POST'])
def submit_score():
    """Submit a new score"""
    data = request.json
    if not data or 'data' not in data:
        return jsonify({'error': 'no data'}), 400

    # Rate limiting by IP could be added here

    revealed = reveal(data['data'])
    if not revealed:
        return jsonify({'error': 'invalid data'}), 400

    try:
        score_data = json.loads(revealed)

        # Validate required fields
        if 'name' not in score_data or 'time' not in score_data:
            return jsonify({'error': 'missing fields'}), 400

        # Sanitize name (max 20 chars, alphanumeric + spaces)
        name = ''.join(c for c in score_data['name'][:20] if c.isalnum() or c in ' _-')
        if not name:
            name = "Anonymous"

        score_data['name'] = name
        score_data['time'] = float(score_data['time'])
        score_data['date'] = datetime.utcnow().isoformat() + 'Z'

        scores = read_scores()
        scores.append(score_data)
        write_scores(scores)

        return jsonify({'success': True, 'rank': len([s for s in scores if s['time'] <= score_data['time']])})

    except (json.JSONDecodeError, ValueError, KeyError):
        return jsonify({'error': 'invalid score data'}), 400

@app.route('/scores', methods=['GET'])
def get_scores():
    """Get top scores"""
    limit = request.args.get('limit', 10, type=int)
    limit = min(limit, 50)  # Max 50

    scores = read_scores()
    return jsonify(scores[:limit])

@app.route('/')
@app.route('/leaderboard')
def leaderboard_html():
    """Simple HTML leaderboard view"""
    scores = read_scores()[:50]  # Top 50

    html = """<!DOCTYPE html>
<html>
<head>
    <title>Leaderboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: monospace; max-width: 800px; margin: 20px auto; padding: 0 10px; background: #1a1a2e; color: #eee; }
        h1 { color: #4ade80; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #333; }
        th { color: #4ade80; }
        tr:hover { background: #16213e; }
        .rank { color: #888; }
        .time { color: #4ade80; font-weight: bold; }
        .date { color: #666; font-size: 0.9em; }
        a { color: #4ade80; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>🏆 Leaderboard</h1>
    <p>Fastest times across all levels</p>
    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Level</th>
                <th>Time</th>
                <th>Date</th>
            </tr>
        </thead>
        <tbody>
"""

    for i, score in enumerate(scores, 1):
        name = score.get('name', 'Unknown')
        time = score.get('time', 0)
        date = score.get('date', '')[:10]  # Just the date part
        time_str = f"{time:.2f}s"

        html += f"""            <tr>
                <td class="rank">{i}</td>
                <td>{name}</td>
                <td class="time">{time_str}</td>
                <td class="date">{date}</td>
            </tr>
"""

    html += """        </tbody>
    </table>
    <p style="margin-top: 30px; color: #666;">
        <a href="https://save.temp.olio.ovh/scores">JSON API</a>
    </p>
</body>
</html>"""

    return html

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'not found'}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'server error'}), 500

if __name__ == '__main__':
    # Run directly for testing
    app.run(host='127.0.0.1', port=5000, debug=False)
