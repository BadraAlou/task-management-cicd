# 🔧 Guide de Dépannage - TastManagement CI/CD

## 🚨 Problèmes Critiques et Solutions

### 1. Application Inaccessible

#### Symptômes
- Erreur 502/503/504 dans le navigateur
- Timeout de connexion
- Service unavailable

#### Diagnostic
```bash
# Vérifier l'état des pods
kubectl get pods -n tastmanagement

# Vérifier les services
kubectl get svc -n tastmanagement

# Logs de l'application
kubectl logs deployment/tastmanagement-app -n tastmanagement --tail=50
```

#### Solutions
```bash
# 1. Redémarrer l'application
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement

# 2. Vérifier le port-forward
kubectl port-forward service/tastmanagement-service 8000:80 -n tastmanagement

# 3. Vérifier les endpoints
kubectl get endpoints -n tastmanagement

# 4. Test de connectivité interne
kubectl run test --image=busybox -it --rm --restart=Never -- wget -qO- http://tastmanagement-service.tastmanagement.svc.cluster.local
```

---

### 2. Pods en CrashLoopBackOff

#### Symptômes
- Pods redémarrent continuellement
- Status : CrashLoopBackOff
- Application indisponible

#### Diagnostic
```bash
# État détaillé du pod
kubectl describe pod <pod-name> -n tastmanagement

# Logs du pod actuel
kubectl logs <pod-name> -n tastmanagement

# Logs du pod précédent (avant crash)
kubectl logs <pod-name> -n tastmanagement --previous

# Événements récents
kubectl get events -n tastmanagement --sort-by='.lastTimestamp' | tail -10
```

#### Solutions Courantes
```bash
# 1. Problème de configuration
kubectl edit configmap tastmanagement-config -n tastmanagement

# 2. Problème de secrets
kubectl get secrets -n tastmanagement
kubectl describe secret tastmanagement-secret -n tastmanagement

# 3. Ressources insuffisantes
kubectl describe node
kubectl top pods -n tastmanagement

# 4. Health checks trop stricts
kubectl edit deployment tastmanagement-app -n tastmanagement
# Augmenter initialDelaySeconds et timeoutSeconds
```

---

### 3. Base de Données Inaccessible

#### Symptômes
- Erreurs Django de connexion DB
- "could not connect to server"
- Timeouts de base de données

#### Diagnostic
```bash
# État PostgreSQL
kubectl get pods -l app=postgres -n tastmanagement
kubectl logs deployment/postgres -n tastmanagement

# Test de connexion
kubectl exec -it deployment/postgres -n tastmanagement -- pg_isready -U tastuser

# Variables d'environnement
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- env | grep DATABASE
```

#### Solutions
```bash
# 1. Redémarrer PostgreSQL
kubectl rollout restart deployment/postgres -n tastmanagement

# 2. Vérifier les secrets
kubectl get secret tastmanagement-secret -n tastmanagement -o yaml

# 3. Test de connexion manuelle
kubectl exec -it deployment/postgres -n tastmanagement -- psql -U tastuser -d tastmanagement -c "SELECT version();"

# 4. Vérifier le PVC
kubectl get pvc -n tastmanagement
kubectl describe pvc postgres-pvc -n tastmanagement
```

---

### 4. Pipeline CI/CD Échoue

#### Symptômes
- Build Docker échoue
- Push vers registry échoue
- Tests automatisés échouent

#### Diagnostic
```bash
# Via GitHub Actions
# https://github.com/BadraAlou/task-management-cicd/actions

# Vérifier les secrets GitHub
# Settings > Secrets and variables > Actions

# Test local du build
docker build -t test-image .
docker run --rm -p 8000:8000 test-image
```

#### Solutions
```bash
# 1. Problème de token GHCR
# Régénérer le token GitHub avec permissions packages:write

# 2. Problème de build Docker
# Vérifier le Dockerfile et les dépendances
docker build --no-cache -t test .

# 3. Tests échouent
# Exécuter les tests localement
docker compose exec web python manage.py test

# 4. Manifestes Kubernetes invalides
./scripts/test-pipeline.sh
```

---

### 5. ArgoCD Ne Synchronise Pas

#### Symptômes
- Application "OutOfSync" dans ArgoCD
- Changements non déployés automatiquement
- Erreurs de synchronisation

#### Diagnostic
```bash
# État ArgoCD
kubectl get pods -n argocd
kubectl logs deployment/argocd-application-controller -n argocd

# Via interface web ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
```

#### Solutions
```bash
# 1. Synchronisation manuelle
kubectl patch application tastmanagement-app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'

# 2. Vérifier la configuration
kubectl get application tastmanagement-app -n argocd -o yaml

# 3. Redémarrer ArgoCD
kubectl rollout restart deployment/argocd-application-controller -n argocd

# 4. Vérifier les permissions Git
# S'assurer que le repository est accessible publiquement
```

---

## 🔍 Outils de Diagnostic

### Commandes de Base
```bash
# Vue d'ensemble complète
kubectl get all -n tastmanagement

# Événements récents
kubectl get events -n tastmanagement --sort-by='.lastTimestamp'

# Utilisation des ressources
kubectl top pods -n tastmanagement
kubectl top nodes

# Description détaillée
kubectl describe deployment tastmanagement-app -n tastmanagement
kubectl describe service tastmanagement-service -n tastmanagement
```

### Tests de Connectivité
```bash
# Test DNS interne
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- nslookup postgres.tastmanagement.svc.cluster.local

# Test de port
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- nc -zv postgres 5432

# Test HTTP interne
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- curl -I http://tastmanagement-service.tastmanagement.svc.cluster.local
```

### Logs Avancés
```bash
# Logs avec horodatage
kubectl logs deployment/tastmanagement-app -n tastmanagement --timestamps=true

# Logs de tous les conteneurs
kubectl logs -l app=tastmanagement-app -n tastmanagement --all-containers=true

# Logs des dernières heures
kubectl logs deployment/tastmanagement-app -n tastmanagement --since=2h

# Suivre les logs en temps réel
kubectl logs -f deployment/tastmanagement-app -n tastmanagement
```

---

## 🚨 Procédures d'Urgence

### Arrêt d'Urgence
```bash
# Arrêter l'application
kubectl scale deployment tastmanagement-app --replicas=0 -n tastmanagement

# Arrêter tout le namespace
kubectl delete all --all -n tastmanagement
```

### Sauvegarde d'Urgence
```bash
# Sauvegarde base de données
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > emergency-backup-$(date +%Y%m%d-%H%M%S).sql

# Sauvegarde des configurations
kubectl get all -n tastmanagement -o yaml > k8s-backup-$(date +%Y%m%d-%H%M%S).yaml
```

### Rollback d'Urgence
```bash
# Rollback vers version précédente
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement

# Voir l'historique des déploiements
kubectl rollout history deployment/tastmanagement-app -n tastmanagement

# Rollback vers version spécifique
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement --to-revision=2
```

### Redémarrage Complet
```bash
# Redémarrer tous les composants
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement
kubectl rollout restart deployment/postgres -n tastmanagement

# Attendre que tout soit prêt
kubectl wait --for=condition=available --timeout=300s deployment/tastmanagement-app -n tastmanagement
```

---

## 📊 Monitoring et Alertes

### Métriques Importantes
```bash
# CPU et mémoire
kubectl top pods -n tastmanagement

# Espace disque (PVC)
kubectl exec -it deployment/postgres -n tastmanagement -- df -h

# Connexions base de données
kubectl exec -it deployment/postgres -n tastmanagement -- psql -U tastuser -d tastmanagement -c "SELECT count(*) FROM pg_stat_activity;"
```

### Seuils d'Alerte Recommandés
- **CPU** : > 80% pendant 5 minutes
- **Mémoire** : > 85% pendant 5 minutes
- **Espace disque** : > 90%
- **Pods non-ready** : > 1 pod pendant 2 minutes
- **Erreurs HTTP** : > 5% sur 5 minutes

---

## 🔧 Maintenance Préventive

### Vérifications Quotidiennes
```bash
# État général
kubectl get pods -n tastmanagement
kubectl get events -n tastmanagement --since=24h

# Logs d'erreur
kubectl logs deployment/tastmanagement-app -n tastmanagement --since=24h | grep -i error

# Utilisation des ressources
kubectl top pods -n tastmanagement
```

### Vérifications Hebdomadaires
```bash
# Sauvegarde base de données
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > weekly-backup-$(date +%Y%m%d).sql

# Nettoyage des logs
kubectl logs deployment/tastmanagement-app -n tastmanagement --tail=1000 > app-logs-$(date +%Y%m%d).log

# Vérification des mises à jour
docker pull python:3.11-slim
docker pull postgres:16-alpine
```

---

## 📞 Escalade et Support

### Niveaux d'Escalade

**Niveau 1 - Auto-résolution (5 min)**
- Redémarrage des pods
- Vérification des logs basiques
- Port-forward pour accès

**Niveau 2 - Investigation (15 min)**
- Analyse des événements Kubernetes
- Vérification des configurations
- Tests de connectivité

**Niveau 3 - Intervention avancée (30 min)**
- Rollback de déploiement
- Restauration de sauvegarde
- Modification des configurations

**Niveau 4 - Escalade externe**
- Contact équipe infrastructure
- Ouverture ticket support cloud provider
- Intervention manuelle sur cluster

### Informations à Collecter
```bash
# Package d'informations de debug
mkdir debug-$(date +%Y%m%d-%H%M%S)
cd debug-$(date +%Y%m%d-%H%M%S)

kubectl get all -n tastmanagement -o yaml > k8s-resources.yaml
kubectl get events -n tastmanagement > events.log
kubectl logs deployment/tastmanagement-app -n tastmanagement > app-logs.log
kubectl logs deployment/postgres -n tastmanagement > db-logs.log
kubectl describe deployment tastmanagement-app -n tastmanagement > deployment-description.txt

tar -czf debug-package.tar.gz *
```

---

**🔧 Ce guide de dépannage couvre les problèmes les plus courants. Pour des problèmes spécifiques non couverts, consultez la [documentation complète](./ADMINISTRATION.md) ou créez une issue sur GitHub.**
