#!/bin/bash
# get-device-info.sh - Gather device information using libimobiledevice
#
# Usage:
#   ./get-device-info.sh              # Get info and output JSON
#   ./get-device-info.sh --add        # Add device to existing devices.json
#
# Requirements:
#   - libimobiledevice installed (ideviceinfo command)
#   - jq installed (for JSON manipulation)
#   - Device connected via USB and trusted

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check for required commands
check_dependencies() {
    if ! command -v ideviceinfo &> /dev/null; then
        echo -e "${RED}❌ Error: ideviceinfo not found${NC}"
        echo ""
        echo "Please install libimobiledevice:"
        echo "  - macOS:  brew install libimobiledevice"
        echo "  - Ubuntu: sudo apt install libimobiledevice-utils"
        echo "  - Windows: Use MSYS2 and run: pacman -S mingw-w64-x86_64-libimobiledevice"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: jq not found. JSON output will be basic.${NC}"
        HAS_JQ=false
    else
        HAS_JQ=true
    fi
}

# Get device info
get_device_info() {
    echo -e "${BLUE}📱 Connecting to device...${NC}"
    
    # Check if device is connected
    if ! ideviceinfo -k ProductType &> /dev/null; then
        echo -e "${RED}❌ Error: No device found${NC}"
        echo ""
        echo "Please make sure:"
        echo "  1. Your device is connected via USB"
        echo "  2. The device is unlocked"
        echo "  3. You have trusted this computer on the device"
        echo ""
        echo "Try running: idevicepair pair"
        exit 1
    fi

    # Gather information
    PRODUCT_TYPE=$(ideviceinfo -k ProductType 2>/dev/null || echo "")
    BOARD_CONFIG=$(ideviceinfo -k HardwareModel 2>/dev/null || echo "")
    ECID_DEC=$(ideviceinfo -k UniqueChipID 2>/dev/null || echo "")
    SERIAL=$(ideviceinfo -k SerialNumber 2>/dev/null || echo "")
    UDID=$(ideviceinfo -k UniqueDeviceID 2>/dev/null || echo "")
    DEVICE_NAME=$(ideviceinfo -k DeviceName 2>/dev/null || echo "My Device")
    DEVICE_COLOR=$(ideviceinfo -k DeviceColor 2>/dev/null || echo "")
    
    # Try to get IMEI (might not be available on all devices)
    IMEI=$(ideviceinfo -k InternationalMobileEquipmentIdentity 2>/dev/null || echo "")
    
    # Convert ECID to hex
    if [[ -n "$ECID_DEC" ]]; then
        ECID_HEX=$(printf "%X" "$ECID_DEC")
    else
        ECID_HEX=""
    fi

    echo -e "${GREEN}✅ Device found!${NC}"
    echo ""
}

# Display info
display_info() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    Device Information                      ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}Name:${NC}         $DEVICE_NAME"
    echo -e "  ${YELLOW}ProductType:${NC}  $PRODUCT_TYPE"
    echo -e "  ${YELLOW}BoardConfig:${NC}  $BOARD_CONFIG"
    echo -e "  ${YELLOW}ECID (dec):${NC}   $ECID_DEC"
    echo -e "  ${YELLOW}ECID (hex):${NC}   $ECID_HEX"
    echo -e "  ${YELLOW}Serial:${NC}       $SERIAL"
    echo -e "  ${YELLOW}UDID:${NC}         $UDID"
    [[ -n "$IMEI" ]] && echo -e "  ${YELLOW}IMEI:${NC}         $IMEI"
    [[ -n "$DEVICE_COLOR" ]] && echo -e "  ${YELLOW}Color:${NC}        $DEVICE_COLOR"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Generate JSON (minimal format - only what tsschecker needs)
generate_json() {
    echo ""
    echo -e "${GREEN}📋 JSON for devices.json:${NC}"
    echo ""
    
    if [[ "$HAS_JQ" == true ]]; then
        jq -n \
            --arg name "$DEVICE_NAME" \
            --arg productType "$PRODUCT_TYPE" \
            --arg boardConfig "$BOARD_CONFIG" \
            --arg ecid "$ECID_HEX" \
            '{
                name: $name,
                productType: $productType,
                boardConfig: $boardConfig,
                ecid: $ecid,
                generator: "0x1111111111111111"
            }'
    else
        cat << EOF
{
  "name": "$DEVICE_NAME",
  "productType": "$PRODUCT_TYPE",
  "boardConfig": "$BOARD_CONFIG",
  "ecid": "$ECID_HEX",
  "generator": "0x1111111111111111"
}
EOF
    fi
}

# Add to existing devices.json
add_to_devices_json() {
    if [[ ! -f "devices.json" ]]; then
        echo -e "${YELLOW}Creating new devices.json...${NC}"
        echo '{"devices": []}' > devices.json
    fi

    if [[ "$HAS_JQ" != true ]]; then
        echo -e "${RED}❌ Error: jq is required to add devices${NC}"
        echo "Please install jq and try again."
        exit 1
    fi

    # Create the new device object (minimal format)
    NEW_DEVICE=$(jq -n \
        --arg name "$DEVICE_NAME" \
        --arg productType "$PRODUCT_TYPE" \
        --arg boardConfig "$BOARD_CONFIG" \
        --arg ecid "$ECID_HEX" \
        '{
            name: $name,
            productType: $productType,
            boardConfig: $boardConfig,
            ecid: $ecid,
            generator: "0x1111111111111111"
        }')

    # Check if device already exists (by ECID)
    EXISTING=$(jq --arg ecid "$ECID_HEX" '.devices[] | select(.ecid == $ecid)' devices.json)
    
    if [[ -n "$EXISTING" ]]; then
        echo -e "${YELLOW}⚠️  Device with ECID $ECID_HEX already exists in devices.json${NC}"
        read -p "Update existing entry? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            jq --argjson device "$NEW_DEVICE" --arg ecid "$ECID_HEX" \
                '.devices = [.devices[] | if .ecid == $ecid then $device else . end]' \
                devices.json > devices.json.tmp && mv devices.json.tmp devices.json
            echo -e "${GREEN}✅ Device updated in devices.json${NC}"
        fi
    else
        jq --argjson device "$NEW_DEVICE" '.devices += [$device]' \
            devices.json > devices.json.tmp && mv devices.json.tmp devices.json
        echo -e "${GREEN}✅ Device added to devices.json${NC}"
    fi
}

# Main
main() {
    check_dependencies
    get_device_info
    display_info
    
    if [[ "$1" == "--add" ]]; then
        add_to_devices_json
    else
        generate_json
        echo ""
        echo -e "${YELLOW}💡 Tip: Run with --add to automatically add this device to devices.json${NC}"
    fi
}

main "$@"
