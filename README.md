# Kubernetes The Hard Way & Cluster Observability with Lens IDE

This branch (`task-2`) contains the deliverables for **Task 2: Install Lens and configure cluster metrics display**, including:
1. `metrics-server.yaml`: Submission manifest configured for the Hard Way cluster.
2. In-depth answers to the guiding questions:
   * **What Is Kubernetes Lens?**
   * **What Problems Does Lens IDE Solve?**
3. Step-by-step instructions for Lens IDE integration, Prometheus Helm deployment, and Lens Metrics configuration.

---

## 📄 Submitted Deliverable: `metrics-server.yaml`

The production-ready manifest `metrics-server.yaml` is located in the root directory.

### Key Configurations:
* **API Service Registration**: Exposes `v1beta1.metrics.k8s.io` to the Kubernetes aggregation layer.
* **Hard Way Hardening & Compatibility**:
  * `--kubelet-insecure-tls`: Required to establish scrape connections with worker node Kubelets utilizing self-signed CA certificates without TLS handshake failure.
  * `--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname`: Correctly prioritizes internal node IPs.
* **Least-Privilege Security**: Runs as non-root (`runAsUser: 1000`), drops `ALL` Linux capabilities, sets `readOnlyRootFilesystem: true`, and applies `seccompProfile: RuntimeDefault`.

Apply manifest:
```bash
kubectl apply -f metrics-server.yaml
```

Verify with:
```bash
kubectl top nodes
kubectl top pods -A
```

---

## 🧠 Guiding Questions & Answers

### 1. What Is Kubernetes Lens?
**Kubernetes Lens** is an open-source, multi-cluster Integrated Development Environment (IDE) built on Electron and React. It acts as an interactive desktop workstation for developers, DevOps engineers, and SREs to monitor, inspect, and manage Kubernetes resources.

Unlike traditional web-based dashboards (e.g. Kubernetes Dashboard), Lens:
* Runs **entirely client-side** on your laptop or workstation.
* Requires **zero cluster-side privileged dashboard deployments**; it accesses the cluster through your standard local `kubeconfig` (`~/.kube/config`).
* Respects the **Kubernetes RBAC** rules of your user identity without needing cluster-admin privileges.
* Features a real-time event engine using WebSockets and API server watch streams to dynamically update cluster state without manual browser refreshing.

### 2. What Problems Does Lens IDE Solve?

1. **Elimination of Destructive Multi-Cluster Context Mistakes:**
   * *Problem:* When managing multiple environments (dev, staging, production) via `kubectl`, engineers frequently execute destructive commands in the wrong environment because their shell context was silently set to `production`.
   * *Lens Solution:* Each cluster runs in an isolated workspace with clear color-coded indicators. Switching between clusters is explicit and visual.
2. **Reduction of CLI Overhead and Cognitive Fatigue:**
   * *Problem:* Debugging an outage via CLI requires remembering dozens of commands (`kubectl describe pod`, `kubectl get events -n prod`, `kubectl get endpoints`, filtering JSONPath).
   * *Lens Solution:* Instant 360-degree hierarchical view. Clicking an unhealthy Pod immediately displays container statuses, events, associated ConfigMaps, Secrets, Service linkages, and historical restart counts.
3. **Instant Terminal and Interactive Log Debugging:**
   * *Problem:* Tailing multiple pods or opening an interactive shell requires multiple terminal sessions and complicated pod name copy-pasting.
   * *Lens Solution:* Single-click pod shell (`exec`) and log streaming with real-time log pause, regex filtering, line wrapping, and log export.
4. **Visual Capacity Planning without Polling:**
   * *Problem:* `kubectl top` provides only a one-time static snapshot and cannot reveal metric spikes or memory leaks over time.
   * *Lens Solution:* Embedded visual time-series graphs for CPU, Memory, Disk I/O, and Network directly rendered onto Nodes, Pods, and Namespaces via Prometheus integration.
5. **Integrated Helm Chart Management:**
   * *Problem:* Managing Helm releases via CLI requires tracking repo URLs, writing custom values files, and remembering release names.
   * *Lens Solution:* Graphical Helm browser to discover charts, configure values via a Monaco editor, deploy, upgrade, and rollback with one click.

---

## 📊 Complete Setup Walkthrough

For the full step-by-step setup guide covering:
1. Setting Up Lens Desktop
2. Connecting to `k8s-hardway`
3. Integrating `prometheus-community` Helm repository
4. Deploying Prometheus (`kube-prometheus-stack`)
5. Configuring Lens Metrics to scrape Prometheus

👉 **Read the full documentation at: [docs/lens-and-metrics.md](docs/lens-and-metrics.md)**
