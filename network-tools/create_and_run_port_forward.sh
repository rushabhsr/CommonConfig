#!/bin/bash

# === CONFIGURATION ===
WIN_DIR="/mnt/c/wsl-port-forward"
SCRIPT_NAME="wsl_port_forward.ps1"
SCRIPT_PATH="${WIN_DIR}/${SCRIPT_NAME}"
PORT=${1:-8080}  # Default port is 8080 unless provided
WSL_IP=$(hostname -I | awk '{print $1}')

# === CHECK: Ensure WSL IP is available ===
if [ -z "$WSL_IP" ]; then
    echo "❌ Could not determine WSL IP address."
    exit 1
fi

# === STEP 1: Create directory if it doesn't exist ===
if [ ! -d "$WIN_DIR" ]; then
    echo "📁 Creating directory: $WIN_DIR"
    mkdir -p "$WIN_DIR"
fi

# === STEP 2: Create PowerShell script if it doesn't exist ===
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "📝 Creating PowerShell script: $SCRIPT_PATH"
    cat > "$SCRIPT_PATH" << 'EOF'
param (
    [Parameter(Mandatory=$true)][int]$Port,
    [Parameter(Mandatory=$true)][string]$WslIP
)

$listenAddress = "0.0.0.0"

# Detect Windows LAN IP
$winIP = Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" } `
    | Select-Object -ExpandProperty IPAddress -First 1

if (-not $winIP) {
    Write-Host "❌ Could not detect Windows LAN IP. Are you connected to a network?"
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Remove any existing portproxy rule
netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=$listenAddress | Out-Null

# Add forwarding rule
netsh interface portproxy add v4tov4 listenaddress=$listenAddress listenport=$Port connectaddress=$WslIP connectport=$Port

# === Add firewall rule to allow incoming traffic on this port ===
$ruleName = "WSL Port $Port"
# Delete existing rule if it exists
netsh advfirewall firewall delete rule name="$ruleName" protocol=TCP localport=$Port profile=Private 2>$null
# Add new rule
netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$Port profile=Private

Write-Host "✅ Port $Port is now forwarded and firewall rule added:"
Write-Host "    From: http://${winIP}:$Port"
Write-Host "    To:   http://${WslIP}:$Port (inside WSL)"
Write-Host ""
Write-Host "⚠️  Note: Run this script in an elevated (Admin) PowerShell prompt."

Read-Host -Prompt "Press Enter to exit"
EOF


    # Optional: Ensure Windows-compatible line endings
    unix2dos "$SCRIPT_PATH" 2>/dev/null || echo "Note: 'unix2dos' not found, but script should still work."
else
    echo "ℹ️ PowerShell script already exists. Skipping creation."
fi

# === STEP 3: Launch elevated PowerShell to run the port forwarding ===
POWERSHELL_CMD="Start-Process powershell -Verb runAs -ArgumentList '-ExecutionPolicy Bypass -File \"C:\\wsl-port-forward\\wsl_port_forward.ps1\" -Port $PORT -WslIP $WSL_IP'"

echo "🚀 Launching elevated PowerShell to forward port $PORT to $WSL_IP..."
powershell.exe -Command "$POWERSHELL_CMD"
