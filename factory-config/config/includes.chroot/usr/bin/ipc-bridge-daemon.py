#!/usr/bin/env python3
import os
import json
import time
import sys

# Shared runtime directories mapped between container and host
IPC_DIR = "/var/lib/anodyne/ipc"
OUTBOX = os.path.join(IPC_DIR, "outbox")  # Container writes here, host reads
INBOX = os.path.join(IPC_DIR, "inbox")    # Host writes here, container reads

# Simulated hardware nodes (mocking sysfs)
SYSFS_BACKLIGHT_MOCK = "/tmp/sys_class_backlight_brightness"
SYSFS_VOLUME_MOCK = "/tmp/alsa_mixer_volume"

def init_environment():
    # Make sure communication directories exist
    os.makedirs(OUTBOX, exist_ok=True)
    os.makedirs(INBOX, exist_ok=True)
    
    # Initialize mock sysfs hardware registers
    if not os.path.exists(SYSFS_BACKLIGHT_MOCK):
        with open(SYSFS_BACKLIGHT_MOCK, "w") as f:
            f.write("80")
            
    if not os.path.exists(SYSFS_VOLUME_MOCK):
        with open(SYSFS_VOLUME_MOCK, "w") as f:
            f.write("70")
            
    print(f"=== Anodyne OS IPC Bridge Daemon v1.0 ===")
    print(f"Watching outbox: {OUTBOX}")
    print(f"Response inbox: {INBOX}")
    print(f"Mock backlight sysfs register: {SYSFS_BACKLIGHT_MOCK}")
    print("==============================================")

def handle_request(req):
    req_id = req.get("id", "unknown")
    command = req.get("command", "")
    args = req.get("args", {})
    
    print(f"[*] Processing Request [{req_id}] -> Command: {command}")
    
    response = {
        "id": req_id,
        "status": "success",
        "message": ""
    }
    
    try:
        if command == "backlight":
            val = args.get("value", "80")
            # In a real environment, this writes to /sys/class/backlight/brightness
            with open(SYSFS_BACKLIGHT_MOCK, "w") as f:
                f.write(str(val))
            response["message"] = f"Wrote brightness value {val}% to sysfs successfully."
            
        elif command == "volume":
            val = args.get("value", "70")
            # In a real environment, this executes: amixer set Master val%
            with open(SYSFS_VOLUME_MOCK, "w") as f:
                f.write(str(val))
            response["message"] = f"Adjusted ALSA sound mixer to {val}%."
            
        elif command == "telephony_mode":
            mode = args.get("mode", "lte")
            # In a real environment, this issues dbus-send to oFono dummy-modem:
            # dbus-send --system --print-reply --dest=org.ofono /dummy_modem ...
            response["message"] = f"oFono D-Bus call succeeded. Swapped cellular profile to: {mode.upper()}."
            
        elif command == "power_action":
            action = args.get("action", "")
            if action in ["shutdown", "reboot"]:
                # In real execution, calls systemctl poweroff or systemctl reboot
                response["message"] = f"Host kernel executing native power signal: systemctl {action}."
            elif action == "powerwash":
                # Resets mutable user partition by wiping user directory cache
                response["message"] = "Host recovery console booted. Formatting LUKS TPM volume caches."
            else:
                response["status"] = "error"
                response["message"] = f"Unknown system action: {action}"
                
        else:
            response["status"] = "error"
            response["message"] = f"Command [{command}] not supported by host bridge daemon."
            
    except Exception as e:
        response["status"] = "error"
        response["message"] = f"Kernel write exception: {str(e)}"
        
    return response

def main():
    init_environment()
    
    try:
        while True:
            # Poll the shared outbox folder for incoming container requests
            files = [f for f in os.listdir(OUTBOX) if f.endswith(".json")]
            
            for file_name in files:
                file_path = os.path.join(OUTBOX, file_name)
                
                # Small delay to ensure writer finished writing
                time.sleep(0.05)
                
                try:
                    with open(file_path, "r") as f:
                        req = json.load(f)
                    
                    # Handle the command
                    resp = handle_request(req)
                    
                    # Write response to inbox
                    resp_file_name = f"resp_{resp['id']}.json"
                    resp_file_path = os.path.join(INBOX, resp_file_name)
                    
                    with open(resp_file_path, "w") as f:
                        json.dump(resp, f, indent=4)
                        
                    print(f"[+] Dispatched response to container: {resp_file_name}")
                    
                except Exception as ex:
                    print(f"[!] Error parsing request file {file_name}: {ex}")
                    
                finally:
                    # Clean up request file from outbox
                    try:
                        os.remove(file_path)
                    except OSError:
                        pass
                        
            time.sleep(0.5)  # Idle polling rate (reduces CPU usage)
            
    except KeyboardInterrupt:
        print("\nDaemon terminated by user.")
        sys.exit(0)

if __name__ == "__main__":
    main()
