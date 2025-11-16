#!/usr/bin/env bash
set -euo pipefail

DEV_MACHINE_DEFAULT="Puppy"
RDP_USER="steph.cooper_adm"
RDP_PASS="FivethChipOnItsWay2025!"
HOSTNAME="dc.puppy.htb"

echo "===== HTB Dev Box Helper ====="

# 1) Token
if [[ -z "${HTB_API_TOKEN:-}" ]]; then
    echo "Enter your HTB Token:"
    IFS= read -r TOKEN_INPUT
    export HTB_API_TOKEN="$TOKEN_INPUT"
else
    echo "[*] Using existing HTB_API_TOKEN from environment."
fi

echo "[DEBUG] HTB_API_TOKEN length: ${#HTB_API_TOKEN}"

# 2) Ensure htbcli.py exists (patched version)
if [[ ! -f htbcli.py ]]; then
    echo "[*] Downloading htbcli.py..."
    wget -q -O htbcli.py "https://raw.githubusercontent.com/thekeen01/htbcli/refs/heads/main/htbcli.py"
    echo "[!] Re-apply your get_machine_id_by_profile() patch now."
fi

# 3) Optional stop
read -r -p "Enter Machine to stop (default: None): " MACHINE_STOP
if [[ -n "${MACHINE_STOP:-}" && "${MACHINE_STOP,,}" != "none" ]]; then
    echo "[*] Stopping machine: ${MACHINE_STOP}"
    if ! python3 htbcli.py stop --machine "${MACHINE_STOP}"; then
        echo "[!] Failed to stop machine '${MACHINE_STOP}'."
    fi
else
    echo "[*] No machine stop requested."
fi

# 4) Machine to start (default Puppy) — AUTO-CONFIRM YES
read -r -p "Enter Machine to start (default: ${DEV_MACHINE_DEFAULT}): " MACHINE_START
MACHINE_START=${MACHINE_START:-$DEV_MACHINE_DEFAULT}

echo "[*] Starting dev box: ${MACHINE_START} (auto-confirm = y)"
START_OUTPUT=$(printf 'y\n' | python3 htbcli.py start --machine "${MACHINE_START}" 2>&1 || true)

echo "----- htbcli start output -----"
echo "$START_OUTPUT"
echo "-------------------------------"

if echo "$START_OUTPUT" | grep -qi "not found"; then
    echo "[!] Machine '${MACHINE_START}' not found."
    exit 1
fi

if echo "$START_OUTPUT" | grep -qi "Operation cancelled"; then
    echo "[!] Start was cancelled unexpectedly inside htbcli."
    exit 1
fi

# 5) Extract IP
IP_ADDR=$(printf '%s\n' "$START_OUTPUT" | awk '/Final machine IP:/ {print $NF}')

if [[ -z "${IP_ADDR:-}" ]]; then
    IP_ADDR=$(printf '%s\n' "$START_OUTPUT" \
        | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        | tail -n1 || true)
fi

if [[ -z "${IP_ADDR:-}" ]]; then
    echo "[!] ERROR: Could not parse machine IP from output."
    exit 1
fi

echo "[*] Detected machine IP: ${IP_ADDR}"

###############################################################################
# 6 & 7) ONLY RUN THESE WHEN MACHINE IS **Puppy**
###############################################################################

if [[ "${MACHINE_START,,}" == "puppy" ]]; then
    echo "[*] Puppy detected — applying Puppy-specific post-steps."

    # /etc/hosts
    echo "[*] Adding entry to /etc/hosts: ${IP_ADDR} ${HOSTNAME}"
    echo "${IP_ADDR} ${HOSTNAME}" | sudo tee -a /etc/hosts

    # Enable RDP
    echo "[*] Enabling RDP via netexec..."
    netexec smb "${HOSTNAME}" -u "${RDP_USER}" -p "${RDP_PASS}" -M rdp -o ACTION=enable >/dev/null 2>&1 || true
    netexec smb "${HOSTNAME}" -u "${RDP_USER}" -p "${RDP_PASS}" -M rdp -o ACTION=enable

    # Launch RDP client
    echo "[*] Launching xfreerdp..."
    xfreerdp /u:"${RDP_USER}" /p:"${RDP_PASS}" \
        /dynamic-resolution /cert-ignore /drive:.,linux /v:"${IP_ADDR}"
else
    echo "[*] '${MACHINE_START}' is not Puppy — skipping hosts update, netexec, and RDP."
fi

###############################################################################
