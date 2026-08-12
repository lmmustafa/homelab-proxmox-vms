#!/bin/bash

set -e

# ============================================================
# Instalação de pacotes básicos - Homelab Kubernetes
# ============================================================

echo "=========================================="
echo " Instalação de pacotes básicos"
echo "=========================================="
echo

echo "[1/3] Atualizando repositórios..."
apt update

echo
echo "[2/3] Atualizando pacotes..."
apt upgrade -y

echo
echo "[3/3] Instalando ferramentas..."

apt install -y \
    curl \
    wget \
    vim \
    nano \
    git \
    unzip \
    tar \
    htop \
    net-tools \
    iputils-ping \
    dnsutils \
    traceroute \
    telnet \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    chrony \
    qemu-guest-agent

echo
echo "=========================================="
echo " Habilitando QEMU Guest Agent"
echo "=========================================="

systemctl enable --now qemu-guest-agent

echo
echo "=========================================="
echo " Instalação concluída"
echo "=========================================="
echo

echo "Versões:"
echo

echo -n "Git: "
git --version

echo -n "Curl: "
curl --version | head -n 1

echo -n "Ping: "
ping -V 2>&1 | head -n 1

echo
echo "Serviço Chrony:"
systemctl is-active chrony || true

echo
echo "QEMU Guest Agent:"
systemctl is-active qemu-guest-agent || true

echo
echo "Sistema:"
hostnamectl