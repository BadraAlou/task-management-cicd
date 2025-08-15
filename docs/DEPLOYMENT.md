# 🚀 Guide de Déploiement - TastManagement CI/CD

## 📋 Vue d'Ensemble des Déploiements

Ce guide couvre tous les aspects du déploiement de l'application TastManagement, depuis le développement local jusqu'à la production Kubernetes avec GitOps.

---

## 🏗️ Architectures de Déploiement

### 1. Développement Local
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │───▶│  Docker Compose │───▶│   Local Access  │
│   (Code Edit)   │    │   (3 services)  │    │ localhost:8000  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   PostgreSQL    │
                       │   (Container)   │
                       └─────────────────┘
```

### 2. Production Kubernetes
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  GitHub Push    │───▶│ GitHub Actions  │───▶│      GHCR       │
│                 │    │   (CI/CD)       │    │ (Docker Images) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     ArgoCD      │◀───│   Kubernetes    │◀───│   Image Pull    │
│   (GitOps)      │    │   Cluster       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🔧 Déploiement Local (Développement)

### Prérequis
```bash
# Vérifier les prérequis
docker --version          # Docker 20.10+
docker compose version    # Docker Compose 2.0+
git --version             # Git 2.30+
```

### Installation Rapide
```bash
# 1. Cloner le repository
git clone https://github.com/BadraAlou/task-management-cicd.git
cd task-management-cicd

# 2. Démarrage automatique
./scripts/dev-setup.sh
```

### Démarrage Manuel
```bash
# 1. Construire les images
docker compose build

# 2. Démarrer les services
docker compose up -d

# 3. Appliquer les migrations
docker compose exec web python manage.py migrate

# 4. Créer un superutilisateur
docker compose exec web python manage.py createsuperuser

# 5. Collecter les fichiers statiques
docker compose exec web python manage.py collectstatic --noinput
```

### Vérification
```bash
# Services actifs
docker compose ps

# Logs
docker compose logs -f web

# Accès application
curl http://localhost:8000
# ou navigateur : http://localhost:8000
```

### Arrêt et Nettoyage
```bash
# Arrêt des services
docker compose down

# Nettoyage complet (avec volumes)
docker compose down -v

# Nettoyage des images
docker system prune -a
```

---

## ☸️ Déploiement Kubernetes

### Prérequis
```bash
# Cluster Kubernetes actif
kubectl cluster-info

# Namespace disponible
kubectl get namespaces

# Permissions suffisantes
kubectl auth can-i create deployments
kubectl auth can-i create services
kubectl auth can-i create configmaps
```

### Déploiement Automatique
```bash
# Script de déploiement complet
./scripts/deploy.sh
```

### Déploiement Manuel

#### 1. Création du Namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

#### 2. Configuration et Secrets
```bash
# ConfigMap
kubectl apply -f k8s/configmap.yaml

# Secrets
kubectl apply -f k8s/secret.yaml
```

#### 3. Base de Données PostgreSQL
```bash
# PVC pour persistance
kubectl apply -f k8s/postgres-pvc.yaml

# Déploiement PostgreSQL
kubectl apply -f k8s/postgres.yaml

# Vérifier que PostgreSQL est prêt
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n tastmanagement
```

#### 4. Application Django
```bash
# Déploiement application
kubectl apply -f k8s/deployment.yaml

# Service
kubectl apply -f k8s/service.yaml

# Ingress (optionnel)
kubectl apply -f k8s/ingress.yaml

# Vérifier le déploiement
kubectl wait --for=condition=available --timeout=300s deployment/tastmanagement-app -n tastmanagement
```

#### 5. Vérification
```bash
# État des pods
kubectl get pods -n tastmanagement

# Services
kubectl get svc -n tastmanagement

# Logs
kubectl logs deployment/tastmanagement-app -n tastmanagement

# Accès via port-forward
kubectl port-forward service/tastmanagement-service 8000:80 -n tastmanagement
```

---

## 🔄 Pipeline CI/CD

### Configuration GitHub Actions

#### 1. Secrets Repository
```bash
# Dans GitHub : Settings > Secrets and variables > Actions
GHCR_TOKEN=<github_personal_access_token>
```

#### 2. Permissions Token
Le token GitHub doit avoir les permissions :
- `write:packages` (pour push vers GHCR)
- `read:packages` (pour pull depuis GHCR)
- `contents:read` (pour accès au code)

### Workflow Automatique

#### Déclencheurs
- Push sur branche `main`
- Pull Request vers `main`
- Déclenchement manuel

#### Étapes du Workflow
1. **Checkout** : Récupération du code
2. **Setup Python** : Installation Python 3.11
3. **Install Dependencies** : Installation des dépendances
4. **Run Tests** : Tests unitaires avec PostgreSQL
5. **Build Docker Image** : Construction de l'image
6. **Push to GHCR** : Envoi vers GitHub Container Registry
7. **Update Manifests** : Mise à jour des manifestes K8s

### Surveillance Pipeline
```bash
# Via interface GitHub
https://github.com/BadraAlou/task-management-cicd/actions

# Statut de la dernière exécution
curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/BadraAlou/task-management-cicd/actions/runs
```

---

## 🎯 Déploiement GitOps avec ArgoCD

### Installation ArgoCD
```bash
# Installation automatique
./scripts/install-argocd.sh

# OU installation manuelle
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Configuration Application
```bash
# Appliquer la configuration ArgoCD
kubectl apply -f argocd/namespace.yaml
kubectl apply -f argocd/application.yaml
```

### Accès Interface ArgoCD
```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Accès web : https://localhost:8080
# Username: admin
# Password: (voir commande ci-dessus)
```

### Synchronisation
```bash
# Synchronisation automatique configurée
# Vérifier l'état dans l'interface ArgoCD

# Synchronisation manuelle si nécessaire
kubectl patch application tastmanagement-app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

---

## 🌍 Déploiement Multi-Environnements

### Structure Recommandée
```
environments/
├── dev/
│   ├── kustomization.yaml
│   └── patches/
├── staging/
│   ├── kustomization.yaml
│   └── patches/
└── prod/
    ├── kustomization.yaml
    └── patches/
```

### Configuration par Environnement

#### Développement
```yaml
# environments/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../k8s
patchesStrategicMerge:
- patches/deployment.yaml
images:
- name: ghcr.io/badraalou/task-management-cicd
  newTag: dev
```

#### Production
```yaml
# environments/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../k8s
patchesStrategicMerge:
- patches/deployment.yaml
- patches/resources.yaml
images:
- name: ghcr.io/badraalou/task-management-cicd
  newTag: latest
```

---

## 🔒 Déploiement Sécurisé

### Secrets Management
```bash
# Création de secrets sécurisés
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32) \
  --from-literal=DB_PASSWORD=$(openssl rand -base64 16) \
  -n tastmanagement

# Utilisation d'outils externes (recommandé)
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
# - Google Secret Manager
```

### RBAC
```yaml
# rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tastmanagement
  name: tastmanagement-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
```

### Network Policies
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tastmanagement-netpol
  namespace: tastmanagement
spec:
  podSelector:
    matchLabels:
      app: tastmanagement-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 8000
```

---

## 📊 Monitoring du Déploiement

### Métriques Kubernetes
```bash
# Utilisation des ressources
kubectl top pods -n tastmanagement
kubectl top nodes

# État des déploiements
kubectl get deployments -n tastmanagement -o wide

# Événements récents
kubectl get events -n tastmanagement --sort-by='.lastTimestamp'
```

### Health Checks
```yaml
# Configuration dans deployment.yaml
livenessProbe:
  httpGet:
    path: /
    port: 8000
    scheme: HTTP
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 8000
    scheme: HTTP
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

### Alerting
```bash
# Exemple d'alertes Prometheus
groups:
- name: tastmanagement
  rules:
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod is crash looping"
```

---

## 🔄 Stratégies de Déploiement

### Rolling Update (Défaut)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

### Blue-Green Deployment
```bash
# Créer version green
kubectl apply -f k8s-green/

# Tester la version green
kubectl port-forward service/tastmanagement-service-green 8001:80 -n tastmanagement

# Basculer le trafic
kubectl patch service tastmanagement-service -n tastmanagement -p '{"spec":{"selector":{"version":"green"}}}'

# Supprimer l'ancienne version
kubectl delete -f k8s-blue/
```

### Canary Deployment
```yaml
# Service principal (90% du trafic)
apiVersion: v1
kind: Service
metadata:
  name: tastmanagement-service
spec:
  selector:
    app: tastmanagement-app
    version: stable
  ports:
  - port: 80
    targetPort: 8000

---
# Service canary (10% du trafic)
apiVersion: v1
kind: Service
metadata:
  name: tastmanagement-service-canary
spec:
  selector:
    app: tastmanagement-app
    version: canary
  ports:
  - port: 80
    targetPort: 8000
```

---

## 🔧 Rollback et Recovery

### Rollback Rapide
```bash
# Voir l'historique
kubectl rollout history deployment/tastmanagement-app -n tastmanagement

# Rollback vers version précédente
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement

# Rollback vers version spécifique
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement --to-revision=2

# Vérifier le rollback
kubectl rollout status deployment/tastmanagement-app -n tastmanagement
```

### Sauvegarde Avant Déploiement
```bash
# Script de sauvegarde automatique
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Sauvegarde base de données
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > $BACKUP_DIR/database.sql

# Sauvegarde configurations K8s
kubectl get all -n tastmanagement -o yaml > $BACKUP_DIR/k8s-resources.yaml

echo "Sauvegarde créée dans $BACKUP_DIR"
```

### Recovery Procedures
```bash
# 1. Arrêt d'urgence
kubectl scale deployment tastmanagement-app --replicas=0 -n tastmanagement

# 2. Restauration base de données
kubectl exec -i deployment/postgres -n tastmanagement -- psql -U tastuser tastmanagement < backup/database.sql

# 3. Restauration configuration
kubectl apply -f backup/k8s-resources.yaml

# 4. Redémarrage
kubectl scale deployment tastmanagement-app --replicas=3 -n tastmanagement
```

---

## 📈 Optimisation des Performances

### Ressources Recommandées
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: tastmanagement-hpa
  namespace: tastmanagement
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: tastmanagement-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Optimisation Base de Données
```sql
-- Configuration PostgreSQL recommandée
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
SELECT pg_reload_conf();
```

---

## 🎯 Checklist de Déploiement

### Pré-déploiement
- [ ] Tests locaux passent
- [ ] Code review approuvé
- [ ] Sauvegarde base de données
- [ ] Vérification des secrets
- [ ] Monitoring activé
- [ ] Plan de rollback préparé

### Déploiement
- [ ] Pipeline CI/CD réussie
- [ ] Image Docker construite
- [ ] Manifestes K8s mis à jour
- [ ] Health checks configurés
- [ ] Déploiement progressif

### Post-déploiement
- [ ] Application accessible
- [ ] Logs sans erreurs
- [ ] Métriques normales
- [ ] Tests de fumée passent
- [ ] Monitoring opérationnel
- [ ] Documentation mise à jour

---

**🚀 Ce guide de déploiement couvre tous les scénarios de déploiement. Pour des questions spécifiques, consultez la [documentation d'administration](./ADMINISTRATION.md) ou le [guide de dépannage](./TROUBLESHOOTING.md).**
