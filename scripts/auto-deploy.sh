#!/bin/bash

# Script d'auto-déploiement pour forcer la mise à jour de l'image latest
# Usage: ./scripts/auto-deploy.sh

set -e

echo "🚀 Démarrage du déploiement automatique..."

# Vérifier que kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé ou accessible"
    exit 1
fi

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Impossible de se connecter au cluster Kubernetes"
    exit 1
fi

# Vérifier que le namespace existe
if ! kubectl get namespace tastmanagement &> /dev/null; then
    echo "❌ Le namespace 'tastmanagement' n'existe pas"
    exit 1
fi

echo "✅ Connexion au cluster Kubernetes établie"

# Forcer le redéploiement avec la dernière image
echo "🔄 Redémarrage du déploiement pour récupérer la dernière image..."
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement

# Attendre que le rollout soit terminé
echo "⏳ Attente de la fin du déploiement..."
kubectl rollout status deployment/tastmanagement-app -n tastmanagement --timeout=300s

# Vérifier l'état des pods
echo "📊 État des pods après déploiement:"
kubectl get pods -n tastmanagement -l app=tastmanagement-app

# Vérifier les services
echo "🌐 Services disponibles:"
kubectl get services -n tastmanagement

echo ""
echo "✅ Déploiement automatique terminé avec succès!"
echo "🌟 L'application utilise maintenant la dernière version de l'image"
echo ""
echo "Pour accéder à l'application:"
echo "kubectl port-forward -n tastmanagement service/tastmanagement-service 8080:80"
echo "Puis ouvrir: http://localhost:8080"
