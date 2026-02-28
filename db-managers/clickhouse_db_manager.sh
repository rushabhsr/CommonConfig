#!/bin/bash

# ClickHouse Database Backup and Restore Manager
# Usage: ./clickhouse_db_manager.sh [backup|restore] [date_suffix]
# Example: ./clickhouse_db_manager.sh backup
# Example: ./clickhouse_db_manager.sh restore oct30

set -e  # Exit on any error

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/clickhouse_db_manager.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Please copy clickhouse_db_manager.config.example and customize it"
    exit 1
fi

source "$CONFIG_FILE"

# Parse database mappings
declare -A DATABASES
for mapping in "${DATABASE_MAPPINGS[@]}"; do
    remote_db="${mapping%%:*}"
    local_db="${mapping##*:}"
    DATABASES["$remote_db"]="$local_db"
done

# Generate timestamp
DATE=$(date +'%b%d' | tr '[:upper:]' '[:lower:]')
TIME=$(date +'%H%M')
LOG_TIMESTAMP="${DATE}_${TIME}"

function archive_files() {
    local archive_all="${1:-false}"
    
    if [[ "$archive_all" == "true" ]]; then
        echo "📁 Starting archive of all backups and logs..."
    else
        echo "📁 Starting archive of old backups and logs..."
    fi
    
    # Create archives directory if it doesn't exist
    mkdir -p "$ARCHIVE_DIR"
    
    # Change to backup directory
    cd "$BACKUP_DIR" || return 1
    
    # Find files to archive
    local files_to_archive=()
    for file in *.sql *.log; do
        [[ -f "$file" ]] || continue
        
        if [[ "$archive_all" == "false" ]]; then
            # Skip files with current date suffix
            if [[ "$file" == *"_${DATE}.sql" ]] || [[ "$file" == *"_${LOG_TIMESTAMP}.log" ]]; then
                echo "🔒 Keeping current backup: $file"
                continue
            fi
        fi
        
        files_to_archive+=("$file")
    done
    
    # Archive files if any found
    if [[ ${#files_to_archive[@]} -gt 0 ]]; then
        local archive_name="clickhouse_backup_archive_${DATE}.zip"
        local archive_path="$ARCHIVE_DIR/$archive_name"
        
        echo "📦 Archiving ${#files_to_archive[@]} files to $archive_name"
        
        # Create zip archive
        if zip -q "$archive_path" "${files_to_archive[@]}"; then
            echo "✅ Archive created successfully: $archive_name"
            
            # Remove original files after successful archiving
            for file in "${files_to_archive[@]}"; do
                rm -f "$file"
                echo "🗑️  Removed: $file"
            done
            
            echo "📊 Archive stats:"
            echo "   Files archived: ${#files_to_archive[@]}"
            echo "   Archive size: $(du -h "$archive_path" | cut -f1)"
        else
            echo "❌ Failed to create archive, keeping original files"
        fi
    else
        echo "ℹ️  No files found to archive"
    fi
}

function show_usage() {
    echo "Usage: $0 [backup|restore|backup-restore|archive|list-archives] [date_suffix] [--background]"
    echo ""
    echo "Commands:"
    echo "  backup           - Backup databases from remote ClickHouse server"
    echo "  restore <date>   - Restore databases to local ClickHouse server"
    echo "  backup-restore   - Backup then restore in one operation"
    echo "  archive          - Archive old backup files manually"
    echo "  list-archives    - List available archive files"
    echo ""
    echo "Options:"
    echo "  --background     - Run operation in background and return to terminal"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 backup --background"
    echo "  $0 restore oct30"
    echo "  $0 backup-restore --background"
    echo "  $0 archive"
    echo "  $0 list-archives"
}

function backup_databases() {
    echo "🔄 Starting parallel ClickHouse database backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    LOG_FILE="$BACKUP_DIR/clickhouse_backup_${LOG_TIMESTAMP}.log"
    
    echo "Backup started at $(date)" | tee "$LOG_FILE"
    echo "💡 To follow logs: tail -f $LOG_FILE"
    
    local pids=()
    local start_time=$(date +%s)
    
    # Start parallel backups
    for remote_db in "${!DATABASES[@]}"; do
        local_db="${DATABASES[$remote_db]}"
        backup_file="${local_db}_${DATE}.sql"
        backup_path="$BACKUP_DIR/$backup_file"
        
        echo "📦 Starting backup for $remote_db -> $backup_file"
        
        # Run backup in background
        (
            db_start_time=$(date +%s)
            
            # ClickHouse backup - use HTTP interface for port 8123, native client for others
            local ch_host="${CH_HOST_BACKUP#https://}"
            ch_host="${ch_host%/}"
            
            if [[ "$CH_PORT_BACKUP" == "8123" ]]; then
                # Use HTTP interface
                local base_url="http://${ch_host}:${CH_PORT_BACKUP}"
                local auth_params=""
                if [[ -n "$CH_USER_BACKUP" ]]; then
                    if [[ -n "$CH_PASSWORD_BACKUP" ]]; then
                        auth_params="--user ${CH_USER_BACKUP}:${CH_PASSWORD_BACKUP}"
                    else
                        auth_params="--user ${CH_USER_BACKUP}:"
                    fi
                fi
            elif [[ "$CH_PORT_BACKUP" == "443" ]]; then
                # Use HTTPS interface
                local base_url="https://${ch_host}"
                local auth_params=""
                if [[ -n "$CH_USER_BACKUP" ]]; then
                    if [[ -n "$CH_PASSWORD_BACKUP" ]]; then
                        auth_params="--user ${CH_USER_BACKUP}:${CH_PASSWORD_BACKUP}"
                    else
                        auth_params="--user ${CH_USER_BACKUP}:"
                    fi
                fi
            else
                # Use HTTP interface with custom port
                local base_url="http://${ch_host}:${CH_PORT_BACKUP}"
                local auth_params=""
                if [[ -n "$CH_USER_BACKUP" ]]; then
                    if [[ -n "$CH_PASSWORD_BACKUP" ]]; then
                        auth_params="--user ${CH_USER_BACKUP}:${CH_PASSWORD_BACKUP}"
                    else
                        auth_params="--user ${CH_USER_BACKUP}:"
                    fi
                fi
            fi
            
            if [[ "$CH_PORT_BACKUP" == "8123" || "$CH_PORT_BACKUP" == "443" ]]; then
                # Use HTTP/HTTPS interface
                if curl -s $auth_params "${base_url}/?query=SHOW%20CREATE%20DATABASE%20${remote_db}" > "$backup_path" 2>>"$LOG_FILE" && \
                   curl -s $auth_params "${base_url}/?query=SHOW%20TABLES&database=${remote_db}" | \
                   while read table; do
                       [[ -n "$table" ]] || continue
                       echo "-- Table: $table" >> "$backup_path"
                       curl -s $auth_params "${base_url}/?query=SHOW%20CREATE%20TABLE%20${table}&database=${remote_db}" >> "$backup_path" 2>>"$LOG_FILE"
                       curl -s $auth_params "${base_url}/?query=SELECT%20*%20FROM%20${table}%20FORMAT%20TabSeparated&database=${remote_db}" >> "$backup_path" 2>>"$LOG_FILE"
                   done; then
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "✅ Backup for $remote_db completed in ${duration}s" | tee -a "$LOG_FILE"
                else
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "❌ Backup for $remote_db failed after ${duration}s" | tee -a "$LOG_FILE"
                    exit 1
                fi
            else
                # Use native client
                if clickhouse-client --host="$ch_host" --port="$CH_PORT_BACKUP" \
                    ${CH_USER_BACKUP:+--user="$CH_USER_BACKUP"} \
                    ${CH_PASSWORD_BACKUP:+--password="$CH_PASSWORD_BACKUP"} \
                    --query="SHOW CREATE DATABASE $remote_db" > "$backup_path" 2>>"$LOG_FILE" && \
                   clickhouse-client --host="$ch_host" --port="$CH_PORT_BACKUP" \
                    ${CH_USER_BACKUP:+--user="$CH_USER_BACKUP"} \
                    ${CH_PASSWORD_BACKUP:+--password="$CH_PASSWORD_BACKUP"} \
                    --database="$remote_db" --query="SHOW TABLES" | \
                   while read table; do
                       [[ -n "$table" ]] || continue
                       echo "-- Table: $table" >> "$backup_path"
                       clickhouse-client --host="$ch_host" --port="$CH_PORT_BACKUP" \
                        ${CH_USER_BACKUP:+--user="$CH_USER_BACKUP"} \
                        ${CH_PASSWORD_BACKUP:+--password="$CH_PASSWORD_BACKUP"} \
                        --database="$remote_db" --query="SHOW CREATE TABLE $table" >> "$backup_path" 2>>"$LOG_FILE"
                       clickhouse-client --host="$ch_host" --port="$CH_PORT_BACKUP" \
                        ${CH_USER_BACKUP:+--user="$CH_USER_BACKUP"} \
                        ${CH_PASSWORD_BACKUP:+--password="$CH_PASSWORD_BACKUP"} \
                        --database="$remote_db" --query="SELECT * FROM $table FORMAT TabSeparated" >> "$backup_path" 2>>"$LOG_FILE"
                   done; then
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "✅ Backup for $remote_db completed in ${duration}s" | tee -a "$LOG_FILE"
                else
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "❌ Backup for $remote_db failed after ${duration}s" | tee -a "$LOG_FILE"
                    exit 1
                fi
            fi
        ) &
        
        pids+=($!)
    done
    
    # Wait for all backups to complete
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=1
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    if [[ $failed -eq 1 ]]; then
        echo "❌ Some backups failed. Total time: ${total_duration}s" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "Backup process completed at $(date). Total time: ${total_duration}s" | tee -a "$LOG_FILE"
    
    # Archive previous backups and logs
    archive_files false
    
    echo "🎉 All backups completed successfully in ${total_duration}s!"
}

function restore_databases() {
    local date_suffix="$1"
    
    if [[ -z "$date_suffix" ]]; then
        echo "❌ Error: Date suffix required for restore operation"
        echo "Available dates:"
        ls -1 "$BACKUP_DIR"/*_*.sql 2>/dev/null | sed 's/.*_\(.*\)\.sql/\1/' | sort -u | tail -10
        return 1
    fi
    
    echo "🔄 Starting parallel ClickHouse database restore for date: $date_suffix"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    RESTORE_LOG_FILE="$BACKUP_DIR/clickhouse_restore_${LOG_TIMESTAMP}.log"
    
    echo "Restore started at $(date)" | tee "$RESTORE_LOG_FILE"
    echo "💡 To follow logs: tail -f $RESTORE_LOG_FILE"
    
    local pids=()
    local start_time=$(date +%s)
    
    # Start parallel restores
    for remote_db in "${!DATABASES[@]}"; do
        local_db="${DATABASES[$remote_db]}"
        backup_file="${local_db}_${date_suffix}.sql"
        backup_path="$BACKUP_DIR/$backup_file"
        
        if [[ ! -f "$backup_path" ]]; then
            echo "⚠️  Warning: Backup file $backup_file not found, skipping..."
            continue
        fi
        
        echo "🗄️  Starting restore for $local_db from $backup_file"
        
        # Run restore in background
        (
            db_start_time=$(date +%s)
            
            # ClickHouse restore - use HTTP/HTTPS interface for web ports, native client for others
            local ch_host="${CH_HOST_LOCAL#https://}"
            ch_host="${ch_host%/}"
            
            if [[ "$CH_PORT_LOCAL" == "8123" ]]; then
                # Use HTTP interface
                local base_url="http://${ch_host}:${CH_PORT_LOCAL}"
                local auth_params=""
                if [[ -n "$CH_USER_LOCAL" ]]; then
                    if [[ -n "$CH_PASSWORD_LOCAL" ]]; then
                        auth_params="--user ${CH_USER_LOCAL}:${CH_PASSWORD_LOCAL}"
                    else
                        auth_params="--user ${CH_USER_LOCAL}:"
                    fi
                fi
            elif [[ "$CH_PORT_LOCAL" == "443" ]]; then
                # Use HTTPS interface
                local base_url="https://${ch_host}"
                local auth_params=""
                if [[ -n "$CH_USER_LOCAL" ]]; then
                    if [[ -n "$CH_PASSWORD_LOCAL" ]]; then
                        auth_params="--user ${CH_USER_LOCAL}:${CH_PASSWORD_LOCAL}"
                    else
                        auth_params="--user ${CH_USER_LOCAL}:"
                    fi
                fi
            else
                # Use HTTP interface with custom port
                local base_url="http://${ch_host}:${CH_PORT_LOCAL}"
                local auth_params=""
                if [[ -n "$CH_USER_LOCAL" ]]; then
                    if [[ -n "$CH_PASSWORD_LOCAL" ]]; then
                        auth_params="--user ${CH_USER_LOCAL}:${CH_PASSWORD_LOCAL}"
                    else
                        auth_params="--user ${CH_USER_LOCAL}:"
                    fi
                fi
            fi
            
            if [[ "$CH_PORT_LOCAL" == "8123" || "$CH_PORT_LOCAL" == "443" ]]; then
                # Use HTTP/HTTPS interface
                # Drop and recreate database
                curl -s $auth_params -X POST "${base_url}/" -d "DROP DATABASE IF EXISTS ${local_db}" >> "$RESTORE_LOG_FILE" 2>&1
                curl -s $auth_params -X POST "${base_url}/" -d "CREATE DATABASE ${local_db}" >> "$RESTORE_LOG_FILE" 2>&1
                
                # Restore from backup (execute SQL file)
                if curl -s $auth_params -X POST "${base_url}/" --data-binary @"$backup_path" >> "$RESTORE_LOG_FILE" 2>&1; then
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "✅ Restore completed for $local_db in ${duration}s" | tee -a "$RESTORE_LOG_FILE"
                else
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "❌ Restore failed for $local_db after ${duration}s" | tee -a "$RESTORE_LOG_FILE"
                    exit 1
                fi
            else
                # Use native client
                if clickhouse-client --host="$ch_host" --port="$CH_PORT_LOCAL" \
                    ${CH_USER_LOCAL:+--user="$CH_USER_LOCAL"} \
                    ${CH_PASSWORD_LOCAL:+--password="$CH_PASSWORD_LOCAL"} \
                    --query="DROP DATABASE IF EXISTS $local_db" >> "$RESTORE_LOG_FILE" 2>&1 && \
                   clickhouse-client --host="$ch_host" --port="$CH_PORT_LOCAL" \
                    ${CH_USER_LOCAL:+--user="$CH_USER_LOCAL"} \
                    ${CH_PASSWORD_LOCAL:+--password="$CH_PASSWORD_LOCAL"} \
                    --query="CREATE DATABASE $local_db" >> "$RESTORE_LOG_FILE" 2>&1 && \
                   clickhouse-client --host="$ch_host" --port="$CH_PORT_LOCAL" \
                    ${CH_USER_LOCAL:+--user="$CH_USER_LOCAL"} \
                    ${CH_PASSWORD_LOCAL:+--password="$CH_PASSWORD_LOCAL"} \
                    --database="$local_db" < "$backup_path" >> "$RESTORE_LOG_FILE" 2>&1; then
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "✅ Restore completed for $local_db in ${duration}s" | tee -a "$RESTORE_LOG_FILE"
                else
                    db_end_time=$(date +%s)
                    duration=$((db_end_time - db_start_time))
                    echo "❌ Restore failed for $local_db after ${duration}s" | tee -a "$RESTORE_LOG_FILE"
                    exit 1
                fi
            fi
        ) &
        
        pids+=($!)
    done
    
    # Wait for all restores to complete
    local failed=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=1
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    if [[ $failed -eq 1 ]]; then
        echo "❌ Some restores failed. Total time: ${total_duration}s" | tee -a "$RESTORE_LOG_FILE"
        return 1
    fi
    
    echo "🎉 Database restore completed successfully in ${total_duration}s!" | tee -a "$RESTORE_LOG_FILE"
    
    # Archive all backups and logs after successful restore
    archive_files true
}

function backup_and_restore() {
    echo "🚀 Starting combined ClickHouse backup and restore operation..."
    
    if backup_databases; then
        echo "⏳ Backup completed, starting restore..."
        restore_databases "$DATE"
    else
        echo "❌ Backup failed, aborting restore operation"
        return 1
    fi
}

# Parse arguments
BACKGROUND=false
COMMAND="$1"
DATE_SUFFIX="$2"

# Check for --background flag in any position
for arg in "$@"; do
    if [[ "$arg" == "--background" ]]; then
        BACKGROUND=true
        break
    fi
done

# Adjust date_suffix if --background is in position 2
if [[ "$2" == "--background" ]]; then
    DATE_SUFFIX="$3"
fi

function run_in_background() {
    local operation="$1"
    local date_arg="$2"
    
    echo "🚀 Starting $operation in background..."
    
    # Create a unique background log
    BG_LOG="$BACKUP_DIR/clickhouse_background_${operation}_${LOG_TIMESTAMP}.log"
    
    # Run operation in background
    (
        case "$operation" in
            "backup")
                backup_databases
                ;;
            "restore")
                restore_databases "$date_arg"
                ;;
            "backup-restore")
                backup_and_restore
                ;;
        esac
    ) > "$BG_LOG" 2>&1 &
    
    local bg_pid=$!
    echo "📋 Process ID: $bg_pid"
    echo "📄 Background log: $BG_LOG"
    echo "💡 To follow progress: tail -f $BG_LOG"
    echo "🔍 To check if running: ps -p $bg_pid"
    echo "⏹️  To stop: kill $bg_pid"
    echo ""
    echo "✅ Operation started in background. Terminal is now free!"
}

# Main execution
case "$COMMAND" in
    "backup")
        if [[ "$BACKGROUND" == true ]]; then
            run_in_background "backup"
        else
            backup_databases
        fi
        ;;
    "restore")
        if [[ "$BACKGROUND" == true ]]; then
            run_in_background "restore" "$DATE_SUFFIX"
        else
            restore_databases "$DATE_SUFFIX"
        fi
        ;;
    "backup-restore")
        if [[ "$BACKGROUND" == true ]]; then
            run_in_background "backup-restore"
        else
            backup_and_restore
        fi
        ;;
    "archive")
        cd "$BACKUP_DIR"
        archive_files false
        ;;
    "list-archives")
        echo "📁 Available ClickHouse archives:"
        ls -lh "$ARCHIVE_DIR"/clickhouse_backup_archive_*.zip 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' || echo "No archives found"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
