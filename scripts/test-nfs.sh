#!/bin/bash

set -e

# ============================================================
# Teste NFS - Homelab Kubernetes
# ============================================================

NFS_SERVER="10.10.1.240"
NFS_HOSTNAME="nfs-server"
NFS_EXPORT="/srv/nfs/k8s"
MOUNT_POINT="/mnt/nfs-test"
TEST_FILE="nfs-test-$(hostname).txt"
TEST_CONTENT="NFS funcionando - $(hostname) - $(date)"

echo
echo "=========================================="
echo " Teste NFS - Homelab Kubernetes"
echo "=========================================="
echo

# ============================================================
# Verificar root
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "Erro: execute este script como root."
    echo
    echo "Exemplo:"
    echo "  sudo ./test-nfs.sh"
    exit 1
fi

# ============================================================
# Informações
# ============================================================

echo "Servidor NFS : $NFS_SERVER"
echo "Hostname     : $NFS_HOSTNAME"
echo "Export       : $NFS_EXPORT"
echo "Mount Point  : $MOUNT_POINT"
echo

# ============================================================
# 1. Testar conectividade
# ============================================================

echo "[1/7] Testando conectividade com o NFS..."

if ping -c 2 -W 2 "$NFS_SERVER" >/dev/null 2>&1; then
    echo "OK - servidor NFS acessível."
else
    echo "ERRO - não foi possível alcançar $NFS_SERVER."
    exit 1
fi

echo

# ============================================================
# 2. Testar resolução de hostname
# ============================================================

echo "[2/7] Testando resolução do hostname..."

RESOLVED_IP=$(getent hosts "$NFS_HOSTNAME" | awk '{print $1}' | head -n 1)

if [ "$RESOLVED_IP" = "$NFS_SERVER" ]; then
    echo "OK - $NFS_HOSTNAME -> $RESOLVED_IP"
else
    echo "AVISO - $NFS_HOSTNAME resolveu para: ${RESOLVED_IP:-não encontrado}"
    echo "Continuando utilizando o IP $NFS_SERVER."
fi

echo

# ============================================================
# 3. Verificar pacotes
# ============================================================

echo "[3/7] Verificando NFS client..."

if ! command -v mount.nfs >/dev/null 2>&1; then
    echo "NFS client não encontrado."
    echo "Instalando nfs-common..."

    apt update
    apt install -y nfs-common
fi

echo "OK - NFS client disponível."

echo

# ============================================================
# 4. Verificar export
# ============================================================

echo "[4/7] Verificando export NFS..."

EXPORTS=$(showmount -e "$NFS_SERVER" 2>/dev/null || true)

if echo "$EXPORTS" | grep -q "$NFS_EXPORT"; then
    echo "OK - export encontrado:"
    echo
    echo "$EXPORTS"
else
    echo "ERRO - export não encontrado:"
    echo "$NFS_EXPORT"
    echo
    echo "Exports disponíveis:"
    echo "$EXPORTS"
    exit 1
fi

echo

# ============================================================
# 5. Criar ponto de montagem
# ============================================================

echo "[5/7] Preparando ponto de montagem..."

mkdir -p "$MOUNT_POINT"

# Desmontar caso esteja montado
if mountpoint -q "$MOUNT_POINT"; then
    echo "Ponto já montado. Desmontando..."
    umount "$MOUNT_POINT"
fi

mount -t nfs "$NFS_SERVER:$NFS_EXPORT" "$MOUNT_POINT"

echo "OK - NFS montado."

echo

# ============================================================
# 6. Testar escrita e leitura
# ============================================================

echo "[6/7] Testando escrita e leitura..."

TEST_PATH="$MOUNT_POINT/$TEST_FILE"

echo "$TEST_CONTENT" > "$TEST_PATH"

if [ ! -f "$TEST_PATH" ]; then
    echo "ERRO - arquivo não foi criado."
    umount "$MOUNT_POINT"
    exit 1
fi

READ_CONTENT=$(cat "$TEST_PATH")

if [ "$READ_CONTENT" = "$TEST_CONTENT" ]; then
    echo "OK - escrita e leitura funcionando."
else
    echo "ERRO - conteúdo lido é diferente do conteúdo gravado."
    umount "$MOUNT_POINT"
    exit 1
fi

echo
echo "Arquivo criado:"
echo "$TEST_PATH"

echo
echo "Conteúdo:"
echo "$READ_CONTENT"

echo

# ============================================================
# 7. Desmontar
# ============================================================

echo "[7/7] Desmontando NFS..."

umount "$MOUNT_POINT"

if mountpoint -q "$MOUNT_POINT"; then
    echo "ERRO - não foi possível desmontar."
    exit 1
fi

echo "OK - NFS desmontado."

echo

# ============================================================
# Resultado
# ============================================================

echo "=========================================="
echo " TESTE NFS CONCLUÍDO COM SUCESSO"
echo "=========================================="
echo
echo "Servidor : $NFS_SERVER"
echo "Export   : $NFS_EXPORT"
echo "Cliente  : $(hostname)"
echo
echo "Conectividade : OK"
echo "Export        : OK"
echo "Montagem       : OK"
echo "Escrita        : OK"
echo "Leitura        : OK"
echo "Desmontagem    : OK"
echo