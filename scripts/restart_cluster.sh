#!/bin/bash

# Simple Homelab Restart Script
set -e

echo "Starting homelab restart..."

# Restart all components
echo "Restarting kube-system (1/6)"
restart kube-system \
    deployment/coredns \
    deployment/local-path-provisioner \
    deployment/metrics-server

sleep 20

echo "Restarting argocd (2/6)"
restart argocd \
    deployment/argocd-applicationset-controller \
    deployment/argocd-dex-server \
    deployment/argocd-notifications-controller \
    deployment/argocd-redis \
    deployment/argocd-repo-server \
    deployment/argocd-server \
    statefulset/argocd-application-controller

sleep 20

echo "Restarting metallb (3/6)"
restart metallb \
    deployment/metallb-controller \
    daemonset/metallb-speaker

sleep 15

echo "Restarting ingress-nginx (4/6)"
restart ingress-nginx \
    deployment/ingress-nginx-controller

sleep 10

echo "Restarting cert-manager (5/6)"
restart cert-manager \
    deployment/cert-manager \
    deployment/cert-manager-cainjector \
    deployment/cert-manager-webhook

sleep 10

echo "Restarting homepager (6/6)"
restart homepage \
    deployment/homepage

echo "Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all --all-namespaces

echo "Homelab restart completed!"