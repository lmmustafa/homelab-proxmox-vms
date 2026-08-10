#!/bin/bash

set -e

# ============================================================
# Configuração de rede - Homelab Kubernetes
# ============================================================

INTERFACE="ens18"
GATEWAY="10.10.1.1"
DNS="10.10.1.1"

if [ "$EUID" -ne 0 ]; then
    echo "Execute este script como root."
    echo "Exemplo: sudo ./configure-network.sh 10.10.1.241"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Uso:"
    echo "  sudo $0 <IP>"
    echo
    echo "Exemplo:"
    echo "  sudo $0 10.10.1.241"
    exit 1
fi

IP="$1"

# Validação simples do endereço

if ! [[ "$IP" =~ ^10\.10\.1\.[0-9]{1,3}$ ]]; then
    echo "Erro: IP inválido."
    echo "Utilize um endereço da rede 10.10.1.0/24."
    exit 1
fi

# Descobrir arquivo Netplan

NETPLAN_FILE=$(find /etc/netplan -maxdepth 1 -type f \
    \( -name "*.yaml" -o -name "*.yml" \) | head -n 1)

if [ -z "$NETPLAN_FILE" ]; then
    NETPLAN_FILE="/etc/netplan/99-homelab.yaml"
fi

echo "=========================================="
echo " Configuração de Rede - Homelab"
echo "=========================================="
echo
echo "Interface : $INTERFACE"
echo "IP        : $IP/24"
echo "Gateway   : $GATEWAY"
echo "DNS       : $DNS"
echo "Arquivo   : $NETPLAN_FILE"
echo

# Backup

if [ -f "$NETPLAN_FILE" ]; then
    cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
    echo "Backup criado:"
    echo "${NETPLAN_FILE}.bak"
fi

# Criar configuração

cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - $IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
          - $DNS
EOF

echo
echo "Configuração criada:"
echo
cat "$NETPLAN_FILE"

echo
echo "Validando configuração..."
netplan generate

echo
echo "Aplicando configuração..."
netplan apply

echo
echo "=========================================="
echo " Configuração concluída"
echo "=========================================="
echo

ip -br addr show "$INTERFACE"

echo
echo "Rotas:"
ip route