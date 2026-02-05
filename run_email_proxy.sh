#!/bin/sh

# Set default values for external_auth, local_auth, debug, cache_store, and logfile
EXTERNAL_AUTH_VALUE=""
LOCAL_SERVER_AUTH_VALUE=""
DEBUG_VALUE=""
CACHE_STORE_VALUE=""
LOG_FILE_PATH=""
LOCAL_STARTTLS_VALUE=""
LOCAL_CERTIFICATE_PATH_VALUE=""
LOCAL_KEY_PATH_VALUE=""

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

# Check if LOCAL_STARTTLS environment variable is set
if [ -n "$LOCAL_STARTTLS" ]; then
    LOCAL_STARTTLS_VALUE="--local-starttls $LOCAL_STARTTLS"
fi

# Check if LOCAL_CERTIFICATE_PATH environment variable is set
if [ -n "$LOCAL_CERTIFICATE_PATH" ]; then
    LOCAL_CERTIFICATE_PATH_VALUE="--local_certificate_path $LOCAL_CERTIFICATE_PATH"
fi

# Check if LOCAL_KEY_PATH environment variable is set
if [ -n "$LOCAL_KEY_PATH" ]; then
    LOCAL_KEY_PATH_VALUE="--local_key_path $LOCAL_KEY_PATH"
fi

# Execute the Python script with arguments
python emailproxy.py --no-gui --log-file $LOG_FILE_PATH --config-file /config/emailproxy.config $CACHE_STORE_VALUE $DEBUG_VALUE $EXTERNAL_AUTH_VALUE $LOCAL_SERVER_AUTH_VALUE $LOCAL_STARTTLS_VALUE $LOCAL_CERTIFICATE_PATH_VALUE $LOCAL_KEY_PATH_VALUE &

# Wait for the log file to be created
while [ ! -f $LOG_FILE_PATH ]; do
    sleep 1
done

# Stream the log file to Docker logs or a specified file
tail -f $LOG_FILE_PATH
