#!/bin/sh

# Optional GUI settings
GUI_MODE=${GUI_MODE:-false}
FOREGROUND=${FOREGROUND:-false}
NOVNC_PORT=${NOVNC_PORT:-6080}
VNC_PORT=${VNC_PORT:-5900}
DISPLAY=${DISPLAY:-:1}

# Set default values for external_auth, local_auth, debug, cache_store, and logfile
EXTERNAL_AUTH_VALUE=""
LOCAL_SERVER_AUTH_VALUE=""
DEBUG_VALUE=""
CACHE_STORE_VALUE=""
LOG_FILE_PATH=""
GUI_FLAG=""
# GUI mode flips to --gui and typically should run in foreground
if [ "$GUI_MODE" = "true" ]; then
    FOREGROUND="true"
    # Default to local server auth in GUI mode if not specified
    if [ -z "$LOCAL_SERVER_AUTH" ]; then
        LOCAL_SERVER_AUTH="true"
    fi
fi

# Check if LOCAL_SERVER_AUTH environment variable is set to "true"
if [ "$LOCAL_SERVER_AUTH" = "true" ]; then
    LOCAL_SERVER_AUTH_VALUE="--local-server-auth"
else
    EXTERNAL_AUTH_VALUE="--external-auth"  # Default to --external-auth if not using local server auth
fi

# Check if DEBUG environment variable is set to "true"
if [ "$DEBUG" = "true" ]; then
    DEBUG_VALUE="--debug"
fi

# Check if CACHE_STORE environment variable is set
if [ -n "$CACHE_STORE" ]; then
    CACHE_STORE_VALUE="--cache-store $CACHE_STORE"
fi

# Check if LOGFILE environment variable is set to "true"
if [ "$LOGFILE" = "true" ]; then
    LOG_FILE_PATH="/config/emailproxy.log"
else
    LOG_FILE_PATH="/app/emailproxy.log"
fi

# Start lightweight GUI stack when requested
DISABLE_RAW_VNC=${DISABLE_RAW_VNC:-false}
if [ "$GUI_MODE" = "true" ]; then
    Xvfb "$DISPLAY" -screen 0 1280x800x24 -ac +extension RANDR >/tmp/xvfb.log 2>&1 &
    if command -v openbox >/dev/null 2>&1; then
        openbox-session >/tmp/openbox.log 2>&1 &
    fi
    if [ "$DISABLE_RAW_VNC" != "true" ]; then
        x11vnc -display "$DISPLAY" -nopw -forever -shared -rfbport "$VNC_PORT" -listen 0.0.0.0 >/tmp/x11vnc.log 2>&1 &
        VNC_TARGET="localhost:$VNC_PORT"
    else
        # websockify can use Xvfb's unix socket directly if x11vnc is not running
        VNC_TARGET="$DISPLAY"
    fi
    if command -v websockify >/dev/null 2>&1; then
        NOVNC_WEB_ROOT=${NOVNC_WEB_ROOT:-/usr/share/novnc}
        # Point to the specific vnc.html to avoid directory listing
        websockify --web "$NOVNC_WEB_ROOT" "$NOVNC_PORT" $VNC_TARGET --target-config="$NOVNC_WEB_ROOT/vnc.html" >/tmp/novnc.log 2>&1 &
    fi
fi
# Start tint2 (system tray) if pystray/Openbox needs a tray manager (Wait slightly for Openbox)
if [ "$GUI_MODE" = "true" ] && command -v tint2 >/dev/null 2>&1; then
   sleep 1
   tint2 >/tmp/tint2.log 2>&1 &
fi

# Execute the Python script with arguments
if [ "$FOREGROUND" = "true" ]; then
    exec python /app/emailproxy.py --log-file "$LOG_FILE_PATH" --config-file /config/emailproxy.config $CACHE_STORE_VALUE $DEBUG_VALUE $EXTERNAL_AUTH_VALUE $LOCAL_SERVER_AUTH_VALUE
fi

python /app/emailproxy.py --no-gui --log-file "$LOG_FILE_PATH" --config-file /config/emailproxy.config $CACHE_STORE_VALUE $DEBUG_VALUE $EXTERNAL_AUTH_VALUE $LOCAL_SERVER_AUTH_VALUE &

# Wait for the log file to be created
while [ ! -f "$LOG_FILE_PATH" ]; do
    sleep 1
done

# Stream the log file to Docker logs or a specified file
tail -f "$LOG_FILE_PATH"
