# Homelab Proxmox VMs

Laboratório de infraestrutura virtual desenvolvido com **Proxmox VE**, **Ubuntu Server** e **NFS**.

Este projeto tem como objetivo criar uma infraestrutura virtual reproduzível para estudos práticos de **Linux, virtualização, redes, armazenamento, infraestrutura e Kubernetes**.

A infraestrutura criada neste projeto será utilizada posteriormente pelo projeto de Kubernetes:

**Homelab Kubernetes**

---

## 📋 Objetivo

Construir uma infraestrutura de laboratório utilizando Proxmox VE, composta por:

* 1 servidor NFS
* 1 Kubernetes Control Plane
* 2 Kubernetes Worker Nodes

O projeto foi dimensionado para um servidor físico com recursos limitados, permitindo estudar Kubernetes em um ambiente real de laboratório.

---

## 🏗️ Arquitetura

```text
                         Internet / LAN
                              |
                         10.10.1.1
                           Gateway
                              |
                              |
                    ┌───────────────────┐
                    │    Proxmox VE     │
                    │    10.10.1.254    │
                    │                   │
                    │      vmbr0        │
                    └─────────┬─────────┘
                              |
             ┌────────────────┼────────────────┐
             |                |                |
             |                |                |
             ▼                ▼                ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │ NFS Server  │ │ K8s Master  │ │ K8s Workers │
      │             │ │             │ │             │
      │ .240        │ │ .241        │ │ .242        │
      │             │ │             │ │ .243        │
      │ 2 vCPU      │ │ 4 vCPU      │ │ 4 vCPU      │
      │ 2 GB RAM    │ │ 4 GB RAM    │ │ 2 GB RAM    │
      │ 100 GB      │ │ 50 GB       │ │ 50 GB       │
      └──────┬──────┘ └─────────────┘ └─────────────┘
             |
             |
        NFS Storage
             |
             ▼
      Kubernetes PV/PVC
```

---

## 🖥️ Hardware do Host

O laboratório está hospedado em um servidor físico com:

| Recurso     | Configuração                     |
| ----------- | -------------------------------- |
| Processador | Intel Xeon E3-1226 v3 @ 3.30 GHz |
| Sockets     | 1                                |
| Cores       | 4                                |
| Threads     | 4                                |
| Memória RAM | 16 GB                            |
| Swap        | 8 GB                             |
| Disco 1     | Kingston SA400S37120G - 120 GB   |
| Disco 2     | Samsung SSD 860 EVO - 500 GB     |

### CPU

O servidor possui **4 cores físicos e 4 threads**.

As máquinas virtuais utilizam um total de **14 vCPUs**, resultando em um overcommit de CPU de aproximadamente **3,5:1**.

Esse overcommit é intencional, pois o ambiente possui finalidade educacional e de laboratório.

---

## 🔧 Proxmox VE

Versões utilizadas:

| Componente  | Versão      |
| ----------- | ----------- |
| Proxmox VE  | 9.1.0       |
| PVE Manager | 9.1.14      |
| Kernel      | 7.0.2-4-pve |
| QEMU/KVM    | 11.0.0-2    |
| ZFS         | 2.4.2-pve1  |
| Ceph        | 19.2.3-pve2 |

Para verificar a versão do ambiente:

```bash
pveversion -v
```

---

## 🌐 Rede

A infraestrutura utiliza a rede local `10.10.1.0/24`.

| Componente           | Endereço       |
| -------------------- | -------------- |
| Rede                 | `10.10.1.0/24` |
| Gateway              | `10.10.1.1`    |
| Proxmox              | `10.10.1.254`  |
| Bridge               | `vmbr0`        |
| NFS Server           | `10.10.1.240`  |
| Kubernetes Master    | `10.10.1.241`  |
| Kubernetes Worker 01 | `10.10.1.242`  |
| Kubernetes Worker 02 | `10.10.1.243`  |

Configuração da bridge no Proxmox:

```text
nic0
  |
  ▼
vmbr0
  |
  ├── NFS Server
  ├── Kubernetes Master
  ├── Kubernetes Worker 01
  └── Kubernetes Worker 02
```

---

## 💻 Máquinas Virtuais

| VMID | Hostname        | Função                   |    CPU |  RAM |  Disco | IP            |
| ---: | --------------- | ------------------------ | -----: | ---: | -----: | ------------- |
|  191 | `k8s-master-01` | Kubernetes Control Plane | 4 vCPU | 4 GB |  50 GB | `10.10.1.241` |
|  201 | `k8s-worker-01` | Kubernetes Worker        | 4 vCPU | 2 GB |  50 GB | `10.10.1.242` |
|  202 | `k8s-worker-02` | Kubernetes Worker        | 4 vCPU | 2 GB |  50 GB | `10.10.1.243` |
|  210 | `nfs-server`    | NFS Server               | 2 vCPU | 2 GB | 100 GB | `10.10.1.240` |

### Recursos alocados

```text
CPU:
14 vCPU

Memória:
10 GB

Storage:
250 GB
```

O restante dos recursos físicos permanece disponível para o Proxmox VE e seus serviços.

---

## 💾 Storage

As máquinas virtuais são armazenadas no pool ZFS:

```text
zfs-s001
```

Distribuição:

| VM              |      Disco |
| --------------- | ---------: |
| `k8s-master-01` |      50 GB |
| `k8s-worker-01` |      50 GB |
| `k8s-worker-02` |      50 GB |
| `nfs-server`    |     100 GB |
| **Total**       | **250 GB** |

O servidor NFS será utilizado posteriormente como backend de armazenamento persistente para o Kubernetes.

---

## 📦 NFS

O servidor NFS será responsável por fornecer armazenamento compartilhado para o cluster Kubernetes.

Servidor:

```text
Hostname: nfs-server
IP:       10.10.1.240
Storage:  100 GB
```

Diretório planejado:

```text
/srv/nfs/k8s
```

A utilização do NFS permitirá trabalhar posteriormente com:

* PersistentVolume (PV)
* PersistentVolumeClaim (PVC)
* StorageClass
* ReadWriteMany (RWX)
* Provisionamento dinâmico

---

## ⚙️ Configuração das VMs

As máquinas virtuais utilizam:

* CPU `host`
* Controladora `virtio-scsi-single`
* Disco VirtIO SCSI
* Interface de rede VirtIO
* Bridge `vmbr0`
* QEMU Guest Agent habilitado
* Memory Ballooning desabilitado
* Discard habilitado
* I/O Thread habilitado
* Inicialização automática habilitada

---

## 🐧 Sistema Operacional

As máquinas virtuais utilizam:

```text
Ubuntu Server
```

ISO utilizada:

```text
ubuntu-26.04-live-server-amd64.iso
```

---

## 📁 Estrutura do Projeto

```text
homelab-proxmox-vms/
│
├── README.md
│
├── docs/
│   ├── architecture.md
│   └── network.md
│
├── scripts/
│   └── create-vm.sh
│
└── .gitignore
```

---

## 🚀 Criação das VMs

As máquinas virtuais são criadas utilizando o script:

```bash
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
Quantidade de vCPUs
Memória em MB
Disco em GB
```

Exemplo para o servidor NFS:

```bash
./scripts/create-vm.sh 210 nfs-server 2 2048 100
```

---

## 🔍 Verificação das VMs

Para listar as máquinas virtuais:

```bash
qm list
```

Para verificar a configuração de uma VM:

```bash
qm config 191
```

Para verificar o status:

```bash
qm status 191
```

---

## 📊 Monitoramento do Host

Comandos utilizados para verificar os recursos do Proxmox:

### CPU

```bash
lscpu
```

### Memória

```bash
free -h
```

### Discos

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

## 🗺️ Roadmap

### Infraestrutura

* [x] Instalação do Proxmox VE
* [x] Configuração da rede `vmbr0`
* [x] Configuração do storage ZFS
* [x] Criação das máquinas virtuais
* [x] Configuração de CPU e memória
* [x] Configuração dos discos
* [x] Configuração da rede virtual
* [x] Instalação do Ubuntu Server no `k8s-master-01`
* [x] Configuração do IP do `k8s-master-01`
* [ ] Instalação do Ubuntu no `k8s-worker-01`
* [ ] Instalação do Ubuntu no `k8s-worker-02`
* [ ] Instalação do Ubuntu no `nfs-server`
* [ ] Configuração do NFS
* [ ] Testes de conectividade entre as VMs
* [ ] Documentação completa

### Kubernetes

A instalação do Kubernetes será realizada em um projeto separado.

---

## 🔗 Projeto Kubernetes

Após a conclusão da infraestrutura, será utilizado o projeto:

```text
homelab-kubernetes
```

Esse projeto será responsável pela instalação e configuração do cluster Kubernetes.

Componentes planejados:

```text
Kubernetes
├── kubeadm
├── kubelet
├── kubectl
├── containerd
├── CNI
├── MetalLB
├── NFS Storage
├── Ingress Controller
└── Aplicações
```

---

## 🎯 Objetivos de Aprendizado

Este laboratório tem como objetivo desenvolver conhecimentos práticos em:

* Linux
* Proxmox VE
* Virtualização
* Redes
* TCP/IP
* Storage
* ZFS
* NFS
* Containers
* Kubernetes
* Networking no Kubernetes
* MetalLB
* Persistent Volumes
* Infrastructure as Code
* Git e GitHub
* DevOps

---

## 📌 Status

🚧 **Projeto em desenvolvimento**

A infraestrutura Proxmox e as máquinas virtuais já foram criadas. A próxima etapa é concluir a instalação e configuração dos sistemas operacionais e do servidor NFS.

---

## 📄 Licença

Este projeto foi desenvolvido para fins de estudo, laboratório e aprendizado prático de infraestrutura, virtualização, Linux e Kubernetes.

