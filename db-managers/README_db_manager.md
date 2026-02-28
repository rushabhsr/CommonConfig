# PostgreSQL Database Manager

A powerful PostgreSQL backup and restore tool with parallel processing, archiving, and background execution capabilities.

## Features

- **PostgreSQL Specific**: Uses `pg_dump`, `pg_restore`, and `psql` commands
- **Parallel Processing**: Multiple databases backup/restore simultaneously
- **Background Execution**: Run operations without blocking terminal
- **Automatic Archiving**: Smart file management with configurable archiving
- **Detailed Logging**: Comprehensive logs with timing information
- **Configurable**: External config file for easy customization

## Quick Start

1. **Copy files to your project directory:**
   ```bash
   cp ~/CommonConfig/db_manager.sh /path/to/your/project/
   cp ~/CommonConfig/db_manager.config.example /path/to/your/project/db_manager.config
   ```

2. **Edit configuration:**
   ```bash
   nano db_manager.config
   ```

3. **Make executable:**
   ```bash
   chmod +x db_manager.sh
   ```

## Configuration

Edit `db_manager.config` with your settings:

```bash
# Remote Database (Source)
PG_USER_BACKUP="your_backup_user"
PG_PASSWORD_BACKUP="your_backup_password"
PG_HOST_BACKUP="your-remote-host.amazonaws.com"

# Local Database (Target)
PG_USER_LOCAL="your_local_user"
PG_PASSWORD_LOCAL="your_local_password"
PG_HOST_LOCAL="localhost"

# Paths
BACKUP_DIR="/path/to/your/db_dumps"
ARCHIVE_DIR="/path/to/your/db_dumps/archives"

# Database Mappings (remote_db:local_db)
DATABASE_MAPPINGS=(
    "remote_db1:local_db1"
    "remote_db2:local_db2"
)
```

## Usage

### Basic Commands

```bash
# Backup databases
./db_manager.sh backup

# Restore databases
./db_manager.sh restore oct30

# Backup then restore
./db_manager.sh backup-restore

# Archive old files manually
./db_manager.sh archive

# List archives
./db_manager.sh list-archives
```

### Background Execution

Run operations in background (non-blocking):

```bash
# Background backup
./db_manager.sh backup --background

# Background backup-restore
./db_manager.sh backup-restore --background

# Background restore
./db_manager.sh restore oct30 --background
```

**Background output example:**
```
🚀 Starting backup-restore in background...
📋 Process ID: 12345
📄 Background log: /path/to/background_backup-restore_dec03_1924.log
💡 To follow progress: tail -f /path/to/background_backup-restore_dec03_1924.log
🔍 To check if running: ps -p 12345
⏹️  To stop: kill 12345

✅ Operation started in background. Terminal is now free!
```

## File Management

### Archiving Behavior

- **After Backup**: Only old files archived, current backups preserved
- **After Restore**: ALL files archived for clean directory
- **Manual Archive**: Only old files archived

### Log Files

- **Backup logs**: `postgresql_backup_MMDD_HHMM.log`
- **Restore logs**: `postgresql_restore_MMDD_HHMM.log`
- **Background logs**: `background_operation_MMDD_HHMM.log`

## Performance Features

### Parallel Processing
- All databases process simultaneously
- Individual timing for each database
- Total operation time tracking
- Failure handling with early termination

### Example Output
```
📦 Starting backup for claim -> cms_dec03.sql
📦 Starting backup for cms_uat_ops -> ops_dec03.sql
✅ Backup for claim completed in 23s
✅ Backup for cms_uat_ops completed in 45s
🎉 All backups completed successfully in 47s!
```

## Monitoring

### Follow Progress
```bash
# Follow backup logs
tail -f postgresql_backup_dec03_1924.log

# Follow background operation
tail -f background_backup-restore_dec03_1924.log
```

### Check Background Process
```bash
# Check if process is running
ps -p 12345

# Stop background process
kill 12345
```

## Directory Structure

```
your-project/
├── db_manager.sh           # Main script
├── db_manager.config       # Your configuration (gitignored)
├── db_manager.config.example # Template for sharing
├── .gitignore             # Excludes sensitive files
├── *.sql                  # Backup files (gitignored)
├── *.log                  # Log files (gitignored)
└── archives/              # Archived files (gitignored)
    └── backup_archive_*.zip
```

## Git Integration

The script includes a `.gitignore` file that excludes:
- `db_manager.config` (contains sensitive credentials)
- `*.sql` and `*.log` files
- `archives/` directory

Only `db_manager.sh` and `db_manager.config.example` are tracked in git.

## Troubleshooting

### Common Issues

1. **Config file not found**
   ```
   ❌ Configuration file not found: ./db_manager.config
   ```
   **Solution**: Copy `db_manager.config.example` to `db_manager.config`

2. **Permission denied**
   ```
   bash: ./db_manager.sh: Permission denied
   ```
   **Solution**: `chmod +x db_manager.sh`

3. **Database connection failed**
   **Solution**: Check credentials and network connectivity in config file

### Log Analysis

Check log files for detailed error information:
```bash
# View latest backup log
ls -t postgresql_backup_*.log | head -1 | xargs cat

# Search for errors
grep -i error *.log
```

## Requirements

- **PostgreSQL**: This script is designed specifically for PostgreSQL databases
- PostgreSQL client tools (`pg_dump`, `pg_restore`, `psql`) must be installed
- `zip` command for archiving
- Bash 4.0+ (for associative arrays)
- Network access to source and target PostgreSQL servers

## Security Notes

- Never commit `db_manager.config` to version control
- Use strong passwords and consider using `.pgpass` file
- Restrict file permissions: `chmod 600 db_manager.config`
- Regularly rotate database credentials

## License

This script is provided as-is for database management purposes.
