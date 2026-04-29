#!/bin/bash

# a script that creates daily backup and saves it to google drive
# in case i forgot how to set up again, here's the post
# https://kernova.io/blog/secure-and-automated-backups-with-borg-and-rclone/

# Stop script on any error
set -e
set -o pipefail

# Configuration
BORG_REPO=/external-hd-backup/borgbackup
export BORG_PASSPHRASE=$(cat /root/.borg_passphrase)

RCLONE_REMOTE="Google drive"
RCLONE_DESTINATION="rasp"

TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)

SOFT_SERVE_DIR=/external-hd-backup/soft-serve/
VAULTWARDEN_DIR=/external-hd-backup/vaultwarden-data/

log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

log "--- Starting daily backup ---"

# 1. Create a backup of soft-serve application
log "Step 1: Backing up soft-serve..."
BORG_SOFT_SERVE_NAME="soft-serve-$TIMESTAMP"
borg create --stats --progress \
  -C zstd,6 \
  "$BORG_REPO::$BORG_SOFT_SERVE_NAME" \
  "$SOFT_SERVE_DIR"
log "Borg backup created: $BORG_SOFT_SERVE_NAME"

# 2. Create a backup of vaultwarden application
log "Step 2: Backing up vaultwarden..."
BORG_VAULTWARDEN_NAME="vaultwarden-$TIMESTAMP"
borg create --stats --progress \
  -C zstd,6 \
  "$BORG_REPO::$BORG_VAULTWARDEN_NAME" \
  "$VAULTWARDEN_DIR"
log "Borg backup created: $BORG_VAULTWARDEN_NAME"

# 3. Sync borg repository to the rclone remote
log "Step 3: Syncing repository to rclone remote..."
rclone sync "$BORG_REPO" "$RCLONE_REMOTE":$RCLONE_DESTINATION --progress
log "Sync complete"

log "--- Daily backup finished successfully ---"

exit 0

