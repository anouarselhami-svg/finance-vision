#!/usr/bin/env python3
"""
Lightweight static server with /config endpoint that reads .env
Run: python serve.py
"""
import http.server
import socketserver
import json
import os
from urllib.parse import urlparse

PORT = int(os.environ.get('PORT', 3000))
HERE = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(HERE, '.env')


def load_env_key(key='API_KEY'):
    if not os.path.exists(ENV_PATH):
        return ''
    try:
        with open(ENV_PATH, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k == key:
                    return v
    except Exception:
        return ''
    return ''


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == '/config':
            api_key = load_env_key('API_KEY')
            payload = {'apiKey': api_key}
            data = json.dumps(payload).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        # serve static files from current directory
        return super().do_GET()


if __name__ == '__main__':
    os.chdir(HERE)
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\nShutting down')
            httpd.server_close()
