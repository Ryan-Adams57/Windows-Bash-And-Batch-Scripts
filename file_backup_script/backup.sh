#!/usr/bin/env bash

###############################################################################
# Backup Automation Utility
# -----------------------------------------------------------------------------
# Purpose:
#   Performs local directory backups with compression support.
#   Can be extended for remote copy (scp/rsync) or cloud upload.
#
# Description:
#   - Archives specified source directory
#   - Compresses output (.tar.gz)
#   - Supports optional remote transfer
#   - Designed for cron automation
###############################################################################

# 1. Configuration and Flags
DEFAULT_CONFIG_FILE="./backup.conf"
CONFIG_FILE="$DEFAULT_CONFIG_FILE"
DRY_RUN=false

usage() {
    echo "Usage: $0 [-c <config_file>] [-d] [-h]"
    echo "  -c <config_file>  Specify a custom configuration file."
    echo "  -d               Dry run mode. Shows what would happen."
    echo "  -h               Show this help message."
    exit 0
}

while getopts ":c:dh" opt; do
    case ${opt} in
        c )
            CONFIG_FILE=$OPTARG
            ;;
        d )
            DRY_RUN=true
            ;;
        h )
            usage
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi
source "$CONFIG_FILE"

# 2. Initialization
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_$TIMESTAMP.tar.gz"
LOG_FILE="$LOG_DIR/backup_$TIMESTAMP.log"

# Create directories if they don't exist (unless it's a dry run)
if [[ "$DRY_RUN" == "false" ]]; then
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"
fi

# 3. Logging Function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="[$timestamp] [$level] $message"
    
    echo "$log_entry"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

# 4. Starting Backup Process
log "INFO" "Starting backup process..."
if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "DRY RUN MODE ENABLED. No actions will be taken."
fi
log "INFO" "Sources to back up: ${SOURCE_PATHS[*]}"
log "INFO" "Local backup directory: $BACKUP_DIR"

# Check if source paths exist and filter valid ones
VALID_SOURCES=()
for path in "${SOURCE_PATHS[@]}"; do
    if [[ -e "$path" ]]; then
        VALID_SOURCES+=("$path")
    else
        log "WARNING" "Source path '$path' does not exist. Skipping."
    fi
done

if [[ ${#VALID_SOURCES[@]} -eq 0 ]]; then
    log "ERROR" "No valid source paths found. Aborting backup."
    exit 1
fi

# Create Archive
# Flags: -c (create), -z (gzip), -f (file)
if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "[DRY RUN] Would create archive: $BACKUP_DIR/$BACKUP_NAME"
    log "INFO" "[DRY RUN] Source files: ${VALID_SOURCES[*]}"
else
    log "INFO" "Creating archive: $BACKUP_DIR/$BACKUP_NAME"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" "${VALID_SOURCES[@]}" 2>> "$LOG_FILE"

    if [[ $? -eq 0 ]]; then
        log "INFO" "Archive created successfully: $BACKUP_DIR/$BACKUP_NAME"
    else
        log "ERROR" "Failed to create archive. Check $LOG_FILE for details."
        exit 1
    fi
fi

# 5. Local Retention Policy
if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "[DRY RUN] Would clean up local backups older than $RETENTION_DAYS days..."
else
    log "INFO" "Cleaning up local backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +"$RETENTION_DAYS" -exec rm {} \; -exec log "INFO" "Deleted old backup: {}" \;
fi

# 6. Remote Transfer (Optional)
if [[ "$ENABLE_REMOTE" == "true" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would start SCP to $REMOTE_HOST:$REMOTE_PATH"
    else
        log "INFO" "Remote transfer enabled. Starting SCP to $REMOTE_HOST..."
        scp "$BACKUP_DIR/$BACKUP_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>> "$LOG_FILE"
        
        if [[ $? -eq 0 ]]; then
            log "INFO" "Remote transfer successful to $REMOTE_HOST:$REMOTE_PATH"
        else
            log "ERROR" "Remote transfer failed. Check $LOG_FILE for details."
        fi
    fi
else
    log "INFO" "Remote transfer disabled. Skipping."
fi

log "INFO" "Backup process complete."
