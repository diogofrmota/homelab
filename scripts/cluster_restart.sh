# Restart all ArgoCD deployments
kubectl -n argocd rollout restart deployment argocd-applicationset-controller
kubectl -n argocd rollout restart deployment argocd-dex-server
kubectl -n argocd rollout restart deployment argocd-notifications-controller
kubectl -n argocd rollout restart deployment argocd-redis
kubectl -n argocd rollout restart deployment argocd-repo-server
kubectl -n argocd rollout restart deployment argocd-server

# Restart the statefulset
kubectl -n argocd rollout restart statefulset argocd-application-controller

# Restart all Cert-manager deployments
kubectl -n cert-manager rollout restart deployment cert-manager cert-manager-cainjector cert-manager-webhook

# Restart all Homepage deployments
kubectl -n homepage rollout restart deployment homepage

# Restart all Ingress Nginx deployments
kubectl -n ingress-nginx rollout restart deployment ingress-nginx-controller

# Restart all Metallb deployments
kubectl -n metallb rollout restart deployment metallb-controller
kubectl -n metallb rollout restart daemonset metallb-speaker

# Restart all Kube-system deployments
kubectl -n kube-system rollout restart deployment coredns local-path-provisioner metrics-server