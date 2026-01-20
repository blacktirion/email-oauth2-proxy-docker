# syntax=docker/dockerfile:1

FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Core tools (kept for debugging or future needs, curl removed from mandatory run)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies (aligned with upstream emailproxy.py)
RUN pip install --no-cache-dir \
    cryptography \
    pyasyncore \
    boto3 \
    prompt_toolkit \
    google-auth \
    requests \
    pyjwt

# Copy the Python script (must be present in context, downloaded by CI or user)
COPY emailproxy.py /app/

# Copy entrypoint
COPY run_email_proxy.sh /app/
RUN chmod +x /app/run_email_proxy.sh

# GUI-capable target (build with --target gui)
FROM base AS gui
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xvfb \
        openbox \
        x11vnc \
        novnc \
        websockify \
        chromium \
        xdg-utils \
        fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

ENV DISPLAY=:1 \
    BROWSER=/usr/bin/chromium

EXPOSE 1993 8080 5900 6080

CMD ["/bin/sh", "/app/run_email_proxy.sh"]

# Headless default target
FROM base AS headless

EXPOSE 1993 8080

CMD ["/bin/sh", "/app/run_email_proxy.sh"]
