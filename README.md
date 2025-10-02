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
- Authentication of sensitive apps with `oauth2-proxy` with GitLab as an OAuth2 provider
- Free endpoint security using `Crowdsec`
- Secrets management with `external-secrets` and GitLab CI/CD variables
- Using `tailscale` as a VPN for external access
- PostgreSQL database management with `CloudNativePG`
- Observability with `Prometheus`, `Grafana` and `Loki`
- Alerting with `Alertmanager` and a `Telegram Bot`
- Thorough HTTP / PostgreSQL status checks with `go-healthcheck`
- Any app I want to host! Currently: `changedetection`, `headscale`, `homepage`, `metallb` and `pihole`

## Repository Structure

```
homelab/
├── argocd-apps/                 # ArgoCD Application configurations
│   ├── app-of-apps.yaml         # Main App-of-Apps definition
│   ├── applicationset.yaml      # ApplicationSet configuration
│   └── k8s-apps/                # Kubernetes applications
│       ├── 0_template/          # Template for applications
│       │   ├── Chart.yaml
│       │   └── values.yaml
│       ├── argocd/              # ArgoCD configuration
│       ├── blackbox-exporter/   # Monitoring exporter
│       ├── cert-manager/        # TLS certificate management
│       ├── changedetection/     # Website change detection
│       ├── cloudnative-pg/      # CloudNative PostgreSQL operator
│       ├── crowdsec/            # Security tool
│       ├── external-dns/        # DNS management
│       ├── external-secrets/    # Secrets management
│       ├── go-healthcheck/      # Health checking
│       ├── headscale/           # Tailscale coordination server
│       ├── homepage/            # Dashboard homepage
│       ├── ingress-nginx/       # Ingress controller
│       ├── kube-prometheus-stack/ # Monitoring stack
│       ├── loki/                # Log aggregation
│       ├── metallb/             # Load balancer
│       ├── oauth2-proxy/        # Authentication proxy
│       ├── pihole/              # DNS sinkhole
│       └── tailscale-operator/  # VPN
├── scripts/                     # Automation scripts
│   ├── bootstrap.sh            # Initial setup script
│   ├── uninstall.sh            # Cleanup script
│   └── update-deployed-apps.sh # Application update script
├── .gitignore                  # Git ignore rules
├── LICENSE                     # Project license
└── README.md                   # Project documentation