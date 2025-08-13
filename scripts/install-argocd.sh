#!/bin/bash

# Script pour installer ArgoCD sur Kubernetes

echo "🚀 Installation d'ArgoCD..."

# Créer le namespace ArgoCD
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
echo "⏳ Attente du démarrage des pods ArgoCD..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Exposer ArgoCD via port-forward (pour développement)
echo "🌐 Configuration de l'accès ArgoCD..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Récupérer le mot de passe admin initial
echo "🔑 Récupération du mot de passe admin ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD installé avec succès!"
echo "📋 Informations de connexion:"
echo "   URL: https://localhost:8080 (après port-forward)"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "🔧 Pour accéder à ArgoCD, exécutez:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
