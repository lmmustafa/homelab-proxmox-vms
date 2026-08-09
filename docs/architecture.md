# Arquitetura do Homelab Proxmox

Este documento descreve a arquitetura física e virtual utilizada no projeto `homelab-proxmox-vms`.

O ambiente foi desenvolvido para estudos de infraestrutura, Linux, virtualização, redes, armazenamento e posteriormente Kubernetes.

---

## 1. Visão Geral

A infraestrutura é composta por:

* 1 servidor físico executando Proxmox VE
* 4 máquinas virtuais
* 1 servidor NFS
* 1 Kubernetes Control Plane
* 2 Kubernetes Worker Nodes
* Rede local `10.10.1.0/24`
* Storage ZFS para as máquinas virtuais

A arquitetura foi dimensionada considerando as limitações de hardware do servidor físico.

---

## 2. Arquitetura Física

```text
                         REDE LOCAL
                        10.10.1.0/24
                              |
                              |
                         Gateway
                        10.10.1.1
                              |
                              |
                    ┌───────────────────┐
                    │    Proxmox VE     │
                    │                   │
                    │    Host: s001     │
                    │  10.10.1.254      │
                    │                   │
                    │  Intel Xeon       │
                    │  4 Cores / 4      │
                    │  Threads          │
                    │  16 GB RAM        │
                    └─────────┬─────────┘
                              |
                            vmbr0
                              |
              ┌───────────────┼────────────────┐
              |               |                |
              ▼               ▼                ▼
       ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
       │ NFS Server  │ │ K8s Master  │ │ K8s Workers │
       │             │ │             │ │             │
       │ .240        │ │ .241        │ │ .242        │
       │ 2 vCPU      │ │ 4 vCPU      │ │ 4 vCPU      │
       │ 2 GB RAM    │ │ 4 GB RAM    │ │ 2 GB RAM    │
       │ 100 GB      │ │ 50 GB       │ │ 50 GB       │
       └─────────────┘ └─────────────┘ └──────┬──────┘
                                              │
                                              │
                                          Worker 02
                                            .243
```

---

## 3. Hardware do Host

O servidor físico utilizado pelo laboratório possui:

| Recurso  | Configuração                     |
| -------- | -------------------------------- |
| Hostname | `s001`                           |
| CPU      | Intel Xeon E3-1226 v3 @ 3.30 GHz |
| Socket   | 1                                |
| Cores    | 4                                |
| Threads  | 4                                |
| RAM      | 16 GB                            |
| Swap     | 8 GB                             |
| Disco 1  | Kingston SA400S37120G - 120 GB   |
| Disco 2  | Samsung SSD 860 EVO - 500 GB     |

### CPU

O processador possui:

```text
Socket:          1
Cores:           4
Threads/core:    1
Total CPUs:      4
```

O servidor não possui Hyper-Threading.

---

## 4. Proxmox VE

Versão do ambiente:

| Componente  | Versão      |
| ----------- | ----------- |
| Proxmox VE  | 9.1.0       |
| PVE Manager | 9.1.14      |
| Kernel      | 7.0.2-4-pve |
| QEMU/KVM    | 11.0.0-2    |
| LXC         | 7.0.0-1     |
| ZFS         | 2.4.2-pve1  |
| Ceph        | 19.2.3-pve2 |

Para verificar a versão:

```bash
pveversion -v
```

---

## 5. Rede

A infraestrutura utiliza uma rede IPv4 privada:

```text
10.10.1.0/24
```

### Endereçamento

| Dispositivo   | Endereço      | Função                   |
| ------------- | ------------- | ------------------------ |
| Gateway       | `10.10.1.1`   | Gateway da rede          |
| Proxmox       | `10.10.1.254` | Host de virtualização    |
| NFS Server    | `10.10.1.240` | Storage compartilhado    |
| K8s Master    | `10.10.1.241` | Kubernetes Control Plane |
| K8s Worker 01 | `10.10.1.242` | Kubernetes Worker        |
| K8s Worker 02 | `10.10.1.243` | Kubernetes Worker        |

### Máscara

```text
255.255.255.0
```

ou:

```text
/24
```

---

## 6. Bridge de Rede

O Proxmox utiliza a bridge:

```text
vmbr0
```

Configuração:

```text
auto vmbr0
iface vmbr0 inet static
        address 10.10.1.254/24
        gateway 10.10.1.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
```

A interface física utilizada é:

```text
nic0
```

Arquitetura:

```text
                  NIC Física
                     nic0
                       |
                       |
                    vmbr0
                       |
        ┌──────────────┼──────────────┐
        |              |              |
        ▼              ▼              ▼
      VM 191         VM 201         VM 202
      Master         Worker 01      Worker 02
        |
        |
      VM 210
      NFS
```

---

## 7. Storage

O laboratório utiliza principalmente o storage ZFS:

```text
zfs-s001
```

Estado atual aproximado:

```text
Total:        ~450 GB
Utilizado:    ~3.5 GB
Disponível:   ~446 GB
Utilização:   < 1%
```

O status dos storages pode ser verificado com:

```bash
pvesm status
```

### Storages disponíveis

| Storage     | Tipo      | Função                    |
| ----------- | --------- | ------------------------- |
| `local`     | Directory | ISO, templates e arquivos |
| `local-lvm` | LVM Thin  | Storage disponível        |
| `zfs-s001`  | ZFS Pool  | Discos das VMs            |

---

## 8. Máquinas Virtuais

As VMs foram criadas através de script utilizando `qm`.

### VM 191 — Kubernetes Master

```text
VMID:       191
Hostname:   k8s-master-01
Função:     Kubernetes Control Plane
CPU:        4 vCPU
RAM:        4 GB
Disco:      50 GB
IP:         10.10.1.241
```

### VM 201 — Kubernetes Worker 01

```text
VMID:       201
Hostname:   k8s-worker-01
Função:     Kubernetes Worker
CPU:        4 vCPU
RAM:        2 GB
Disco:      50 GB
IP:         10.10.1.242
```

### VM 202 — Kubernetes Worker 02

```text
VMID:       202
Hostname:   k8s-worker-02
Função:     Kubernetes Worker
CPU:        4 vCPU
RAM:        2 GB
Disco:      50 GB
IP:         10.10.1.243
```

### VM 210 — NFS Server

```text
VMID:       210
Hostname:   nfs-server
Função:     NFS Storage
CPU:        2 vCPU
RAM:        2 GB
Disco:      100 GB
IP:         10.10.1.240
```

---

## 9. Distribuição de Recursos

### CPU

O host possui:

```text
4 cores físicos
```

As VMs possuem:

```text
4 + 4 + 4 + 2 = 14 vCPU
```

Portanto:

```text
14 vCPU / 4 cores = 3,5:1
```

Existe um overcommit de CPU de aproximadamente **3,5:1**.

Esse comportamento é intencional para o laboratório e permite estudar o comportamento de workloads virtualizados sob recursos limitados.

### Memória

A distribuição de memória é:

| VM              |       RAM |
| --------------- | --------: |
| `k8s-master-01` |      4 GB |
| `k8s-worker-01` |      2 GB |
| `k8s-worker-02` |      2 GB |
| `nfs-server`    |      2 GB |
| **Total**       | **10 GB** |

Considerando aproximadamente 16 GB de RAM física, permanecem cerca de 6 GB para o Proxmox VE e seus serviços.

---

## 10. Distribuição de Storage

Os discos das VMs estão distribuídos da seguinte forma:

| VM              |      Disco |
| --------------- | ---------: |
| `k8s-master-01` |      50 GB |
| `k8s-worker-01` |      50 GB |
| `k8s-worker-02` |      50 GB |
| `nfs-server`    |     100 GB |
| **Total**       | **250 GB** |

Os discos são armazenados no pool:

```text
zfs-s001
```

---

## 11. Configuração das VMs

As máquinas virtuais utilizam:

```text
CPU:
host

Storage Controller:
virtio-scsi-single

Disco:
SCSI / VirtIO

Network:
VirtIO

Bridge:
vmbr0

QEMU Guest Agent:
enabled

Memory Ballooning:
disabled

Discard:
enabled

I/O Thread:
enabled

SSD emulação:
enabled

Boot:
scsi0 → ide2 → net0
```

A ISO utilizada para instalação é:

```text
ubuntu-26.04-live-server-amd64.iso
```

---

## 12. Sistema Operacional

Todas as máquinas virtuais utilizarão:

```text
Ubuntu Server
```

A configuração de rede é realizada utilizando Netplan.

Exemplo do `k8s-master-01`:

```text
Interface: ens18
IP:        10.10.1.241/24
Gateway:   10.10.1.1
```

Verificação:

```bash
ip -br addr
```

Resultado esperado:

```text
ens18    UP    10.10.1.241/24
```

---

## 13. NFS

A VM `nfs-server` será utilizada como servidor de armazenamento compartilhado para o cluster Kubernetes.

Configuração planejada:

```text
Hostname: nfs-server
IP:       10.10.1.240
CPU:      2 vCPU
RAM:      2 GB
Disco:    100 GB
```

O armazenamento será posteriormente utilizado pelo Kubernetes para Persistent Volumes.

Fluxo planejado:

```text
                 Kubernetes
                     |
                     |
                  PV / PVC
                     |
                     |
                   NFS
                     |
                     ▼
              10.10.1.240
```

---

## 14. Segurança e Isolamento

As interfaces das VMs utilizam firewall do Proxmox:

```text
firewall=1
```

A comunicação entre as máquinas ocorre através da rede:

```text
10.10.1.0/24
```

O ambiente é destinado a laboratório e estudos.

---

## 15. Monitoramento do Host

Comandos utilizados para verificar os recursos:

### CPU

```bash
lscpu
```

### Memória

```bash
free -h
```

### Discos físicos

```bash
lsblk -d -o NAME,SIZE,MODEL
```

### Storage Proxmox

```bash
pvesm status
```

### ZFS

```bash
zpool status
```

```bash
zpool list
```

```bash
zfs list
```

---

## 16. Script de Criação

A criação das VMs é automatizada através do script:

```text
scripts/create-vm.sh
```

Exemplo:

```bash
./scripts/create-vm.sh 191 k8s-master-01 4 4096 50
```

Parâmetros:

```text
VMID
Nome
vCPU
Memória em MB
Disco em GB
```

Exemplo para o NFS:

```bash
./scripts/create-vm.sh 210 nfs-server 2 2048 100
```

---

## 17. Fluxo de Implantação

O processo de implantação segue as seguintes etapas:

```text
1. Proxmox VE
       |
       ▼
2. Configuração de rede
       |
       ▼
3. Configuração do Storage
       |
       ▼
4. Criação das VMs
       |
       ▼
5. Instalação do Ubuntu Server
       |
       ▼
6. Configuração de IP estático
       |
       ▼
7. Configuração do NFS
       |
       ▼
8. Testes de conectividade
       |
       ▼
9. Infraestrutura pronta
       |
       ▼
10. Projeto Kubernetes
```

---

## 18. Projeto Kubernetes

A infraestrutura deste projeto será utilizada pelo projeto de Kubernetes desenvolvido separadamente.

Arquitetura planejada:

```text
homelab-proxmox-vms
        |
        | fornece infraestrutura
        ▼
┌───────────────────────────┐
│       Kubernetes          │
│                           │
│  Control Plane             │
│  Worker 01                 │
│  Worker 02                 │
│                           │
│  CNI                       │
│  MetalLB                   │
│  NFS                       │
└───────────────────────────┘
```

O projeto Kubernetes será responsável pela instalação e configuração do cluster.

---

## 19. Estado Atual

### Proxmox

* [x] Proxmox VE instalado
* [x] Rede `vmbr0` configurada
* [x] Gateway configurado
* [x] Storage ZFS configurado
* [x] Hardware documentado

### Máquinas Virtuais

* [x] `k8s-master-01` criada
* [x] `k8s-worker-01` criada
* [x] `k8s-worker-02` criada
* [x] `nfs-server` criada

### Sistema Operacional

* [x] Ubuntu instalado no `k8s-master-01`
* [x] IP `10.10.1.241` configurado
* [ ] Ubuntu instalado no `k8s-worker-01`
* [ ] Ubuntu instalado no `k8s-worker-02`
* [ ] Ubuntu instalado no `nfs-server`

### Storage

* [ ] Configuração do NFS
* [ ] Exportação NFS
* [ ] Teste de montagem NFS
* [ ] Integração com Kubernetes

---

## 20. Próximas Etapas

1. Finalizar configuração do `k8s-master-01`
2. Instalar e configurar o `k8s-worker-01`
3. Instalar e configurar o `k8s-worker-02`
4. Instalar e configurar o `nfs-server`
5. Configurar SSH entre os nós
6. Validar conectividade entre todas as VMs
7. Configurar o NFS
8. Criar testes de montagem NFS
9. Documentar a infraestrutura final
10. Iniciar o projeto `homelab-kubernetes`

---

## 21. Objetivo do Laboratório

O objetivo principal deste laboratório é construir uma infraestrutura prática e reproduzível para desenvolver conhecimentos em:

* Linux
* Proxmox VE
* Virtualização
* Redes
* Storage
* ZFS
* NFS
* Containers
* Kubernetes
* Networking
* MetalLB
* Persistent Volumes
* Infrastructure as Code
* Git
* GitHub
* DevOps
* Troubleshooting

O ambiente também será utilizado como laboratório prático para preparação para a certificação **CKA (Certified Kubernetes Administrator)**.
