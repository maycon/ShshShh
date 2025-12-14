#!/bin/bash
# encrypt.sh - Encrypt sensitive files
#
# Usage:
#   ./encrypt.sh              # Encrypts devices.tsv
#   ./encrypt.sh file.txt     # Encrypts specific file
#
# Encryption key can be provided via:
#   1. ENCRYPTION_KEY environment variable
#   2. .encryption_key file (don't commit this!)
#   3. Interactive prompt

set -e

INPUT_FILE="${1:-devices.json}"
OUTPUT_FILE="${INPUT_FILE}.enc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔐 Encrypting: ${INPUT_FILE}${NC}"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo -e "${RED}❌ Error: File '$INPUT_FILE' not found${NC}"
    exit 1
fi

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

KEY=$(get_encryption_key)

if [[ -z "$KEY" ]]; then
    echo -e "${RED}❌ Error: No encryption key provided${NC}"
    exit 1
fi

if [[ ${#KEY} -lt 16 ]]; then
    echo -e "${RED}❌ Error: Key must be at least 16 characters${NC}"
    exit 1
fi

openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
    -in "$INPUT_FILE" \
    -out "$OUTPUT_FILE" \
    -pass pass:"$KEY"

echo -e "${GREEN}✅ Encrypted: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   1. Add '$INPUT_FILE' to .gitignore"
echo "   2. Add '.encryption_key' to .gitignore"
echo "   3. Set ENCRYPTION_KEY as a GitHub secret"
echo ""
echo -e "${GREEN}To decrypt:${NC}"
echo "   ./decrypt.sh $OUTPUT_FILE"
