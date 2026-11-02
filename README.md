# Kubernetes The Hard Way: Automated with Terraform & Ansible

This repository provides full end-to-end infrastructure provisioning and configuration management to bootstrap a production-grade Kubernetes cluster from scratch ("The Hard Way") using **Terraform** on AWS and **Ansible**.

---

## 📁 Repository Structure

```text
k8s-cluster-terraform-ansible/
├── ansible/
│   ├── ansible.cfg
│   ├── hosts.ini
│   ├── site.yml
│   └── roles/
│       ├── generate-certs/
│       │   └── tasks/main.yml
│       ├── generate-configs/
│       │   └── tasks/main.yml
│       ├── bootstrap-etcd/
│       │   ├── handlers/main.yml
│       │   └── tasks/main.yml
│       ├── setup-control-plane/
│       │   └── tasks/main.yml
│       ├── setup-worker-nodes/
│       │   ├── handlers/main.yml
│       │   └── tasks/main.yml
│       ├── configure-kubectl/
│       │   └── tasks/main.yml
│       ├── setup-networking/
│       │   └── tasks/main.yml
│       └── smoke-test/
│           └── tasks/main.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── README.md
```

---

## 🏗️ Architecture Overview

The cluster consists of:
* **Control Plane (`controller-0`)**:
  * Distributed State Store: `etcd` v3.5.9
  * Control Plane Daemons: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`
  * Data Encryption at Rest (`aescbc:v1:key1`) for etcd Secrets
* **Worker Nodes (`worker-0`, `worker-1`)**:
  * Container Runtime: `containerd` v1.7.6 with `runc` v1.1.9 (Systemd cgroup driver)
  * Node Agents: `kubelet` v1.28.2, `kube-proxy` v1.28.2
  * Networking: Calico CNI with VXLAN encapsulation and CoreDNS v1.10.1
* **Management Station (`localhost`)**:
  * Automated PKI certificate authority and key generation
  * Kubeconfig rendering and remote `kubectl` context configuration

---

## 🚀 Step-by-Step Deployment Guide

### Prerequisites
1. **Terraform** `>= 1.5.0`
2. **Ansible** `>= 2.14`
3. **AWS CLI** configured with appropriate credentials
4. **OpenSSL** and **kubectl** installed locally

### Step 1: Provision Infrastructure via Terraform
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
Terraform creates:
* Custom VPC (`10.240.0.0/16`) and Public Subnet (`10.240.0.0/24`).
* Security Groups opening ports `22` (SSH), `6443` (Kubernetes API), `2379-2380` (etcd), `10250` (kubelet), NodePorts `30000-32767`, and intra-VPC mesh traffic for CNI overlay.
* 1 EC2 instance for Controller and 2 EC2 instances for Workers with disabled `source_dest_check`.

Inspect the generated inventory:
```bash
terraform output -raw ansible_inventory > ../ansible/hosts.ini
cd ../ansible
```

### Step 2: Run Ansible Master Playbook
```bash
ansible-playbook -i hosts.ini site.yml
```

The playbook executes the following automated roles:
1. **`generate-certs`**: Provisions Certificate Authority (CA) and generates TLS certificates for API server, etcd, controller-manager, scheduler, kube-proxy, workers, and service accounts with complete Subject Alternative Names (SANs).
2. **`generate-configs`**: Renders isolated `kubeconfig` authentication files for all nodes and generates `encryption-config.yaml` with a cryptographic 32-byte key.
3. **`bootstrap-etcd`**: Installs `etcd` and `etcdctl`, sets up TLS peer/client communication, configures systemd, and checks cluster health.
4. **`setup-control-plane`**: Configures `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, enables admission plugins, encryption provider, and deploys Kubelet API access RBAC (`system:kube-apiserver-to-kubelet`).
5. **`setup-worker-nodes`**: Configures kernel parameters (`overlay`, `br_netfilter`, `ip_forward`), installs `containerd` with `SystemdCgroup = true`, installs `kubelet` and `kube-proxy`, and registers workers.
6. **`configure-kubectl`**: Sets up remote admin `kubectl` context to manage the cluster securely from the local machine.
7. **`setup-networking`**: Deploys Calico CNI overlay networking and CoreDNS for cluster internal name resolution (`10.32.0.10`).
8. **`smoke-test`**: Runs end-to-end cluster validation.

---

## 🧪 Verification & Smoke Tests

The `smoke-test` role automatically verifies:

### 1. Data Encryption at Rest in ETCD
Ensures etcd secrets are encrypted at rest using AES-CBC encryption:
```bash
ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem \
  /registry/secrets/default/smoke-test-secret
```
Output prefix verified: `k8s:enc:aescbc:v1:key1`.

### 2. Workload Scheduling & Pod Health
```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
```

### 3. Bidirectional API Server to Kubelet Exec & Logs
Verifies RBAC and mutual TLS tunnel between apiserver and kubelet:
```bash
kubectl exec deployment/nginx-smoke-test -- nginx -v
kubectl logs -l app=nginx-smoke-test
```

### 4. Cluster DNS Resolution
Verifies CoreDNS resolves internal cluster domains:
```bash
kubectl exec pod/dns-smoke-test -- nslookup kubernetes.default
# Returns: 10.32.0.1
```

---

## 🛠️ Challenges Faced & Solutions Implemented

### 1. AWS Source/Destination Check Dropping Pod Traffic
* **Challenge:** Pods scheduled on `worker-0` could not reach pods or services running on `worker-1`, even though nodes could ping each other.
* **Root Cause:** By default, AWS EC2 drops packets whose source or destination IP does not match the EC2 instance's private IP. Because Pod IPs belong to the cluster CIDR (`10.200.x.x`), AWS packet filters discarded overlay frames.
* **Solution:** Configured `source_dest_check = false` on all EC2 worker instances in `terraform/main.tf` and deployed Calico with VXLAN encapsulation to reliably tunnel pod traffic over AWS VPC.

### 2. TLS SAN Mismatch for Remote `kubectl` Access
* **Challenge:** Running `kubectl` from outside AWS threw `x509: certificate is valid for ..., not <controller-public-ip>`.
* **Root Cause:** Standard Kubernetes certificates only include the internal IP (`10.240.0.10`) and Kubernetes internal service IPs (`10.32.0.1`).
* **Solution:** Designed the `generate-certs` role to dynamically read the controller's public IP from the Ansible inventory and inject it into the `subjectAltName` extension of `kubernetes-openssl.cnf`.

### 3. Cgroup Driver Conflict Between Containerd and Kubelet
* **Challenge:** Kubelet periodically crashed on worker nodes with error: `failed to run Kubelet: misconfiguration: kubelet cgroup driver: "systemd" is different from runtime cgroup driver: "cgroupfs"`.
* **Root Cause:** In modern Linux kernels with systemd, running different cgroup managers causes conflicting resource limits and node instability.
* **Solution:** Standardized both `containerd` (`SystemdCgroup = true` in `/etc/containerd/config.toml`) and `kubelet` (`cgroupDriver: systemd` in `/var/lib/kubelet/kubelet-config.yaml`).

### 4. Kube-API Server to Kubelet API 401/403 Errors on `kubectl exec` / `logs`
* **Challenge:** When running `kubectl logs` or `kubectl exec`, the API server returned `Error from server (Forbidden): nodes "worker-0" is forbidden: User "kubernetes" cannot get resource "nodes/proxy"`.
* **Root Cause:** Kubernetes 1.28 requires explicit RBAC rules allowing the API server's client certificate to interact with Kubelet endpoints.
* **Solution:** Created ClusterRole `system:kube-apiserver-to-kubelet` and ClusterRoleBinding `system:kube-apiserver` in `setup-control-plane` role granting full proxy permissions to the `kubernetes` user.
