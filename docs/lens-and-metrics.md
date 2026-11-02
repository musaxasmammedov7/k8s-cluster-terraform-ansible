# Task 2: Lens IDE Setup, Prometheus Monitoring & Cluster Metrics

This guide covers the answers to the guiding questions, installation of Lens IDE, deployment of `metrics-server`, and Prometheus integration for real-time cluster metrics.

---

## 💡 Guiding Questions & Conceptual Foundation

### 1. What Is Kubernetes Lens?
**Kubernetes Lens** is an open-source, multi-cluster Kubernetes Integrated Development Environment (IDE) designed for developers, DevOps engineers, and SREs. It acts as a desktop command center for Kubernetes.

Key architectural characteristics:
* **Client-Side Architecture:** Lens runs locally on your workstation (macOS, Linux, Windows) using your local `kubeconfig` (`~/.kube/config`). It does **not** require installing heavyweight web dashboards or granting cluster-admin proxy privileges on the cluster control plane.
* **Native RBAC Passthrough:** Lens strictly respects the permissions of the authenticated user in your kubeconfig. If your credentials only allow viewing resources in a specific namespace, Lens only renders that namespace.
* **Real-Time Event Stream:** Connects directly to the Kubernetes API server via WebSockets and long-polling watch streams to instantly reflect state changes (pod crashes, evictions, rolling updates).

---

### 2. What Problems Does Lens IDE Solve?

| Traditional Kubernetes CLI Workflow | Lens IDE Solution |
| :--- | :--- |
| **Context Confusion:** Accidentally deleting resources in `prod` because the active `kubectl config current-context` was wrong. | **Isolated Cluster Workspaces:** Every cluster has an isolated tab and distinct visual identifier, eliminating dangerous context misconfigurations. |
| **CLI Cognitive Load:** Constantly stringing together `kubectl get`, `kubectl describe`, `grep`, and JSONPath queries to diagnose an issue. | **Hierarchical 360° Resource View:** Click from a failing Ingress straight to its Service, Endpoints, Pods, and Container Logs in seconds. |
| **Fragmented Log & Shell Access:** Running multiple terminal windows for `kubectl logs -f` and `kubectl exec -it`. | **Built-in Smart Terminal:** One-click instant pod terminal execution, live log tailing with regex search, log downloading, and pause/resume. |
| **Blind Resource Capacity Planning:** Running `kubectl top pod` provides only a momentary static snapshot without history. | **Embedded Visual Time-Series Metrics:** Live CPU, Memory, Disk, and Network graphs rendered directly onto Pods, Nodes, and Deployments via Prometheus. |
| **Complex Helm Operations:** Needing external Helm CLI scripts, tracking release revisions and value overrides manually. | **Integrated Helm Management:** Search, inspect, install, configure values, upgrade, and rollback Helm charts via a graphical interface. |

---

## 🛠️ Step-by-Step Implementation Guide

### Objective 1: Setting Up Lens IDE
1. Download and install Lens Desktop from [k8slens.dev](https://docs.k8slens.dev/) or via Homebrew on macOS:
   ```bash
   brew install --cask lens
   ```
2. Launch Lens. Lens detects existing kubeconfig files located in `~/.kube/config`.

---

### Objective 2: Connecting to the Hard Way Cluster
1. Ensure the `configure-kubectl` role from Task 1 has set your active cluster context:
   ```bash
   kubectl config use-context k8s-hardway
   kubectl get nodes
   ```
2. In Lens:
   * Click on the **Catalog** (top-left menu).
   * Click **Clusters** -> Click the **+ (Add Cluster)** button.
   * Lens will automatically discover `k8s-hardway` from your local `~/.kube/config`. Click to add it.
   * If adding manually, paste the content of `ansible/configs/admin.kubeconfig`.
3. You now have full visual access to Nodes, Namespaces, Pods, Services, and Storage.

---

### Objective 3: Installing Kubernetes Metrics Server
For Kubernetes to expose base resource usage (`kubectl top node`, `kubectl top pod`) and for Lens to display live node gauges, install `metrics-server`:

```bash
kubectl apply -f metrics-server.yaml
```

Verify that `metrics-server` is healthy:
```bash
kubectl -n kube-system get deployment metrics-server
kubectl top nodes
kubectl top pods -A
```

> **Note on Bare-Metal / Hard Way Clusters:** The provided `metrics-server.yaml` includes `--kubelet-insecure-tls` because the cluster uses self-signed CA certificates for kubelets.

---

### Objective 4: Integrating Helm Repositories in Lens
1. Open Lens and navigate to **Preferences** (Command + `,` on macOS or `File -> Preferences`).
2. Go to **Kubernetes** -> **Helm Charts**.
3. Under **Repositories**, click **Add Custom Repository**:
   * **Name:** `prometheus-community`
   * **URL:** `https://prometheus-community.github.io/helm-charts`
4. Click **Add**. Lens syncs the repository index.

---

### Objective 5: Deploying Prometheus Using Helm in Lens
1. Inside Lens, click your connected cluster (`k8s-hardway`).
2. In the left navigation menu, navigate to **Helm** -> **Charts**.
3. In the search bar, type `kube-prometheus-stack`.
4. Select the `kube-prometheus-stack` chart and click **Install**.
5. Configure deployment settings:
   * **Namespace:** `monitoring` (Check *Create namespace if not present*).
   * **Release Name:** `kube-prometheus-stack`
6. Click **Install**.
7. Wait 1–2 minutes for Prometheus Operator, Node Exporter, and Grafana to initialize. Verify in **Workloads** -> **Pods**:
   ```bash
   kubectl -n monitoring get pods
   ```

---

### Objective 6: Configuring Lens Metrics
1. Right-click on your cluster in the Lens top-left icon bar and select **Settings**.
2. Scroll to the **Metrics** section.
3. Under **Prometheus Service**, select:
   * **Prometheus Operator / Helm (`kube-prometheus-stack`)**
   * Lens auto-detects: `monitoring/kube-prometheus-stack-prometheus:9090`
4. If configuring standard standalone Prometheus:
   * Path: `monitoring/prometheus-server:80`
5. Save settings and return to the **Cluster Overview** page.
6. **Result:** Real-time graphs for Cluster CPU utilization, Memory pressure, Pod disk I/O, and Network ingress/egress are now rendered live inside Lens.
