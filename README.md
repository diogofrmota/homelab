# Kubernetes cluster managed with ArgoCD

## Hardware (3 nodes)
- 3× Raspberry Pi 4B (2GB RAM)
- Each raspberry has 1 64GB SD card
- OS is Ubuntu Server 22.04 LTS

## Features (fix to the current apps)
- Kubernetes cluster deployed with k3s
- GitOps deployment with `ArgoCD` and `Helm`
- `gitops` contains ArgoCD applications deploying Helm charts in `applications`
- Domain-based access on local network with `ingress-nginx`
- TLS certificates (HTTPS) with `cert-manager` and Let's Encrypt
- Load balancing with `metallb` for bare metal
- Monitoring stack with `kube-prometheus-stack` (Prometheus + Grafana)
- Application dashboard with `homepage`

## Access

| Service | URL | Description |
|---------|-----|-------------|
| ArgoCD | https://argocd.diogomota.pt | GitOps continuous delivery tool |
| Grafana | https://grafana.diogomota.pt | Monitoring dashboards |
| Prometheus | https://prometheus.diogomota.pt | Metrics collection |
| Homepage | https://apps.diogomota.pt | Application dashboard |

## Repository Structure (update names)

```
homelab/
├── applications/ # Helm charts for applications
│   ├── argocd/ # GitOps controller
│   ├── cert-manager/ # TLS certificate management
│   ├── homepage/ # Application dashboard
│   ├── ingress-nginx/ # Nginx ingress controller
│   ├── kube-prometheus-stack/# Monitoring stack
│   └── metallb/ # Load balancer for bare metal
├── gitops/ # ArgoCD Application configurations
│   ├── app-of-apps.yaml # Main App-of-Apps definition
│   └── applicationset.yaml # ApplicationSet configuration
├── INSTALLATION.md # Setup instructions
└── README.md # Main project details
```

## Architecture

```
Local Network Devices
↓
Ingress-Nginx LoadBalancer (*.diogomota.pt → 192.168.1.210)
↓
Internal Cluster Services (ClusterIP)
↓
Applications (Pods)
```

## Quick Start

See [installation.md](installation.md) for detailed setup instructions.

## Key Details

* **Domains:** Custom domain `diogomota.pt` with subdomains for each service
* **TLS Certificates:** Let's Encrypt via `cert-manager` with DNS01 challenges
* **Ingress Controller:** All HTTP/HTTPS traffic routed through `ingress-nginx` at **192.168.1.210**
* **MetalLB IP Range:** `192.168.1.210–225` (16 IPs total)
* **Cluster Resources:** 3 nodes × 2 GB RAM = 6 GB total
* **GitOps Pattern:** ArgoCD manages all components, including itself
* **Monitoring:** Prometheus for metrics, Grafana for visualization

## Notes

- Services are only accessible on local network
- No port forwarding or public exposure required
- All services accessed via domain names through ingress controller
- Automatic TLS certificate provisioning via Let's Encrypt