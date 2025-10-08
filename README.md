# Kubernetes cluster managed with ArgoCD

## Hardware (3 nodes)
- 3× Raspberry Pi 4B (2GB RAM)
- Each raspberry has 1 64GB SD card
- OS is Ubuntu Server 22.04 LTS

## Features
- Kubernetes cluster deployed with k3s
- GitOps deployment with `ArgoCD` and `Helm`
- `argocd-apps` contains ArgoCD applications deploying Helm charts in `k8s-apps`
- Domain-based access on local network with `ingress-nginx`
- Self-signed HTTPS certificates with `cert-manager`
- Load balancing with `metallb` for bare metal
- Monitoring with `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager)
- Network-wide ad blocking with `pihole`

## Access

| Service | URL | IP / Notes |
|----------|-----|------------|
| ArgoCD | https://argocd.homelab.local | Via ingress (192.168.1.210) |
| Grafana | https://grafana.homelab.local | Via ingress (192.168.1.210) |
| Prometheus | https://prometheus.homelab.local | Via ingress (192.168.1.210) |
| Alertmanager | https://alertmanager.homelab.local | Via ingress (192.168.1.210) |
| Pi-hole Admin	| http://192.168.1.214/admin | **Direct LoadBalancer** |
| Pi-hole DNS | 192.168.1.213:53 | **DNS service only** |

> **DNS Configuration Required:**  
> Configure Pi-hole, `/etc/hosts`, or router to resolve `*.homelab.local` → `192.168.1.210`.

## Repository Structure

```
homelab/
├── argocd-apps/                 # ArgoCD Application configurations
│   ├── app-of-apps.yaml         # Main App-of-Apps definition
│   └── applicationset.yaml      # ApplicationSet with sync waves
└── k8s-apps/                    # Helm charts for applications
    ├── argocd/                  # ArgoCD (GitOps controller)
    ├── cert-manager/            # TLS certificate management
    ├── ingress-nginx/           # Nginx ingress controller
    ├── kube-prometheus-stack/   # Prometheus + Grafana + Alertmanager
    ├── metallb/                 # Load balancer for bare metal
    └── pihole/                  # Network-wide ad blocker
```

## Deployment Strategy

Applications deploy via ArgoCD in waves:
1. **MetalLB** – provides LoadBalancer IPs  
2. **Ingress-Nginx** – HTTP/HTTPS routing  
3. **Cert-Manager** – installs CRDs + self-signed issuer  
4. **ArgoCD** – GitOps controller (self-managed)  
5. **Kube-Prometheus-Stack** – monitoring stack  
6. **Pi-hole** – DNS ad-blocker (direct LB access)

## Architecture

```
Local Network Devices (DNS queries → 192.168.1.213:53)
↓
Pi-hole DNS Service (*.homelab.local → 192.168.1.210 via Local DNS Records)
↓
Ingress-Nginx LoadBalancer (192.168.1.210)
↓
Internal Cluster Services (ClusterIP)
```

- `MetalLB` IP range: `192.168.1.210–220`
- `Ingress-Nginx` static IP: `192.168.1.210`
- `Pi-hole` static IPs: `192.168.1.213` (UDP/DNS), `192.168.1.214` (TCP/Admin)
- All HTTPS certificates issued by `cert-manager` → `selfsigned` ClusterIssuer
- Local-only network scope (no external exposure)

## Quick Start

See [installation.md](installation.md) for detailed setup instructions.

## Key Details

* **Domains:** Local `.homelab.local` TLD with subdomains for each service (except Pi-hole)
* **TLS Certificates:** Self-signed via `cert-manager` (browser warnings expected)
* **Ingress Controller:** All HTTP/HTTPS traffic routed through `ingress-nginx` at **192.168.1.210**
* **MetalLB IP Range:** `192.168.1.210–220` (11 IPs total, 3 in use: `210` ingress, `213–214` Pi-hole)
* **Cluster Resources:** 3 nodes × 2 GB RAM = 6 GB total
* **GitOps Pattern:** ArgoCD manages all components, including itself
* **Network Scope:** Local-only, no public exposure or port forwarding
* **Pi-hole Access:** Web admin via direct LoadBalancer IP (`192.168.1.214`), DNS service via `192.168.1.213`

## Notes

- Browser will show certificate warnings (expected for self-signed certs)
- Services are only accessible on local network
- No port forwarding or public exposure required
- Pi-hole web admin accessed directly via LoadBalancer IP to avoid DNS circular dependencies
- All other services accessed via domain names through ingress controller

