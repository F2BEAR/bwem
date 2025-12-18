#!bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

if [ $# -eq 0 ]; then
    log_error "You must provide the secure note name"
    echo "Usage: source $0 <note-name>"
    return 1 2>/dev/null || exit 1
fi

NOTE_NAME="$*"

if ! command -v bw &> /dev/null; then
    log_error "Bitwarden CLI is not installed"
    return 1 2>/dev/null || exit 1
fi

if [ -z "$BW_SESSION" ]; then
    log_warning "No active Bitwarden session"
    echo "Unlocking vault..."
    
    BW_UNLOCK_OUTPUT=$(bw unlock --raw)
    
    if [ $? -ne 0 ]; then
        log_error "Could not unlock the vault"
        return 1 2>/dev/null || exit 1
    fi
    
    export BW_SESSION="$BW_UNLOCK_OUTPUT"
    log_info "Vault unlocked successfully"
fi

log_info "Syncing with Bitwarden..."
bw sync --session "$BW_SESSION" > /dev/null 2>&1 || log_warning "Could not synchronize"

log_info "Searching for note: $NOTE_NAME"
NOTE_ID=$(bw list items --search "$NOTE_NAME" --session "$BW_SESSION" | jq -r '.[0].id' 2>/dev/null)

if [ -z "$NOTE_ID" ] || [ "$NOTE_ID" = "null" ]; then
    log_error "No note found with the name: '$NOTE_NAME'"
    return 1 2>/dev/null || exit 1
fi

NOTE_CONTENT=$(bw get notes "$NOTE_ID" --session "$BW_SESSION" 2>/dev/null)

if [ -z "$NOTE_CONTENT" ] || [ "$NOTE_CONTENT" = "null" ]; then
    log_error "The note is empty or its content could not be retrieved"
    return 1 2>/dev/null || exit 1
fi

log_info "Loading environment variables..."

VAR_COUNT=0

while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=.* ]]; then
        export "$line"
        VAR_NAME=$(echo "$line" | cut -d'=' -f1)
        log_info "✓ Loaded: $VAR_NAME"
        ((VAR_COUNT++))
    fi
done <<< "$NOTE_CONTENT"

if [ $VAR_COUNT -eq 0 ]; then
    log_warning "No valid environment variables found"
    echo "Expected format: KEY=VALUE (one per line)"
    return 1 2>/dev/null || exit 1
fi

log_info "✅ Successfully loaded $VAR_COUNT environment variables"
echo ""
echo "Variables will be available while this terminal is open."
echo "To unload variables, close the terminal or run: unset \$(compgen -v | grep -E '^[A-Z_]+$')"
