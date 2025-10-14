# OS Installation - On each node
1. Burn OS
Use the official Raspberry Pi Imager tool to flash Ubuntu Server 64-bit 22.04 LTS onto your SD cards.

2. Find your IP address

```bash
hostname -I
```

2. Configure hostnames
k3s-master        # On master node - 192.168.1.29
k3s-worker-01     # On worker node 1 - 192.168.1.31
k3s-worker-02     # On worker node 2 - 192.168.1.32

# System configuration - On each node

1. Install essential utilities

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim jq openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

2. Enable cgroups on Raspberry Pi Nodes

```bash
# Append cgroup_memory=1 cgroup_enable=memory to the end of the line. 
sudo vim /boot/firmware/cmdline.txt
```

3. Disable Swap 

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo reboot
```

# K3s Installation

1. Setup - On master node

```bash
export SETUP_NODEIP=192.168.1.29  # Your node IP
export SETUP_CLUSTERTOKEN=S5Kwre2s2bZkaZb88B  # Strong token

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.33.3+k3s1" \
  INSTALL_K3S_EXEC="--node-ip $SETUP_NODEIP \
  --disable=servicelb,traefik \
  K3S_TOKEN=$SETUP_CLUSTERTOKEN \
  K3S_KUBECONFIG_MODE=644 sh -s -

# Get node token
sudo cat /var/lib/rancher/k3s/server/node-token
```

2. Setup - On EACH worker node

```bash
export MASTER_IP=192.168.1.29  # IP of your master node
export NODE_IP=(node_IP)    # IP of THIS worker node (192.168.1.31 and 192.168.1.32)
export K3S_TOKEN=your-node-token # From master's node-token file

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.33.3+k3s1" \
  K3S_URL="https://$MASTER_IP:6443" \
  K3S_TOKEN=$K3S_TOKEN \
  INSTALL_K3S_EXEC="--node-ip $NODE_IP" sh -

# On the MASTER node - Verify the new node joined
kubectl get nodes -o wide
```

# Secrets Setup

- `cloudflare-api-token` in `cert-manager` namespace (for DNS challenges)
- `argo-webhook-secret` in `argocd` namespace (for webhook authentication)

```bash
kubectl create ns cert-manager

# Create this secret
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: YOUR_CLOUDFLARE_API_TOKEN_HERE

kubectl create ns argocd

# Create this secret
apiVersion: v1
kind: Secret
metadata:
  name: argo-webhook-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
    app.kubernetes.io/part-of: argocd
type: Opaque
stringData:
  secret: YOUR_WEBHOOK_SECRET_VALUE_HERE

# Tokens was saved outside of this repository
```

# Helm Chart Setup

```bash
# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm version

cd ../../applications/cert-manager && helm dependency update
cd ../../applications/homepage && helm dependency update
cd ../../applications/ingress-nginx && helm dependency update
cd ../../applications/kube-prometheus-stack && helm dependency update
cd ../../applications/metallb && helm dependency update
cd ../../applications/argocd && helm dependency update
```

# GitOps Setup

```bash
# Argo CD Bootstrap
helm template argocd . -n argocd | kubectl apply -n argocd -f -
kubectl apply -f ../../gitops/app-of-apps.yaml -n argocd
kubectl apply -f ../../gitops/applicationset.yaml -n argocd

# Wait for Argo CD
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial password (change immediately!)
ARGO_PASS=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo "Initial Argo CD password: $ARGO_PASS"

# Generate a New Password:
Use a bcrypt hash generator tool (such as https://www.browserling.com/tools/bcrypt) to create a new bcrypt hash for the password.
Update the argocd-secret secret with the new bcrypt hash.
kubectl -n argocd patch secret argocd-secret -p '{"stringData": { "admin.password": "$2a$10$rgDBwhzr0ygDfH6scxkdddddx3cd612Cutw1Xu1X3a.kVrRq", "admin.passwordMtime": "'$(date +%FT%T%Z)'" }}'

# Fix argocd.example.com (Only if necessary)
https://www.youtube.com/watch?v=dq3QbPp-GTA
```

## Monitor deployment progress

Check application status:
```bash
kubectl get applications -n argocd -w
```

Wait for all applications to show "Synced" and "Healthy" status.

### Step 7: Configure DNS

1. **Configure /etc/hosts**:
     ```bash
     argocd.diogomota.pt       → 192.168.1.210
     apps.diogomota.pt         → 192.168.1.210
     ```

### Step 8: Access Your Applications

Once certificates are issued, access via domains:

**Local Network Access (HTTPS with self-signed certificates):**
- ArgoCD: https://argocd.diogomota.pt


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