#!/bin/bash


log_error() {
    echo "[ERROR] $1" >&2
}


log_info() {
    echo "[INFO] $1"
}


log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}


require_dir() {
    if [ ! -d "$1" ]; then
        log_error "Directory does not exist"
        return 1
    fi
    return 0
} 