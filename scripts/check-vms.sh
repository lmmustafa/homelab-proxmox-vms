#!/bin/bash

# ============================================================
# Verificação das VMs - Homelab Proxmox
# ============================================================

VMS=(
    191
    201
    202
    210
)

echo
echo "=================================================================="
echo "                 HOMELAB PROXMOX - VMs"
echo "=================================================================="
printf "%-8s %-22s %-12s %-18s\n" \
    "VMID" "HOSTNAME" "STATUS" "IP"
echo "------------------------------------------------------------------"

for VMID in "${VMS[@]}"; do

    # Verificar se a VM existe
    if ! qm status "$VMID" >/dev/null 2>&1; then
        printf "%-8s %-22s %-12s %-18s\n" \
            "$VMID" "N/A" "NOT FOUND" "-"
        continue
    fi

    # Status
    STATUS=$(qm status "$VMID" | awk '{print $2}')

    # Nome
    NAME=$(qm config "$VMID" | awk '/^name:/ {print $2}')

    # IP
    IP=$(qm guest cmd "$VMID" network-get-interfaces 2>/dev/null \
        | grep -o '"ip-address" : "[0-9.]*"' \
        | grep -o '[0-9.]*' \
        | grep '^10\.10\.1\.' \
        | head -n 1)

    # Caso não encontre IP
    if [ -z "$IP" ]; then
        IP="-"
    fi

    printf "%-8s %-22s %-12s %-18s\n" \
        "$VMID" "$NAME" "$STATUS" "$IP"

done

echo "=================================================================="
echo