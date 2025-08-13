#!/bin/bash

# Script de déploiement complet pour tastmanagement

set -e

echo "🚀 Déploiement de l'application tastmanagement..."

# Vérifier que kubectl est configuré
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Erreur: kubectl n'est pas configuré ou le cluster n'est pas accessible"
    exit 1
fi

# Déployer les ressources Kubernetes
echo "📦 Déploiement des ressources Kubernetes..."

# Créer le namespace
kubectl apply -f k8s/namespace.yaml

# Déployer les ConfigMaps et Secrets
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Déployer PostgreSQL
echo "🐘 Déploiement de PostgreSQL..."
kubectl apply -f k8s/postgres.yaml

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente du démarrage de PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n tastmanagement

# Déployer l'application Django
echo "🐍 Déploiement de l'application Django..."
kubectl apply -f k8s/deployment.yaml

# Attendre que l'application soit prête
echo "⏳ Attente du démarrage de l'application..."
kubectl wait --for=condition=available --timeout=300s deployment/tastmanagement-app -n tastmanagement

# Vérifier le statut
echo "📊 Statut des déploiements:"
kubectl get pods -n tastmanagement
kubectl get services -n tastmanagement
kubectl get ingress -n tastmanagement

echo "✅ Déploiement terminé avec succès!"
echo "🌐 L'application est accessible via l'ingress configuré"
