#!/bin/bash

# Webhook pour déclenchement automatique du déploiement
# Ce script peut être appelé par GitHub Actions ou un webhook externe

set -e

echo "🔔 Webhook de déploiement déclenché à $(date)"

# Variables d'environnement
NAMESPACE=${NAMESPACE:-"tastmanagement"}
DEPLOYMENT=${DEPLOYMENT:-"tastmanagement-app"}
TIMEOUT=${TIMEOUT:-"300s"}

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Vérifications préliminaires
log "🔍 Vérification des prérequis..."

if ! command -v kubectl &> /dev/null; then
    log "❌ kubectl n'est pas disponible"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    log "❌ Cluster Kubernetes inaccessible"
    exit 1
fi

# Vérifier l'existence du déploiement
if ! kubectl get deployment/$DEPLOYMENT -n $NAMESPACE &> /dev/null; then
    log "❌ Déploiement $DEPLOYMENT introuvable dans le namespace $NAMESPACE"
    exit 1
fi

log "✅ Prérequis validés"

# Obtenir l'état actuel
CURRENT_REPLICAS=$(kubectl get deployment/$DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.replicas}')
log "📊 Réplicas actuelles: $CURRENT_REPLICAS"

# Forcer le redéploiement
log "🚀 Déclenchement du rollout restart..."
kubectl rollout restart deployment/$DEPLOYMENT -n $NAMESPACE

# Attendre la fin du déploiement
log "⏳ Attente de la fin du rollout (timeout: $TIMEOUT)..."
if kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=$TIMEOUT; then
    log "✅ Rollout terminé avec succès"
else
    log "❌ Timeout du rollout - vérification manuelle requise"
    exit 1
fi

# Vérification post-déploiement
log "🔍 Vérification post-déploiement..."
READY_REPLICAS=$(kubectl get deployment/$DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
UPDATED_REPLICAS=$(kubectl get deployment/$DEPLOYMENT -n $NAMESPACE -o jsonpath='{.status.updatedReplicas}')

log "📊 État final:"
log "  - Réplicas prêtes: $READY_REPLICAS/$CURRENT_REPLICAS"
log "  - Réplicas mises à jour: $UPDATED_REPLICAS/$CURRENT_REPLICAS"

if [[ "$READY_REPLICAS" == "$CURRENT_REPLICAS" ]] && [[ "$UPDATED_REPLICAS" == "$CURRENT_REPLICAS" ]]; then
    log "✅ Déploiement réussi - Toutes les réplicas sont prêtes et à jour"
    
    # Afficher les pods mis à jour
    log "🎯 Pods actifs:"
    kubectl get pods -n $NAMESPACE -l app=tastmanagement-app --no-headers | while read line; do
        log "  - $line"
    done
    
    log "🌟 Déploiement automatique terminé avec succès!"
    exit 0
else
    log "⚠️  Déploiement partiellement réussi - Vérification manuelle recommandée"
    exit 1
fi
