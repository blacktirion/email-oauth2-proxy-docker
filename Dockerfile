# syntax=docker/dockerfile:1

FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Core tools (kept for debugging or future needs)
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
        tint2 \
        # Dependencies for GUI python modules (pystray, pywebview, etc.)
        # --- Runtime Dependencies ---
        gir1.2-gtk-3.0 \
        gir1.2-webkit2-4.* \
        gir1.2-ayatanaappindicator3-* \
        gir1.2-freedesktop \
        gir1.2-glib-2.0 \
        gir1.2-girepository-2.0 \
        # --- Build Dependencies (removed later) ---
        gcc pkg-config python3-dev cmake \
        libcairo2-dev \
        libgtk-3-dev \
        libglib2.0-dev \
        libgirepository1.0-dev \
        libgirepository-2.0-dev \
        gobject-introspection \
    # Install Python GUI dependencies (pycairo/PyGObject need build tools)
    && pip install --no-cache-dir \
        pycairo \
        PyGObject \
        pystray \
        Pillow \
        timeago \
        pywebview \
        packaging \
    # Cleanup build tools
    && apt-get purge -y --auto-remove \
        gcc pkg-config python3-dev cmake \
        libcairo2-dev libgtk-3-dev libglib2.0-dev \
        libgirepository1.0-dev libgirepository-2.0-dev \
        gobject-introspection \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV DISPLAY=:1 \
    BROWSER=/usr/bin/chromium

EXPOSE 1993 8080 5900 6080

CMD ["/bin/sh", "/app/run_email_proxy.sh"]

# Headless default target
FROM base AS headless

EXPOSE 1993 8080

CMD ["/bin/sh", "/app/run_email_proxy.sh"]
