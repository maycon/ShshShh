#!/bin/bash
# decrypt.sh - Decrypt encrypted files
#
# Usage:
#   ./decrypt.sh devices.tsv.enc           # Decrypts to devices.tsv
#   ./decrypt.sh file.enc output.txt       # Decrypts to specific file
#   ./decrypt.sh blobs/*.shsh2.enc         # Decrypts multiple blobs
#
# Encryption key can be provided via:
#   1. ENCRYPTION_KEY environment variable
#   2. .encryption_key file
#   3. Interactive prompt

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_encryption_key() {
    if [[ -n "$ENCRYPTION_KEY" ]]; then
        echo "$ENCRYPTION_KEY"
    elif [[ -f ".encryption_key" ]]; then
        cat ".encryption_key"
    else
        read -s -p "Enter encryption key: " key
        echo >&2
        echo "$key"
    fi
}

decrypt_file() {
    local input="$1"
    local output="$2"
    local key="$3"
    
    if [[ ! -f "$input" ]]; then
        echo -e "${RED}❌ File not found: $input${NC}"
        return 1
    fi
    
    if openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
        -in "$input" \
        -out "$output" \
        -pass pass:"$key" 2>/dev/null; then
        echo -e "${GREEN}✅ Decrypted: $input → $output${NC}"
    else
        echo -e "${RED}❌ Failed to decrypt: $input (wrong key?)${NC}"
        return 1
    fi
}

if [[ $# -lt 1 ]]; then
    echo -e "${YELLOW}Usage: $0 <file.enc> [output]${NC}"
    echo "       $0 blobs/*.shsh2.enc"
    exit 1
fi

KEY=$(get_encryption_key)

if [[ -z "$KEY" ]]; then
    echo -e "${RED}❌ Error: No encryption key provided${NC}"
    exit 1
fi

if [[ $# -eq 2 && ! "$1" == *"*"* ]]; then
    decrypt_file "$1" "$2" "$KEY"
else
    for enc_file in "$@"; do
        if [[ -f "$enc_file" && "$enc_file" == *.enc ]]; then
            output="${enc_file%.enc}"
            decrypt_file "$enc_file" "$output" "$KEY"
        elif [[ -f "$enc_file" ]]; then
            output="${enc_file}.dec"
            decrypt_file "$enc_file" "$output" "$KEY"
        fi
    done
fi
