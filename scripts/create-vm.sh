#!/bin/bash

set -e

VMID="$1"
NAME="$2"
CORES="$3"
MEMORY="$4"
DISK="$5"

STORAGE="zfs-s001"
BRIDGE="vmbr0"
ISO="local:iso/ubuntu-26.04-live-server-amd64.iso"

if [ -z "$VMID" ] || [ -z "$NAME" ] || [ -z "$CORES" ] || [ -z "$MEMORY" ] || [ -z "$DISK" ]; then
    echo "Uso:"
    echo "./create-vm.sh <VMID> <NOME> <CPU> <RAM_MB> <DISCO_GB>"
    exit 1
fi

if qm status "$VMID" &>/dev/null; then
    echo "ERRO: a VMID $VMID já existe."
    exit 1
fi

echo "========================================"
echo " Criando máquina virtual"
echo "========================================"
echo "VMID:      $VMID"
echo "Nome:      $NAME"
echo "CPU:       $CORES vCPU"
echo "RAM:       ${MEMORY} MB"
echo "Disco:     ${DISK} GB"
echo "Storage:   $STORAGE"
echo "Bridge:    $BRIDGE"
echo "ISO:       $ISO"
echo "========================================"

qm create "$VMID" \
    --name "$NAME" \
    --agent 1 \
    --balloon 0 \
    --cores "$CORES" \
    --sockets 1 \
    --cpu host \
    --memory "$MEMORY" \
    --numa 0 \
    --scsihw virtio-scsi-single \
    --scsi0 "$STORAGE:$DISK,discard=on,iothread=1,ssd=1" \
    --net0 "virtio,bridge=$BRIDGE,firewall=1" \
    --ide2 "$ISO,media=cdrom" \
    --boot "order=scsi0;ide2;net0" \
    --onboot 1

echo
echo "VM $VMID criada com sucesso."
echo

qm config "$VMID"