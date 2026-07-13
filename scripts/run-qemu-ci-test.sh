#!/bin/bash
# ==============================================================================
# Anodyne OS - Headless QEMU Integration & Smoke Verification
# ==============================================================================
# Launches the bootable ISO in a headless virtual machine and monitors serial
# outputs for successful OS boot and core shell startup signals.
# ==============================================================================

set -euo pipefail

ISO_PATH="${1:-./factory/binary.hybrid.iso}"
LOG_FILE="qemu-serial.log"
TIMEOUT=120

echo "===================================================="
echo "    ANODYNE OS - HEADLESS BOOT VERIFICATION FLOW   "
echo "===================================================="
echo "[*] Checking target ISO path: $ISO_PATH"

if [ ! -f "$ISO_PATH" ]; then
    echo "❌ ERROR: ISO image file not found at $ISO_PATH"
    exit 1
fi

# Clean old log files
rm -f "$LOG_FILE"
touch "$LOG_FILE"

# Detect nested KVM virtualization capability
KVM_FLAG=""
if [ -c /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    echo "[+] Hardware acceleration (KVM) detected. Enabling speedups."
    KVM_FLAG="-enable-kvm"
else
    echo "[*] KVM not available. Falling back to software emulation (TCG)."
fi

echo "[*] Launching emulator in background..."
# Boot the CD-ROM ISO with redirected serial output to our log file, without graphical display windows
qemu-system-x86_64 \
    $KVM_FLAG \
    -m 2048 \
    -cdrom "$ISO_PATH" \
    -display none \
    -serial file:"$LOG_FILE" &

QEMU_PID=$!

# Ensure QEMU process gets terminated upon unexpected shell exit
trap 'kill -9 $QEMU_PID 2>/dev/null || true' EXIT

echo "[*] Emulation active. PID: $QEMU_PID. Monitoring boot console log..."

START_TIME=$(date +%s)
SUCCESS=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ "$ELAPSED" -gt "$TIMEOUT" ]; then
        break
    fi

    # Check for core signals in the serial console logs
    if grep -q "ShellBridge: Initialized" "$LOG_FILE" 2>/dev/null || \
       grep -q "mounted web asset successfully" "$LOG_FILE" 2>/dev/null; then
        echo ""
        echo "===================================================="
        echo "🎉 SUCCESS: Anodyne OS core shell initialized successfully!"
        echo "===================================================="
        SUCCESS=1
        break
    fi

    # Print dot to indicate progress
    echo -n "."
    sleep 2
done

if [ "$SUCCESS" -eq 1 ]; then
    echo "[*] Core shell is functional. Terminating QEMU process cleanly."
    kill $QEMU_PID || kill -9 $QEMU_PID
    exit 0
else
    echo ""
    echo "===================================================="
    echo "❌ ERROR: Boot verification timed out after $TIMEOUT seconds!"
    echo "===================================================="
    echo "[+] DUMPING LATEST SERIAL CONSOLE OUTPUT LOGS:"
    echo "----------------------------------------------------"
    if [ -f "$LOG_FILE" ]; then
        tail -n 100 "$LOG_FILE"
    else
        echo "(Log file is missing)"
    fi
    echo "----------------------------------------------------"
    
    kill $QEMU_PID || kill -9 $QEMU_PID
    exit 1
fi
