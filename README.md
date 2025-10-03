# My Kubernetes cluster managed with ArgoCD

## Hardware (3 nodes)
- 3× Raspberry Pi 4B (2GB RAM)
- Each raspberry has 1 64GB SD card
- OS is Ubuntu Server 22.04 LTS

To access my apps, I expose them directly on the internet with port-forwarding on my router.

## Features
- Kubernetes cluster deployed with k3s
- GitOps deployment with `ArgoCD` and `Helm`
- `argocd-apps` contains ArgoCD applications deploying Helm charts in `k8s-apps`
- Fully automated HTTPS exposition using `cert-manager`, `external-dns` and `ingress-nginx`
- Using `tailscale` as a VPN for external access
- Observability with `kube-prometheus-stack`
- Any app I want to host! Currently: `metallb`

## Repository Structure

```
homelab/
├── argocd-apps/                 # ArgoCD Application configurations
│   ├── app-of-apps.yaml         # Main App-of-Apps definition
│   ├── applicationset.yaml      # ApplicationSet configuration
│   └── k8s-apps/                # Kubernetes applications
│       ├── argocd/              # ArgoCD configuration
│       ├── cert-manager/        # TLS certificate management
│       ├── external-dns/        # DNS management
│       ├── tailscale/           # Tailscale VPN
│       ├── ingress-nginx/       # Ingress controller
│       ├── kube-prometheus-stack/ # Monitoring stack
│       └── metallb/             # Load balancer
├── .gitignore                  # Git ignore rules
├── LICENSE                     # Project license
└── README.md                   # Project documentation