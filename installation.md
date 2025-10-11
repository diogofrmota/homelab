# Homelab Installation Guide - Local Network with Domain Names

## Installation Steps

### Step 1: Install k3s on all nodes

On the **first node** (master):
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644
```

Get the node token:
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

On the **other nodes** (workers):
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://[MASTER_NODE_IP]:6443 \
  K3S_TOKEN=[NODE_TOKEN_FROM_MASTER] sh -
```

### Step 2: Configure kubectl on your local machine

From the master node:
```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

Copy the content and save it locally as `~/.kube/config`, then replace `127.0.0.1` with your master node IP.

### Step 3: Update Helm dependencies

```bash
# Update dependencies for each chart
cd k8s-apps/argocd && helm dependency update && cd ../..
cd k8s-apps/cert-manager && helm dependency update && cd ../..
cd k8s-apps/ingress-nginx && helm dependency update && cd ../..
cd k8s-apps/metallb && helm dependency update && cd ../..
```

### Step 4: Install ArgoCD

```bash
kubectl create namespace argocd
cd k8s-apps/argocd && helm install argocd . -n argocd -f values.yaml
```

Wait for ArgoCD to be ready:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

Get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 5: Deploy the App of Apps

```bash
kubectl apply -f argocd-apps/app-of-apps.yaml -n argocd
```

### Step 6: Monitor deployment progress

Check application status:
```bash
kubectl get applications -n argocd -w
```

Wait for all applications to show "Synced" and "Healthy" status.

### Step 7: Configure DNS

1. **Configure /etc/hosts**:
     ```bash
     argocd.homelab.local       → 192.168.1.210
     ```

### Step 8: Access Your Applications

Once certificates are issued, access via domains:

**Local Network Access (HTTPS with self-signed certificates):**
- ArgoCD: https://argocd.homelab.local

**Note**: Your browser will warn about self-signed certificates. This is normal and safe for local use. Click "Advanced" → "Accept Risk and Continue" (or similar).

Login credentials:
- **ArgoCD**: username `admin`, password from Step 5

## Optional: Accept Self-Signed Certificates Permanently

To avoid browser warnings, you can add the self-signed certificates to your system's trust store:

### Linux
```bash
# Export certificate
kubectl get secret argocd-tls -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d > argocd.crt

# Add to system trust
sudo cp argocd.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### Windows
1. Export certificate as shown above
2. Double-click the .crt file
3. Click "Install Certificate"
4. Select "Local Machine"
5. Place in "Trusted Root Certification Authorities"

Repeat for each service's certificate if desired.