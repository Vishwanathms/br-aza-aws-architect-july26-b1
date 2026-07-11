from flask import Flask, jsonify
import os
import redis

app = Flask(__name__)

# Get Redis IP from environment variable (will be set below)
redis_host = os.environ.get('REDIS_IP', '10.0.3.178')  # Replace with your Redis private IP
redis_client = redis.Redis(host=redis_host, port=6379, decode_responses=True)

@app.route('/')
def home():
    try:
        redis_client.ping()
        return jsonify({
            'status': 'ok',
            'message': 'Connected to Redis updated',
            'hostname': os.popen('hostname').read().strip()
        })
    except Exception as exc:
        return jsonify({'status': 'error', 'message': str(exc)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)