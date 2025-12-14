# 🤫 ShshShh

[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/maycon/ShshShh/update-blobs.yml?branch=main&label=blob%20saver&logo=github)](https://github.com/maycon/ShshShh/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![iOS](https://img.shields.io/badge/iOS-blobs-black?logo=apple)](https://github.com/maycon/ShshShh/releases)
[![Encryption](https://img.shields.io/badge/encryption-AES--256--CBC-green?logo=openssl)](https://www.openssl.org/)
[![Made with Love](https://img.shields.io/badge/made%20with-❤️-red)](https://github.com/hacknroll)

> *Shhh... your blobs are safe now*

Automated SHSH2 blob saver with **end-to-end encryption**. Keep your iOS device identifiers private while maintaining a public backup of your precious blobs.

## Table of Contents

- [Why Encrypt?](#why-encrypt)
- [Quick Start](#quick-start)
- [Getting Device Information](#getting-device-information)
  - [From the Device](#from-the-device)
  - [Using libimobiledevice](#using-libimobiledevice)
  - [Using Finder/iTunes](#using-finderitunes)
- [devices.json Format](#devicesjson-format)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Local Testing with Act](#local-testing-with-act)
- [Contributing](#contributing)
- [License](#license)

## Why Encrypt?

SHSH2 blobs and device files contain sensitive information:

| Data | Sensitivity | Risk |
|------|-------------|------|
| ECID | 🔴 High | Unique device identifier |
| IMEI | 🔴 High | Can be used for tracking |
| UDID | 🔴 High | Unique device identifier |
| Serial Number | 🟡 Medium | Hardware identification |
| SHSH2 Blob | 🟡 Medium | Contains embedded ECID |

ShshShh encrypts everything so you can safely store blobs in a public repository.

## Quick Start

### 1. Generate a Strong Key

```bash
openssl rand -base64 32
```

Save this key somewhere secure (password manager, etc).

### 2. Configure GitHub Secret

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Name: `ENCRYPTION_KEY`
4. Value: your generated key

### 3. Create Your devices.json

See [Getting Device Information](#getting-device-information) below, then create your `devices.json` file.

### 4. Encrypt and Commit

```bash
export ENCRYPTION_KEY="your-key-here"
./scripts/encrypt.sh devices.json
git add devices.json.enc .gitignore
git commit -m "Add encrypted devices file"
git push
```

---

## Getting Device Information

You'll need the following information for each device:

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Friendly name (e.g., "My iPhone 14") |
| `productType` | Yes | Model identifier (e.g., "iPhone15,2") |
| `ecid` | Yes | Exclusive Chip ID in **hexadecimal** |
| `boardConfig` | Yes | Board configuration (e.g., "D73AP") |
| `serialNumber` | No | Device serial number |
| `udid` | No | Unique Device Identifier |
| `imei` | No | IMEI number |

### From the Device

#### iOS Settings (Basic Info)

1. Open **Settings → General → About**
2. You can find:
   - **Serial Number**: Tap and hold to copy
   - **IMEI**: Scroll down, tap and hold to copy
   - **Model Name**: Shows device model

> ⚠️ **Note**: ECID is **not** visible in iOS Settings. You need a computer to get it.

#### Finding Your ProductType and BoardConfig

Use this reference table or check [The iPhone Wiki](https://www.theiphonewiki.com/wiki/Models):

| Device | ProductType | BoardConfig |
|--------|-------------|-------------|
| iPhone 7 (GSM) | iPhone9,3 | D101AP |
| iPhone 7 (Global) | iPhone9,1 | D10AP |
| iPhone 7 Plus (GSM) | iPhone9,4 | D111AP |
| iPhone 7 Plus (Global) | iPhone9,2 | D11AP |
| iPhone 8 | iPhone10,1 / iPhone10,4 | D20AP / D201AP |
| iPhone 8 Plus | iPhone10,2 / iPhone10,5 | D21AP / D211AP |
| iPhone X | iPhone10,3 / iPhone10,6 | D22AP / D221AP |
| iPhone XR | iPhone11,8 | N841AP |
| iPhone XS | iPhone11,2 | D321AP |
| iPhone XS Max | iPhone11,4 / iPhone11,6 | D331AP / D331pAP |
| iPhone 11 | iPhone12,1 | N104AP |
| iPhone 11 Pro | iPhone12,3 | D421AP |
| iPhone 11 Pro Max | iPhone12,5 | D431AP |
| iPhone 12 mini | iPhone13,1 | D52gAP |
| iPhone 12 | iPhone13,2 | D53gAP |
| iPhone 12 Pro | iPhone13,3 | D53pAP |
| iPhone 12 Pro Max | iPhone13,4 | D54pAP |
| iPhone 13 mini | iPhone14,4 | D16AP |
| iPhone 13 | iPhone14,5 | D17AP |
| iPhone 13 Pro | iPhone14,2 | D63AP |
| iPhone 13 Pro Max | iPhone14,3 | D64AP |
| iPhone 14 | iPhone14,7 | D27AP |
| iPhone 14 Plus | iPhone14,8 | D28AP |
| iPhone 14 Pro | iPhone15,2 | D73AP |
| iPhone 14 Pro Max | iPhone15,3 | D74AP |
| iPhone 15 | iPhone15,4 | D37AP |
| iPhone 15 Plus | iPhone15,5 | D38AP |
| iPhone 15 Pro | iPhone16,1 | D83AP |
| iPhone 15 Pro Max | iPhone16,2 | D84AP |

---

### Using libimobiledevice

**libimobiledevice** is a cross-platform tool to communicate with iOS devices. It's the most reliable way to get all device information.

#### 🐧 Linux (Ubuntu/Debian)

```bash
# Install from package manager
sudo apt-get update
sudo apt-get install -y libimobiledevice-utils

# Connect your device via USB and trust it
# Then run:
ideviceinfo
```

If the package is outdated, build from source:

```bash
# Install dependencies
sudo apt-get install -y build-essential git autoconf automake \
    libtool-bin libplist-dev libusbmuxd-dev libssl-dev usbmuxd

# Clone and build
git clone https://github.com/libimobiledevice/libimobiledevice.git
cd libimobiledevice
./autogen.sh --prefix=/usr
make
sudo make install
```

#### 🍎 macOS

```bash
# Using Homebrew
brew install libimobiledevice

# Connect your device and trust it
ideviceinfo
```

If you need the latest version:

```bash
brew install --HEAD libimobiledevice
```

#### 🪟 Windows

**Option 1: Using MSYS2 (Recommended)**

1. Install [MSYS2](https://www.msys2.org/)
2. Open MSYS2 MinGW 64-bit terminal
3. Run:

```bash
pacman -S mingw-w64-x86_64-libimobiledevice
ideviceinfo
```

**Option 2: Pre-compiled Binaries**

Download from [libimobiledevice-win32](https://github.com/libimobiledevice-win32/imobiledevice-net/releases) releases.

**Option 3: Using WSL**

Install WSL2 and follow the Linux instructions. Note: USB passthrough requires additional setup.

#### Getting All Required Info with libimobiledevice

Once installed, connect your device via USB, trust it, and run:

```bash
# Get all info at once
ideviceinfo

# Or get specific values:
ideviceinfo -k ProductType      # e.g., iPhone14,3
ideviceinfo -k UniqueChipID     # ECID in decimal
ideviceinfo -k HardwareModel    # e.g., D64AP
ideviceinfo -k SerialNumber     # Serial number
ideviceinfo -k UniqueDeviceID   # UDID

# Get ECID in hex (convert from decimal)
ECID_DEC=$(ideviceinfo -k UniqueChipID)
printf "ECID (hex): %X\n" $ECID_DEC
```

**One-liner to get all required info:**

```bash
echo "ProductType: $(ideviceinfo -k ProductType)"
echo "BoardConfig: $(ideviceinfo -k HardwareModel)"
ECID_DEC=$(ideviceinfo -k UniqueChipID)
echo "ECID (dec): $ECID_DEC"
printf "ECID (hex): %X\n" $ECID_DEC
echo "Serial: $(ideviceinfo -k SerialNumber)"
echo "UDID: $(ideviceinfo -k UniqueDeviceID)"
```

---

### Using Finder/iTunes

#### 🍎 macOS (Finder)

1. Connect your iPhone to your Mac
2. Open **Finder** and select your device in the sidebar
3. Click on the device info below the device name:
   - Click once: Shows **Serial Number**
   - Click again: Shows **UDID**
   - Click again: Shows **ECID** (in hexadecimal)

> 💡 Right-click on any value to copy it.

#### 🪟 Windows (iTunes - Legacy)

> ⚠️ Note: Apple has removed device management from iTunes on Windows. Use the **Apple Devices** app or libimobiledevice instead.

For older iTunes versions:
1. Connect your iPhone and open iTunes
2. Click the device icon
3. On the Summary page, click **Serial Number** repeatedly to cycle through UDID and ECID

#### 🪟 Windows (Recovery/DFU Mode)

1. Put your device in **Recovery Mode** or **DFU Mode**
2. Open **Device Manager**
3. Find **Apple Mobile Device (Recovery Mode)** or **Apple Mobile Device (DFU Mode)**
4. Right-click → **Properties** → **Details** tab
5. Select **Device Instance Path** from the dropdown
6. The ECID is part of the value shown

---

## devices.json Format

We use **JSON** instead of TSV for better structure and validation. The format is minimal - only storing what `tsschecker` actually needs.

### Format

```json
{
  "devices": [
    {
      "name": "My iPhone 14 Pro",
      "productType": "iPhone15,2",
      "boardConfig": "D73AP",
      "ecid": "1A2B3C4D5E6F",
      "generator": "0x1111111111111111"
    },
    {
      "name": "Work iPhone 13",
      "productType": "iPhone14,5",
      "boardConfig": "D17AP",
      "ecid": "AABBCCDD1234",
      "generator": "0x1111111111111111"
    }
  ]
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Friendly device name (for your reference) |
| `productType` | string | ✅ | Model identifier (e.g., "iPhone15,2") |
| `boardConfig` | string | ✅ | Board config (e.g., "D73AP") |
| `ecid` | string | ✅ | ECID in **hexadecimal** (without 0x prefix) |
| `generator` | string | ✅ | Nonce generator (default: "0x1111111111111111") |

### What NOT to Store

**Don't include** these fields - they're not needed by tsschecker and only increase risk if leaked:

- ❌ `serialNumber` - Not used
- ❌ `udid` - Not used  
- ❌ `imei` - Not used
- ❌ `color` - Not used

### Why JSON over TSV?

| Feature | TSV | JSON |
|---------|-----|------|
| Human readable | 🟡 | ✅ |
| Structured data | ❌ | ✅ |
| Validation | ❌ | ✅ |
| Easy parsing | 🟡 | ✅ |

---

## Usage

### Decrypt Downloaded Blobs

```bash
# Download a release
gh release download 18.2 -D ./blobs/

# Decrypt all blobs
export ENCRYPTION_KEY="your-key"
./scripts/decrypt.sh blobs/*.enc
```

### Add a New Device

```bash
# 1. Decrypt
./scripts/decrypt.sh devices.json.enc

# 2. Edit (add new device to the array)
nano devices.json

# 3. Re-encrypt
./scripts/encrypt.sh devices.json

# 4. Commit
git add devices.json.enc
git commit -m "Add new device"
git push
```

### Manual Blob Saving (Testing)

```bash
# Using tsschecker directly
tsschecker \
  --device iPhone15,2 \
  --boardconfig D73AP \
  --ecid 0x1A2B3C4D5E6F \
  --generator 0x1111111111111111 \
  --latest \
  --save
```

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── update-blobs.yml    # Automated workflow
├── scripts/
│   ├── encrypt.sh              # Encrypt files locally
│   └── decrypt.sh              # Decrypt files locally
├── devices.json.enc            # 🔒 Encrypted device list
├── .gitignore                  # Prevents accidental commits
└── README.md
```

---

## Security

### What's Protected

- ✅ **devices.json** - Encrypted with AES-256-CBC
- ✅ **SHSH2 blobs** - Encrypted before upload to releases
- ✅ **GitHub Actions logs** - Sensitive data is masked
- ✅ **Releases** - Contain only encrypted files

### Best Practices

1. **Never** commit decrypted `devices.json`
2. **Never** put the key in repository files
3. **Rotate** your key periodically
4. Use a **password manager** for the key
5. Enable **2FA** on your GitHub account

### Encryption Details

- **Cipher**: AES-256-CBC
- **Key Derivation**: PBKDF2 with 100,000 iterations
- **Compatible with**: OpenSSL 1.1+

---

## Troubleshooting

### "bad decrypt" Error

The key is incorrect. Make sure you're using the same key that was used for encryption.

### Workflow Fails on GitHub Actions

Verify the `ENCRYPTION_KEY` secret is correctly configured in repository settings.

### "No device found" with libimobiledevice

1. Make sure the device is unlocked
2. Trust the computer on your device when prompted
3. Try running `idevicepair pair` first
4. On Linux, you may need udev rules:
   ```bash
   sudo sh -c 'echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"05ac\", MODE=\"0666\"" > /etc/udev/rules.d/51-apple.rules'
   sudo udevadm control --reload-rules
   ```

### Can't Find ECID on newer macOS/Windows

Use libimobiledevice or checkra1n to view ECID. Apple has removed this from newer versions of Finder/iTunes.

---

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  devices.json   │────▶│  GitHub Actions  │────▶│  Encrypted      │
│  (encrypted)    │     │  (decrypts,      │     │  SHSH2 blobs    │
│                 │     │   runs tsschecker│     │  in Releases    │
└─────────────────┘     │   encrypts blobs)│     └─────────────────┘
                        └──────────────────┘
                                │
                                ▼
                        ┌──────────────────┐
                        │  Logs show only  │
                        │  masked ECIDs:   │
                        │  1910****8326    │
                        └──────────────────┘
```

---

## Local Testing with Act

You can test the workflow locally using [act](https://github.com/nektos/act) before pushing to GitHub.

### Install Act

```bash
# macOS
brew install act

# Linux (using GitHub's official script)
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Windows (using Chocolatey)
choco install act-cli
```

> ⚠️ **Requirement**: Docker must be installed and running.

### Setup

1. **Create a secrets file** (never commit this!):

```bash
# .secrets (add to .gitignore!)
ENCRYPTION_KEY=your-actual-encryption-key
GITHUB_TOKEN=ghp_your_github_token
```

2. **Add `.secrets` to `.gitignore`**:

```bash
echo ".secrets" >> .gitignore
```

### Run the Workflow

```bash
# List available jobs
act -l

# Run the build job only (recommended for testing)
act -j build --secret-file .secrets

# Run with verbose output
act -j build --secret-file .secrets -v

# Run specific event (push is default)
act push --secret-file .secrets

# Dry run (show what would be executed)
act -n
```

### Using Different Runner Images

Act uses Docker images to simulate GitHub runners. Choose based on your needs:

```bash
# Micro (fast, minimal) - good for simple workflows
act -P ubuntu-22.04=catthehacker/ubuntu:act-22.04

# Medium (balanced) - recommended
act -P ubuntu-22.04=catthehacker/ubuntu:full-22.04

# Large (slow, complete) - most compatible
act -P ubuntu-22.04=catthehacker/ubuntu:runner-22.04
```

Save your preference in `.actrc`:

```bash
# .actrc
-P ubuntu-22.04=catthehacker/ubuntu:full-22.04
--secret-file .secrets
```

### Testing Tips

1. **Test only the build job first** (skip release):
   ```bash
   act -j build --secret-file .secrets
   ```

2. **Skip steps locally** using the `ACT` environment variable:
   ```yaml
   - name: Upload to Release
     if: ${{ !env.ACT }}
     run: gh release upload ...
   ```

3. **Check artifacts**:
   ```bash
   # Artifacts are saved to /tmp/artifacts by default
   act -j build --secret-file .secrets --artifact-server-path /tmp/artifacts
   ```

4. **Debug failed steps**:
   ```bash
   act -j build --secret-file .secrets -v --rm=false
   # Then inspect the container: docker ps -a
   ```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Cannot connect to Docker" | Start Docker daemon |
| "Secret not found" | Create `.secrets` file with required secrets |
| "Image pull failed" | Check internet connection or use `-P` flag |
| "Permission denied" | Run with `sudo` or add user to docker group |
| Job takes too long | Use smaller runner image (`micro`) |

### Example Test Session

```bash
# 1. Navigate to project
cd ShshShh

# 2. Create secrets file
cat > .secrets << EOF
ENCRYPTION_KEY=MyTestKey12345678
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
EOF

# 3. Run build job
act -j build --secret-file .secrets -v

# 4. Check if blobs were created
ls -la blobs/
```

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

MIT © [Hack N Roll](https://github.com/hacknroll)

---

<p align="center">
  <i>Keep your blobs safe. Keep them secret. Keep them ShshShh.</i> 🤫
</p>

<p align="center">
  <sub>A <a href="https://github.com/hacknroll">Hack N Roll</a> project</sub>
</p>