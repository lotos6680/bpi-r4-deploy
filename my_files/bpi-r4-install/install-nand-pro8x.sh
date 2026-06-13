#!/bin/sh
# BPI-R4 Pro 8X - Install rescue system to NAND
# Run from SD card: sh /root/install-dir/install-nand.sh

set -e

GH_USER="woziwrt"
GH_REPO="bpi-r4-deploy"
GH_TAG="release-pro-8x-standard"
SNAND_NAME="bpi-r4-pro-snand-img.bin"

# Image search order: explicit argument, /tmp/, download from GitHub
if [ -n "${1:-}" ]; then
    NAND_IMG="$1"
elif [ -f "/tmp/${SNAND_NAME}" ]; then
    NAND_IMG="/tmp/${SNAND_NAME}"
else
    echo "Downloading ${SNAND_NAME} from GitHub..."
    wget -O "/tmp/${SNAND_NAME}" \
        "https://github.com/${GH_USER}/${GH_REPO}/releases/download/${GH_TAG}/${SNAND_NAME}"
    if [ $? -ne 0 ] || [ ! -s "/tmp/${SNAND_NAME}" ]; then
        echo "ERROR: Download failed. Connect ethernet and try again."
        rm -f "/tmp/${SNAND_NAME}"
        exit 1
    fi
    NAND_IMG="/tmp/${SNAND_NAME}"
fi

echo ""
echo "=================================================="
echo "  BPI-R4 Pro 8X - Install rescue system to NAND"
echo "=================================================="
echo ""

if ! grep -q "fitrw" /proc/mounts 2>/dev/null; then
    echo "ERROR: This script must be run from the SD card!"
    echo "       Make sure the DIP switch is set to SD boot."
    exit 1
fi

echo "OK: System is running from SD card."
echo ""

if [ ! -f "${NAND_IMG}" ]; then
    echo "ERROR: Image file not found: ${NAND_IMG}"
    echo "       Download snand-img.bin to /tmp/ or pass path as argument."
    exit 1
fi

echo "OK: Pro 8X image found ($(du -h ${NAND_IMG} | cut -f1))."
echo ""

if ! grep -q '"nand"' /proc/mtd 2>/dev/null; then
    echo "ERROR: NAND device not found in /proc/mtd!"
    exit 1
fi

echo "OK: NAND device found."
echo ""

echo "WARNING: The entire NAND flash will be overwritten!"
echo "         Press ENTER to continue or CTRL+C to cancel."
read _

echo ""
echo "Flashing Pro 8X image to NAND..."
mtd -e nand write "${NAND_IMG}" nand

echo ""
echo "=================================================="
echo "  DONE! Rescue system installed to NAND."
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Power off the device"
echo "  2. Switch DIP to NAND boot"
echo "  3. Power on — U-Boot initializes env automatically on first boot"
echo "  4. Login via SSH and run:"
echo "     sh /root/install-dir/install-nvme.sh"
echo ""
