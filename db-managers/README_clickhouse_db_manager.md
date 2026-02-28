# ClickHouse Database Manager

A powerful ClickHouse backup and restore tool with parallel processing, archiving, and background execution capabilities.

## Features

- **ClickHouse Specific**: Uses `clickhouse-client` commands for backup/restore
- **Parallel Processing**: Multiple databases backup/restore simultaneously
- **Background Execution**: Run operations without blocking terminal
- **Automatic Archiving**: Smart file management with configurable archiving
- **Detailed Logging**: Comprehensive logs with timing information
- **Configurable**: External config file for easy customization

## Quick Start

1. **Copy files to your project directory:**
   ```bash
   cp ~/CommonConfig/clickhouse_db_manager.sh /path/to/your/project/
   cp ~/CommonConfig/clickhouse_db_manager.config.example /path/to/your/project/clickhouse_db_manager.config
   ```

2. **Edit configuration:**
   ```bash
   nano clickhouse_db_manager.config
   ```

3. **Make executable:**
   ```bash
   chmod +x clickhouse_db_manager.sh
   ```

## Configuration

Edit `clickhouse_db_manager.config` with your settings:

```bash
# Remote ClickHouse (Source)
CH_USER_BACKUP="your_backup_user"
CH_PASSWORD_BACKUP="your_backup_password"
CH_HOST_BACKUP="your-remote-clickhouse-host.com"
CH_PORT_BACKUP="9000"

# Local ClickHouse (Target)
CH_USER_LOCAL="your_local_user"
CH_PASSWORD_LOCAL="your_local_password"
CH_HOST_LOCAL="localhost"
CH_PORT_LOCAL="9000"

# Paths
BACKUP_DIR="/path/to/your/clickhouse_dumps"
ARCHIVE_DIR="/path/to/your/clickhouse_dumps/archives"

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
./clickhouse_db_manager.sh backup

# Restore databases
./clickhouse_db_manager.sh restore oct30

# Backup then restore
./clickhouse_db_manager.sh backup-restore

# Archive old files manually
./clickhouse_db_manager.sh archive

# List archives
./clickhouse_db_manager.sh list-archives
```

### Background Execution

Run operations in background (non-blocking):

```bash
# Background backup
./clickhouse_db_manager.sh backup --background

# Background backup-restore
./clickhouse_db_manager.sh backup-restore --background

# Background restore
./clickhouse_db_manager.sh restore oct30 --background
```

**Background output example:**
```
🚀 Starting backup-restore in background...
📋 Process ID: 12345
📄 Background log: /path/to/clickhouse_background_backup-restore_dec03_1924.log
💡 To follow progress: tail -f /path/to/clickhouse_background_backup-restore_dec03_1924.log
🔍 To check if running: ps -p 12345
⏹️  To stop: kill 12345

✅ Operation started in background. Terminal is now free!
```

## ClickHouse Backup Process

### How Backup Works

1. **Database Structure**: Exports `SHOW CREATE DATABASE` statements
2. **Table Schemas**: Exports `SHOW CREATE TABLE` for each table
3. **Data Export**: Exports table data in TabSeparated format
4. **Parallel Processing**: All databases backed up simultaneously

### Backup File Format

Each backup file contains:
```sql
-- Database creation
CREATE DATABASE database_name;

-- Table: table1
CREATE TABLE database_name.table1 (...);
-- Data for table1 (TabSeparated format)

-- Table: table2
CREATE TABLE database_name.table2 (...);
-- Data for table2 (TabSeparated format)
```

## File Management

### Archiving Behavior

- **After Backup**: Only old files archived, current backups preserved
- **After Restore**: ALL files archived for clean directory
- **Manual Archive**: Only old files archived

### Log Files

- **Backup logs**: `clickhouse_backup_MMDD_HHMM.log`
- **Restore logs**: `clickhouse_restore_MMDD_HHMM.log`
- **Background logs**: `clickhouse_background_operation_MMDD_HHMM.log`

## Performance Features

### Parallel Processing
- All databases process simultaneously
- Individual timing for each database
- Total operation time tracking
- Failure handling with early termination

### Example Output
```
📦 Starting backup for analytics -> analytics_dec03.sql
📦 Starting backup for logs -> logs_dec03.sql
✅ Backup for analytics completed in 23s
✅ Backup for logs completed in 45s
🎉 All backups completed successfully in 47s!
```

## Monitoring

### Follow Progress
```bash
# Follow backup logs
tail -f clickhouse_backup_dec03_1924.log

# Follow background operation
tail -f clickhouse_background_backup-restore_dec03_1924.log
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
├── clickhouse_db_manager.sh           # Main script
├── clickhouse_db_manager.config       # Your configuration (gitignored)
├── clickhouse_db_manager.config.example # Template for sharing
├── .gitignore                         # Excludes sensitive files
├── *.sql                              # Backup files (gitignored)
├── *.log                              # Log files (gitignored)
└── archives/                          # Archived files (gitignored)
    └── clickhouse_backup_archive_*.zip
```

## Troubleshooting

### Common Issues

1. **Config file not found**
   ```
   ❌ Configuration file not found: ./clickhouse_db_manager.config
   ```
   **Solution**: Copy `clickhouse_db_manager.config.example` to `clickhouse_db_manager.config`

2. **ClickHouse client not found**
   ```
   bash: clickhouse-client: command not found
   ```
   **Solution**: Install ClickHouse client tools

3. **Connection failed**
   **Solution**: Check host, port, credentials in config file

4. **Permission denied**
   ```
   bash: ./clickhouse_db_manager.sh: Permission denied
   ```
   **Solution**: `chmod +x clickhouse_db_manager.sh`

### Log Analysis

Check log files for detailed error information:
```bash
# View latest backup log
ls -t clickhouse_backup_*.log | head -1 | xargs cat

# Search for errors
grep -i error *.log
```

## Requirements

- **ClickHouse**: This script is designed specifically for ClickHouse databases
- ClickHouse client tools (`clickhouse-client`) must be installed
- `zip` command for archiving
- Bash 4.0+ (for associative arrays)
- Network access to source and target ClickHouse servers

## ClickHouse Client Installation

### Ubuntu/Debian
```bash
sudo apt-get install -y apt-transport-https ca-certificates dirmngr
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8919F6BD2B48D754
echo "deb https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo apt-get install -y clickhouse-client
```

### CentOS/RHEL
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
sudo yum install -y clickhouse-client
```

## Security Notes

- Never commit `clickhouse_db_manager.config` to version control
- Use strong passwords and consider IP restrictions
- Restrict file permissions: `chmod 600 clickhouse_db_manager.config`
- Regularly rotate database credentials
- Consider using ClickHouse users with limited permissions for backups

## Limitations

- **Large Tables**: Very large tables may take significant time to backup
- **Data Types**: Some ClickHouse-specific data types may need special handling
- **Materialized Views**: May need manual recreation after restore
- **Partitions**: Partition information is preserved in CREATE TABLE statements

## License

This script is provided as-is for ClickHouse database management purposes.
