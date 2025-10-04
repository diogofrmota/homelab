# My Kubernetes cluster managed with ArgoCD

## Hardware (3 nodes)
- 3× Raspberry Pi 4B (2GB RAM)
- Each raspberry has 1 64GB SD card
- OS is Ubuntu Server 22.04 LTS

## Features
- Kubernetes cluster deployed with k3s
- GitOps deployment with `ArgoCD` and `Helm`
- `argocd-apps` contains ArgoCD applications deploying Helm charts in `k8s-apps`
- Fully automated HTTPS exposition on internal network using `cert-manager`, `metallb` and `ingress-nginx`
- Using `tailscale` for remote access (VPN)
- Monitoring with `kube-prometheus-stack`

## Dual Ingress Approach:

Internal Access (via nginx + MetalLB):
https://argocd.diogomota.pt (internal network)

https://grafana.diogomota.pt (internal network)

Remote Access (via Tailscale):
https://argocd.tailnet.ts.net (Tailscale VPN)

https://grafana.tailnet.ts.net (Tailscale VPN)

## Repository Structure

```
homelab/
├── argocd-apps/                 # ArgoCD Application configurations
│   ├── app-of-apps.yaml         # Main App-of-Apps definition
│   ├── applicationset.yaml      # ApplicationSet configuration
│   └── k8s-apps/                # Kubernetes applications
│       ├── argocd/              # ArgoCD configuration
│       ├── cert-manager/        # TLS certificate management
│       ├── tailscale/           # Tailscale VPN
│       ├── ingress-nginx/       # Ingress controller
│       ├── kube-prometheus-stack/ # Monitoring stack
│       └── metallb/             # Load balancer
├── .gitignore                  # Git ignore rules
├── LICENSE                     # Project license
└── README.md                   # Project documentation