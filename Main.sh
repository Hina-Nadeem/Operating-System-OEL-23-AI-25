#!/bin/bash

# Directories
PROJECT_DIR="$HOME/project"
BACKUP_BASE="$HOME/backup"

# Date
DATE=$(date +%F)
BACKUP_DIR="$BACKUP_BASE/backup_$DATE"

# Log & Report
LOG_FILE="cleanup.log"
REPORT_FILE="report.txt"

# Initialize
mkdir -p "$BACKUP_DIR"
echo "Cleanup Started: $(date)" > "$LOG_FILE"
echo "Cleanup Report - $DATE" > "$REPORT_FILE"

MOVED=0
DELETED=0
SPACE=0
ERRORS=0

# Check disk space
AVAILABLE=$(df "$BACKUP_BASE" | awk 'NR==2 {print $4}')

if [ "$AVAILABLE" -lt 102400 ]; then
    echo "Backup disk space low" | tee -a "$LOG_FILE" "$REPORT_FILE"
    exit 1
fi

echo "Backup directory created: $BACKUP_DIR" >> "$LOG_FILE"

# Move .log and .zip older than 30 days
while read file
do
    REL_PATH=$(dirname "${file#$PROJECT_DIR/}")
    DEST="$BACKUP_DIR/$REL_PATH"

    mkdir -p "$DEST"

    if mv "$file" "$DEST/" 2>>"$LOG_FILE"; then
        echo "Moved: $file" >> "$REPORT_FILE"
        ((MOVED++))
    else
        echo "Permission error: $file" >> "$REPORT_FILE"
        ((ERRORS++))
    fi

done < <(find "$PROJECT_DIR" -type f \( -name "*.log" -o -name "*.zip" \) -mtime +30)

# Delete .tmp older than 7 days
while read file
do
    SIZE=$(du -k "$file" | cut -f1)

    if rm "$file" 2>>"$LOG_FILE"; then
        echo "Deleted: $file" >> "$REPORT_FILE"
        SPACE=$((SPACE + SIZE))
        ((DELETED++))
    else
        echo "Permission error: $file" >> "$REPORT_FILE"
        ((ERRORS++))
    fi

done < <(find "$PROJECT_DIR" -type f -name "*.tmp" -mtime +7)

# Summary
echo "" >> "$REPORT_FILE"
echo "Summary:" >> "$REPORT_FILE"
echo "Files moved: $MOVED" >> "$REPORT_FILE"
echo "Files deleted: $DELETED" >> "$REPORT_FILE"
echo "Space cleared: ${SPACE} KB" >> "$REPORT_FILE"
echo "Errors: $ERRORS" >> "$REPORT_FILE"

echo "Cleanup finished: $(date)" >> "$LOG_FILE"