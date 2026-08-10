#!/bin/bash

set -e

# ============================================================
# Configuração do /etc/hosts - Homelab Kubernetes
# ============================================================

HOSTS_FILE="/etc/hosts"

echo "=========================================="
echo " Configuração de Hosts - Homelab"
echo "=========================================="
echo

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo "Erro: execute este script como root."
    echo "Exemplo:"
    echo "  sudo ./configure-hosts.sh"
    exit 1
fi

# Backup
BACKUP="${HOSTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"

cp "$HOSTS_FILE" "$BACKUP"

echo "Backup criado:"
echo "$BACKUP"
echo

# Remover entradas antigas do Homelab
sed -i '/# Kubernetes Homelab/,$d' "$HOSTS_FILE"

# Adicionar configuração do Homelab
cat >> "$HOSTS_FILE" <<EOF

# Kubernetes Homelab
10.10.1.241 k8s-master-01
10.10.1.242 k8s-worker-01
10.10.1.243 k8s-worker-02
10.10.1.240 nfs-server
EOF

echo "Configuração aplicada:"
echo

cat "$HOSTS_FILE"

echo
echo "=========================================="
echo " Testando resolução de nomes"
echo "=========================================="
echo

for host in \
    k8s-master-01 \
    k8s-worker-01 \
    k8s-worker-02 \
    nfs-server
do
    echo -n "$host -> "

    getent hosts "$host" | awk '{print $1}'
done

echo
echo "=========================================="
echo " Configuração concluída"
echo "=========================================="