#!/bin/bash


# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to load k3s config
load_k3s_config() {
    # Check if S3 bucket is set
    if [ -z "$S3_BUCKET_NAME" ]; then
        log "Error: S3_BUCKET_NAME environment variable not set"
        exit 1
    fi

    # Create .kube directory if it doesn't exist
    local kube_dir="$HOME/.kube"
    mkdir -p "$kube_dir"

    # Backup existing config if it exists
    if [ -f "$kube_dir/config" ]; then
        log "Backing up existing config to $kube_dir/config.backup"
        cp "$kube_dir/config" "$kube_dir/config.backup"
    fi

    # Download the config
    log "Fetching k3s config from S3..."
    if aws s3 cp "s3://${S3_BUCKET_NAME}/k3s_config.yaml" "$kube_dir/config"; then
        log "Successfully downloaded config to $kube_dir/config"
        # Set appropriate permissions
        chmod 600 "$kube_dir/config"
        log "Set permissions to 600 for $kube_dir/config"
    else
        log "Error: Failed to download config from S3"
        exit 1
    fi

    # Verify the config is valid
    if ! kubectl version --client &> /dev/null; then
        log "Warning: kubectl command not found. Please install kubectl to verify the config"
    else
        if kubectl cluster-info &> /dev/null; then
            log "Successfully verified kubernetes connection"
        else
            log "Warning: Could not verify kubernetes connection. Please check your VPN/network connection"
        fi
    fi
}

# Main execution
main() {
    log "Starting k3s config download process..."
    load_k3s_config
    log "Config loading process completed"
}

# Run the script
main