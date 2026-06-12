# ═══════════════════════════════════════════════════════════════
#  Nova CalcX — Fixed Multi-Stage Dockerfile
#  Stage 1: Build Flutter Web
#  Stage 2: nginx serves Flutter + Python API via gunicorn
# ═══════════════════════════════════════════════════════════════

# ── Stage 1: Build Flutter Web ──────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app

# Copy Flutter project (pubspec.yaml is at flutter_app/ root)
COPY flutter_app/pubspec.yaml flutter_app/pubspec.lock* ./
RUN flutter pub get

COPY flutter_app/ .

# Build for web with correct base-href for GitHub Pages
# For Docker deployment use / as base-href
RUN flutter build web --release --base-href /

# ── Stage 2: nginx + Python API ─────────────────────────────────
FROM python:3.11-slim

# Install nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Python calculator (note: fixed filename, no spaces)
COPY calculator.py .

# Copy Flutter web build into the place Python serves from
COPY --from=flutter-builder /app/build/web /app/public/web

# nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose ports
EXPOSE 80 8000

# Start script: nginx (web) + gunicorn (API)
RUN echo '#!/bin/sh\n\
nginx &\n\
exec gunicorn --bind 0.0.0.0:8000 --workers 4 --timeout 120 calculator:app\n\
' > /start.sh && chmod +x /start.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["/start.sh"]
