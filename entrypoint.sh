#!/bin/bash
set -e

# Ensure save file exists
SAVE_PATH="/home/container/serverdata/serverfiles/saves/${GAME_SAVE_NAME:-docker.park}"
if [ ! -f "$SAVE_PATH" ]; then
    echo "Creating empty save file at $SAVE_PATH..."
    touch "$SAVE_PATH"
fi

# Update config.ini with environment variables if they are set
CONFIG_FILE="/home/container/serverdata/serverfiles/user-data/config.ini"
echo "Checking config.ini configuration..."

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating new config.ini..."
    touch "$CONFIG_FILE"
fi

# Function to update or add a configuration value only if the environment variable is set
update_config() {
    local key=$1
    local value=$2
    if [ ! -z "$value" ]; then
        if grep -q "^${key}=" "$CONFIG_FILE"; then
            sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
        else
            echo "${key}=${value}" >> "$CONFIG_FILE"
        fi
    fi
}

# Only update values that are set in environment variables
[ ! -z "$GAME_PORT" ] && update_config "port" "$GAME_PORT"
[ ! -z "$GAME_PASSWORD" ] && update_config "password" "$GAME_PASSWORD"
[ ! -z "$SERVER_NAME" ] && update_config "server-name" "$SERVER_NAME"
[ ! -z "$MAX_PLAYERS" ] && update_config "max-players" "$MAX_PLAYERS"
[ ! -z "$PUBLIC" ] && update_config "public" "$PUBLIC"
[ ! -z "$PAUSE_NO_CLIENTS" ] && update_config "pause-when-no-clients" "$PAUSE_NO_CLIENTS"
[ ! -z "$LOG_ACTIONS" ] && update_config "log-server-actions" "$LOG_ACTIONS"
[ ! -z "$AUTOSAVE_ENABLED" ] && update_config "autosave-enabled" "$AUTOSAVE_ENABLED"
[ ! -z "$AUTOSAVE_INTERVAL" ] && update_config "autosave-interval" "$AUTOSAVE_INTERVAL"

# Ensure users.json exists and matches schema
USERS_FILE="/home/container/serverdata/serverfiles/user-data/users.json"
echo "Ensuring users.json exists and matches schema..."
if [ ! -f "$USERS_FILE" ]; then
    echo "Creating users.json..."
    echo '[]' > "$USERS_FILE"
fi

# Add admin user if credentials are provided
if [ ! -z "${ADMIN_NAME}" ] && [ ! -z "${ADMIN_HASH}" ]; then
    echo "Updating admin user..."
    jq --arg name "$ADMIN_NAME" --arg hash "$ADMIN_HASH" '
        map(if .name == $name then .hash = $hash else . end)
        + (if any(.name == $name) | not then [{"name": $name, "hash": $hash}] else [] end)
    ' "$USERS_FILE" > "${USERS_FILE}.tmp" && mv "${USERS_FILE}.tmp" "$USERS_FILE"
fi

echo "Configuration complete, starting OpenRCT2 server..."
cd /home/container/serverdata/serverfiles/saves
exec openrct2-cli host --headless ${GAME_CONFIG:-} "$SAVE_PATH"