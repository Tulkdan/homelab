#!/bin/bash

# a script that creates daily backup and saves it to google drive
# in case i forgot how to set up again, here's the post
# https://kernova.io/blog/secure-and-automated-backups-with-borg-and-rclone/

# Stop script on any error
set -e
set -o pipefail

DIR_ROOT=/media/external-hd-backup

# Configuration
BORG_REPO=$DIR_ROOT/borgbackup
export BORG_PASSPHRASE=$(cat /root/.borg_passphrase)

RCLONE_REMOTE="Google drive"
RCLONE_DESTINATION="rasp"

TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)

SOFT_SERVE_DIR=$DIR_ROOT/soft-serve/
VAULTWARDEN_DIR=$DIR_ROOT/vaultwarden-data/

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

# 3. Prune repository
log "Step 3: Prunning to maintain 4 weekly and 6 monthly..."
borg prune         \
  --list           \
  --show-rc        \
  --keep-weekly 4  \
  --keep-monthly 6 \
  $BORG_REPO
log "Prunning complete"

# 4. Prune repository
log "Step 4: Compacting borg repo..."
borg compact $BORG_REPO
log "Compacting complete"

# 5. Sync borg repository to the rclone remote
log "Step 5: Syncing repository to rclone remote..."
rclone sync "$BORG_REPO" "$RCLONE_REMOTE":$RCLONE_DESTINATION --progress
log "Sync complete"

log "--- Daily backup finished successfully ---"

exit 0

