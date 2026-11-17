
#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
source "$SCRIPT_DIR/lib.sh"

# Target directory
target_dir="${1:-.}"

# Log file
LOG_FILE="$target_dir/audit.log"

# Check that the target directory exists
if ! require_dir "$target_dir"; then
    exit 1
fi


# 1. Scan Directory
scan_directory() {
    local f

    echo "===== DIRECTORY SCAN ====="

    for f in "$target_dir"/*; do
        if [ -e "$f" ]; then
            if [ -f "$f" ]; then
                echo "File: ${f##*/}"
            elif [ -d "$f" ]; then
                echo "Directory: ${f##*/}"
            fi
        fi
    done

    log_action "Directory scan completed"
}


# 2. Permission Audit
permission_audit() {
    local f
    local permissions

    echo "===== PERMISSION AUDIT ====="

    for f in "$target_dir"/*; do
        if [ -e "$f" ]; then
            permissions=$(stat -c "%A" "$f")
            echo "${f##*/} : $permissions"
        fi
    done

    log_action "Permission audit completed"
}


# 3. Extension Report
extension_report() {
    local f
    local filename
    local ext

    declare -A extension_count

    echo "===== EXTENSION REPORT ====="

    for f in "$target_dir"/*; do
        if [ -f "$f" ]; then
            filename="${f##*/}"

            if [[ "$filename" == *.* && "$filename" != .* ]]; then
                ext="${filename##*.}"
            else
                ext="other"
            fi

            ((extension_count["$ext"]++))
        fi
    done

    for ext in "${!extension_count[@]}"; do
        echo "$ext : ${extension_count[$ext]} file(s)"
    done

    log_action "Extension report completed"
}


# 4. Search File
search_file() {
    local search_text
    local f
    local found=0

    read -r -p "Enter text to search: " search_text

    for f in "$target_dir"/*; do
        if [ -f "$f" ]; then
            if [[ "${f##*/}" == *"$search_text"* ]]; then
                echo "${f##*/}"
                found=1
            fi
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "No matching files found"
    fi

    log_action "Search completed"
}


# 5. Backup All
backup_all() {
    local backup_dir="$target_dir/backups"
    local f
    local filename
    local timestamp
    local saved=0
    local skipped=0

    mkdir -p "$backup_dir"

    timestamp=$(date '+%Y%m%d_%H%M%S')

    for f in "$target_dir"/*; do
        if [ -f "$f" ]; then
            filename="${f##*/}"

            if [ -r "$f" ]; then
                cp "$f" "$backup_dir/${filename}_${timestamp}.bak"

                if [ $? -eq 0 ]; then
                    ((saved++))
                else
                    ((skipped++))
                fi
            else
                echo "Cannot read: $filename"
                ((skipped++))
            fi
        fi
    done

    echo "Files saved: $saved"
    echo "Files skipped: $skipped"

    log_action "Backup completed"
}


# 6. List Backups
list_backups() {
    local backup
    local found=0

    for backup in "$target_dir"/backups/*.bak; do
        if [ -f "$backup" ]; then
            echo "${backup##*/}"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "(no backups yet)"
    fi

    log_action "List backups completed"
}


# 7. Restore Backup
restore_backup() {
    local backup_name
    local source_file
    local destination

    read -r -p "Enter backup name: " backup_name

    source_file="$target_dir/backups/$backup_name"
    destination="$target_dir/restored_$backup_name"

    if [ ! -f "$source_file" ]; then
        log_error "Backup does not exist"
        log_action "Restore failed"
        return 1
    elif [ -e "$destination" ]; then
        log_error "File already exists"
        log_action "Restore failed"
        return 1
    else
        cp "$source_file" "$destination"

        if [ $? -eq 0 ]; then
            echo "Backup restored successfully"
            log_action "Restore completed"
        else
            log_error "Restore failed"
            log_action "Restore failed"
            return 1
        fi
    fi
}


# Main Menu
menu() {
    local choice

    while true; do
        echo
        echo "===== FILE AUDITOR ====="
        echo "1. Scan Directory"
        echo "2. Permission Audit"
        echo "3. Extension Report"
        echo "4. Search File"
        echo "5. Backup All"
        echo "6. List Backups"
        echo "7. Restore Backup"
        echo "8. Exit"

        read -r -p "Enter your choice: " choice

        case "$choice" in
            1) scan_directory ;;
            2) permission_audit ;;
            3) extension_report ;;
            4) search_file ;;
            5) backup_all ;;
            6) list_backups ;;
            7) restore_backup ;;
            8)
                echo "Goodbye!"
                break
                ;;
            *)
                log_error "Invalid choice"
                ;;
        esac
    done
}


# Command Line Options
if [ -n "${2:-}" ]; then
    case "$2" in
        scan) scan_directory ;;
        perms) permission_audit ;;
        ext) extension_report ;;
        backup) backup_all ;;
        *)
            log_error "Invalid action"
            exit 1
            ;;
    esac
else
    menu
fi
