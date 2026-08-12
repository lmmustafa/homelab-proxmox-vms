#!/bin/bash

set -e

# ============================================================
# Configuração NFS - Homelab Kubernetes
# ============================================================

NFS_DIR="/srv/nfs/k8s"
NETWORK="10.10.1.0/24"
EXPORTS_FILE="/etc/exports"

echo
echo "=========================================="
echo " Configuração NFS - Homelab Kubernetes"
echo "=========================================="
echo

# ============================================================
# Verificar root
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "Erro: execute este script como root."
    echo
    echo "Exemplo:"
    echo "  sudo ./configure-nfs.sh"
    exit 1
fi

# ============================================================
# Instalação dos pacotes
# ============================================================

echo "[1/6] Instalando pacotes NFS..."

apt update

apt install -y \
    nfs-kernel-server \
    nfs-common

echo
echo "Pacotes instalados."
echo

# ============================================================
# Criar diretório
# ============================================================

echo "[2/6] Criando diretório NFS..."

mkdir -p "$NFS_DIR"

# Permissão inicial para laboratório
chmod 777 "$NFS_DIR"

echo "Diretório:"
echo "$NFS_DIR"

echo

# ============================================================
# Backup do /etc/exports
# ============================================================

if [ -f "$EXPORTS_FILE" ]; then

    BACKUP="${EXPORTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"

    cp "$EXPORTS_FILE" "$BACKUP"

    echo "[3/6] Backup criado:"
    echo "$BACKUP"

else

    echo "[3/6] Arquivo $EXPORTS_FILE não existe."

    touch "$EXPORTS_FILE"

fi

echo

# ============================================================
# Configuração do Export
# ============================================================

echo "[4/6] Configurando export NFS..."

EXPORT_LINE="$NFS_DIR $NETWORK(rw,sync,no_subtree_check,no_root_squash)"

# Remover configuração anterior do mesmo diretório
sed -i "\|^$NFS_DIR |d" "$EXPORTS_FILE"

# Adicionar nova configuração
echo "$EXPORT_LINE" >> "$EXPORTS_FILE"

echo
echo "Export configurado:"
echo
grep "$NFS_DIR" "$EXPORTS_FILE"

echo

# ============================================================
# Aplicar configuração
# ============================================================

echo "[5/6] Aplicando configuração..."

exportfs -rav

echo

# ============================================================
# Habilitar serviço
# ============================================================

echo "[6/6] Habilitando serviço NFS..."

systemctl enable --now nfs-server

echo

# ============================================================
# Validação
# ============================================================

echo "=========================================="
echo " Validação"
echo "=========================================="
echo

echo "Serviço NFS:"
systemctl is-active nfs-server

echo

echo "Exports:"
exportfs -v

echo

echo "Diretório:"
ls -ld "$NFS_DIR"

echo

echo "Porta NFS:"
ss -lntup | grep ':2049' || true

echo

echo "=========================================="
echo " NFS configurado com sucesso!"
echo "=========================================="
echo

echo "Servidor:"
hostname

echo
echo "Diretório:"
echo "$NFS_DIR"

echo
echo "Rede autorizada:"
echo "$NETWORK"

echo
```
