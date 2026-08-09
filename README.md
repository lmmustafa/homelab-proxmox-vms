# Homelab Proxmox VMs

Laboratório de infraestrutura construído utilizando **Proxmox VE**.

Este projeto tem como objetivo criar e documentar a infraestrutura virtual que será utilizada posteriormente pelo projeto **Homelab Kubernetes**.

O laboratório foi desenvolvido com foco em estudos práticos de:

* Linux
* Virtualização
* Proxmox VE
* Redes
* Armazenamento
* NFS
* Infraestrutura como código
* Kubernetes

A proposta é criar uma infraestrutura reproduzível, organizada e documentada, permitindo recriar o ambiente sempre que necessário.

---

## Arquitetura

O ambiente será composto por quatro máquinas virtuais:

* 1 servidor NFS
* 1 Kubernetes Control Plane
* 2 Kubernetes Worker Nodes

```text
                         Gateway
                       10.10.1.1
                           |
                           |
                    Proxmox VE
                    10.10.1.254
                           |
                        vmbr0
                    10.10.1.0/24
                           |
          +----------------+----------------+
          |                |                |
          |                |                |
      NFS Server       Kubernetes        Kubernetes
      10.10.1.240       Cluster           Cluster
          |                |                |
          |          +-----+-----+          |
          |          |           |          |
          |          |           |          |
          |       Master      Workers       |
          |       .241        .242           |
          |                   .243           |
          |                                  |
          +----------------------------------+
                    NFS Storage
```

---

## Máquinas Virtuais

| VMID | Hostname        | Endereço IP   | Função                   |    CPU |  RAM |  Disco |
| ---: | --------------- | ------------- | ------------------------ | -----: | ---: | -----: |
|  191 | `k8s-master-01` | `10.10.1.241` | Kubernetes Control Plane | 4 vCPU | 8 GB |  50 GB |
|  201 | `k8s-worker-01` | `10.10.1.242` | Kubernetes Worker        | 4 vCPU | 8 GB |  50 GB |
|  202 | `k8s-worker-02` | `10.10.1.243` | Kubernetes Worker        | 4 vCPU | 8 GB |  50 GB |
|  210 | `nfs-server`    | `10.10.1.240` | Servidor NFS             | 2 vCPU | 4 GB | 100 GB |

---

## Rede

| Componente           | Configuração   |
| -------------------- | -------------- |
| Rede                 | `10.10.1.0/24` |
| Gateway              | `10.10.1.1`    |
| Proxmox VE           | `10.10.1.254`  |
| Bridge               | `vmbr0`        |
| NFS Server           | `10.10.1.240`  |
| Kubernetes Master    | `10.10.1.241`  |
| Kubernetes Worker 01 | `10.10.1.242`  |
| Kubernetes Worker 02 | `10.10.1.243`  |

---

## Armazenamento

As máquinas virtuais serão armazenadas no storage ZFS do Proxmox:

```text
zfs-s001
```

Distribuição planejada:

```text
NFS Server       100 GB
K8s Master        50 GB
K8s Worker 01     50 GB
K8s Worker 02     50 GB
------------------------
Total             250 GB
```

O servidor NFS será utilizado posteriormente pelo cluster Kubernetes para fornecer armazenamento persistente através de **Persistent Volumes (PV)**.

---

## Configuração das VMs

As máquinas virtuais utilizarão:

* CPU: `host`
* Rede: VirtIO
* Disco: VirtIO SCSI
* Controladora: `virtio-scsi-single`
* QEMU Guest Agent: habilitado
* Memory Ballooning: desabilitado
* Discard: habilitado
* I/O Thread: habilitado

---

## Sistema Operacional

As máquinas virtuais utilizarão:

**Ubuntu Server**

Imagem utilizada:

```text
ubuntu-26.04-live-server-amd64.iso
```

---

## Estrutura do Projeto

```text
homelab-proxmox-vms/
│
├── README.md
│
├── docs/
│   ├── 01-arquitetura.md
│   ├── 02-rede.md
│   ├── 03-armazenamento.md
│   ├── 04-maquinas-virtuais.md
│   └── 05-servidor-nfs.md
│
├── scripts/
│   ├── create-vm.sh
│   ├── create-cluster-vms.sh
│   └── destroy-vms.sh
│
├── config/
│   └── lab.env.example
│
└── diagrams/
    └── architecture.md
```

---

## Escopo do Projeto

Este repositório é responsável exclusivamente pela **infraestrutura virtual** do laboratório.

### Incluído

* Configuração do Proxmox VE
* Criação das máquinas virtuais
* CPU e memória
* Discos virtuais
* Rede virtual
* Instalação do Ubuntu Server
* Configuração de hostname
* Configuração de endereçamento IP
* Configuração do servidor NFS
* Preparação da infraestrutura para o Kubernetes

### Não incluído

A instalação e configuração do Kubernetes serão realizadas em um projeto separado:

**Homelab Kubernetes**

O projeto Kubernetes será responsável por:

* containerd
* kubeadm
* kubelet
* kubectl
* Kubernetes
* CNI
* MetalLB
* Persistent Volumes
* Storage
* Ingress
* Aplicações

---

## Objetivo

O objetivo deste projeto é criar uma infraestrutura de laboratório que possa ser utilizada como base para estudos de:

```text
Proxmox
   │
   ├── Virtualização
   ├── Linux
   ├── Networking
   ├── Storage
   └── NFS
          │
          ▼
     Kubernetes
          │
          ├── CNI
          ├── MetalLB
          ├── Storage
          └── Ingress
```

---

## Status do Projeto

🚧 **Em desenvolvimento**

### Infraestrutura

* [x] Proxmox VE configurado
* [x] Rede `vmbr0`
* [x] Storage ZFS
* [ ] Criação das máquinas virtuais
* [ ] Instalação do Ubuntu Server
* [ ] Configuração dos hostnames
* [ ] Configuração dos endereços IP
* [ ] Configuração do servidor NFS
* [ ] Testes de conectividade
* [ ] Documentação da infraestrutura

### Próxima etapa

Após a conclusão deste projeto, a infraestrutura estará preparada para receber o segundo projeto:

**Homelab Kubernetes**

---

## Projetos relacionados

Este projeto faz parte de um laboratório maior dividido em duas etapas:

### 1. Homelab Proxmox VMs

Infraestrutura e máquinas virtuais.

```text
Proxmox
   │
   ├── NFS Server
   ├── Kubernetes Master
   ├── Kubernetes Worker 01
   └── Kubernetes Worker 02
```

### 2. Homelab Kubernetes

Instalação e configuração da plataforma Kubernetes.

```text
Kubernetes
   │
   ├── Control Plane
   ├── Worker Nodes
   ├── CNI
   ├── MetalLB
   ├── NFS Storage
   └── Ingress
```

---

## Licença

Este projeto foi desenvolvido para fins de estudo, laboratório e aprendizado prático de infraestrutura, virtualização e Kubernetes.
