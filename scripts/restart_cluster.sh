#!/bin/bash

# Simple Homelab Restart Script
set -e

echo "Starting homelab restart..."

# Restart all components
echo "Restarting kube-system (1/6)"
kubectl -n kube-system rollout restart deployment coredns local-path-provisioner metrics-server

sleep 20

echo "Restarting argocd (2/6)"
kubectl -n argocd rollout restart deployment argocd-applicationset-controller
kubectl -n argocd rollout restart deployment argocd-dex-server
kubectl -n argocd rollout restart deployment argocd-notifications-controller
kubectl -n argocd rollout restart deployment argocd-redis
kubectl -n argocd rollout restart deployment argocd-repo-server
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd rollout restart statefulset argocd-application-controller

sleep 20

echo "Restarting metallb (3/6)"
kubectl -n metallb rollout restart deployment metallb-controller
kubectl -n metallb rollout restart daemonset metallb-speaker

sleep 15

echo "Restarting ingress-nginx (4/6)"
kubectl -n ingress-nginx rollout restart deployment ingress-nginx-controller

sleep 10

echo "Restarting cert-manager (5/6)"
kubectl -n cert-manager rollout restart deployment cert-manager cert-manager-cainjector cert-manager-webhook

sleep 10

echo "Restarting homepager (6/6)"
kubectl -n homepage rollout restart deployment homepage

echo "Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all --all-namespaces

echo "Homelab restart completed!"