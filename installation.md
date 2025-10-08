# Homelab Installation Guide - Local Network with Domain Names

## Prerequisites

### Prepare Your Secrets
Have these values ready before installation:
- Grafana Admin Password
- Pi-hole Web Password

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
cd k8s-apps/kube-prometheus-stack && helm dependency update && cd ../..
cd k8s-apps/metallb && helm dependency update && cd ../..
cd k8s-apps/pihole && helm dependency update && cd ../..
```

### Step 4: Create Kubernetes Secrets

**IMPORTANT**: Replace the placeholder values with your actual secrets before running these commands.

```bash
# Create required namespaces
kubectl create namespace argocd
kubectl create namespace kube-prometheus-stack
kubectl create namespace pihole

# 1. Grafana Admin Password Secret
kubectl create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="YOUR_GRAFANA_PASSWORD" \
  -n kube-prometheus-stack


# 2. Pihole Password Secret
kubectl create secret generic pihole-password \
  --from-literal=password="YOUR_PIHOLE_PASSWORD" \
  -n pihole
```

### Step 5: Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for ArgoCD to be ready:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

Get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 6: Deploy the App of Apps

```bash
kubectl apply -f argocd-apps/app-of-apps.yaml
```

### Step 7: Monitor deployment progress

Check application status:
```bash
kubectl get applications -n argocd -w
```

Wait for all applications to show "Synced" and "Healthy" status.

### Step 8: Configure Local DNS

1. **Access Pi-hole Admin**: `http://192.168.1.214/admin`
2. **Configure Local DNS**:
   - Go to **Local DNS** → **DNS Records**
   - Add A records pointing to `192.168.1.210`:
     ```
     argocd.homelab.local       → 192.168.1.210
     grafana.homelab.local      → 192.168.1.210
     prometheus.homelab.local   → 192.168.1.210
     alertmanager.homelab.local → 192.168.1.210
     ```
3. **Configure Devices**:
   - Set DNS server to: `192.168.1.213` (Pi-hole DNS)
4. **Access Services**:
   - Cluster apps: Use domain names (via ingress)
   - Pi-hole admin: Use `http://192.168.1.214/admin` directly

### Step 9: Verify Certificate Issuance

Self-signed certificates should issue immediately:

```bash
# Check certificate status
kubectl get certificate -A

# Should show Ready=True for all certificates
```

### Step 10: Access Your Applications

Once certificates are issued, access via domains:

**Local Network Access (HTTPS with self-signed certificates):**
- ArgoCD: https://argocd.homelab.local
- Grafana: https://grafana.homelab.local
- Prometheus: https://prometheus.homelab.local
- Alertmanager: https://alertmanager.homelab.local
- Pi-hole: http://192.168.1.213/admin

**Note**: Your browser will warn about self-signed certificates. This is normal and safe for local use. Click "Advanced" → "Accept Risk and Continue" (or similar).

**Alternative: Direct IP Access** (if DNS not configured):
- Ingress-Nginx: http://192.168.1.210

Login credentials:
- **ArgoCD**: username `admin`, password from Step 5
- **Grafana**: password from your secret (Step 4)
- **Pi-hole**: password from your secret (Step 4)

### Step 11: Verify all components

```bash
# Check all pods are running
kubectl get pods -A

# Check ingress resources
kubectl get ingress -A

# Check certificates (should all be Ready=True)
kubectl get certificate -A

# Verify Ingress-Nginx has external IP
kubectl get svc -n ingress-nginx
```

## Application Deployment Order

Your applications will deploy in this order through ArgoCD:

1. **MetalLB** (wave 0) - Load balancer (provides IP for Ingress-Nginx)
2. **Ingress-Nginx** (wave 1) - Ingress controller (receives all HTTP/HTTPS traffic)
3. **Cert-Manager** (wave 2) - Issues self-signed TLS certificates
4. **ArgoCD** (wave 3) - GitOps deployment manager (self-management)
5. **Kube-Prometheus-Stack** (wave 4) - Monitoring and observability
6. **Pi-hole** (wave 5) - Network-wide ad blocker

## Troubleshooting Commands

```bash
# Check application sync status
kubectl get applications -n argocd

# Check ingress status
kubectl get ingress -A

# Check certificate status
kubectl get certificate -A
kubectl describe certificate -A

# Check Ingress-Nginx logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Test DNS resolution (if using Pi-hole or custom DNS)
nslookup argocd.homelab.local
nslookup grafana.homelab.local

# Check MetalLB IP assignments
kubectl get svc -A | grep LoadBalancer
```

## Known Issues & Solutions

### Cannot Access Via Domain Name
**Symptoms**: Domain doesn't resolve or times out

**Solutions**:
1. Verify DNS is configured (Pi-hole, /etc/hosts, or router)
2. Test DNS resolution: `nslookup argocd.homelab.local`
3. Should resolve to `192.168.1.210`
4. If using Pi-hole DNS, ensure device is configured to use `192.168.1.213` as DNS server
5. Try direct IP access: `http://192.168.1.210`

### Browser Certificate Warnings
**Symptoms**: "Your connection is not private" or similar warnings

**This is normal for self-signed certificates.** Solutions:
1. Click "Advanced" → "Proceed" (Chrome/Edge)
2. Click "Advanced" → "Accept the Risk and Continue" (Firefox)
3. Or use direct IP access without HTTPS: `http://192.168.1.210`

### ArgoCD Self-Management Issues
- The initial manual installation bootstraps ArgoCD
- Wave 3 deploys the Helm chart which ArgoCD adopts and manages
- If conflicts occur, delete the Application and let it re-sync

### High Memory Usage
- With 6GB total cluster memory, monitor usage closely
- Consider reducing Prometheus retention if needed
- Check for memory leaks: `kubectl top pods -A --sort-by=memory`

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

