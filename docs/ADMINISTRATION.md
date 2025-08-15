# 📚 Documentation Complète - Administration & Maintenance

## 🎯 Vue d'Ensemble du Système

**TastManagement** est une application Django moderne déployée avec une pipeline CI/CD complète utilisant :
- **GitHub Actions** pour l'intégration continue
- **Docker** pour la containerisation
- **Kubernetes** pour l'orchestration
- **ArgoCD** pour le GitOps
- **PostgreSQL** pour la base de données
- **GitHub Container Registry** pour les images Docker

---

## 📋 Table des Matières

1. [Architecture du Système](#architecture-du-système)
2. [Prérequis et Installation](#prérequis-et-installation)
3. [Administration Kubernetes](#administration-kubernetes)
4. [Gestion de la Pipeline CI/CD](#gestion-de-la-pipeline-cicd)
5. [Administration ArgoCD](#administration-argocd)
6. [Gestion de la Base de Données](#gestion-de-la-base-de-données)
7. [Monitoring et Logs](#monitoring-et-logs)
8. [Sécurité](#sécurité)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance et Mises à Jour](#maintenance-et-mises-à-jour)
11. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🏗️ Architecture du Système

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │───▶│   GitHub Repo   │───▶│ GitHub Actions  │
│   (Code Push)   │    │                 │    │   (CI/CD)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ArgoCD        │◀───│   Kubernetes    │◀───│     GHCR        │
│   (GitOps)      │    │   Cluster       │    │ (Docker Images) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   PostgreSQL    │
                       │   Database      │
                       └─────────────────┘
```

### Composants Principaux

- **Frontend** : Page d'accueil personnalisée avec HTML/CSS/JS
- **Backend** : Django 5.1 avec API REST
- **Base de données** : PostgreSQL 16 avec persistance
- **Reverse Proxy** : Nginx (développement local)
- **Orchestration** : Kubernetes avec 3 réplicas
- **CI/CD** : GitHub Actions avec tests automatisés
- **GitOps** : ArgoCD pour déploiement automatique

---

## 🔧 Prérequis et Installation

### Prérequis Système

```bash
# Outils requis
- Docker Desktop ou Docker Engine
- Kubernetes (minikube, Docker Desktop, ou cluster cloud)
- kubectl
- git
- Python 3.11+
- Node.js (optionnel pour outils frontend)
```

### Installation Initiale

```bash
# 1. Cloner le repository
git clone https://github.com/BadraAlou/task-management-cicd.git
cd task-management-cicd

# 2. Configuration des permissions
chmod +x scripts/*.sh

# 3. Installation locale (développement)
./scripts/dev-setup.sh

# 4. Déploiement Kubernetes
./scripts/deploy.sh

# 5. Installation ArgoCD (optionnel)
./scripts/install-argocd.sh
```

### Variables d'Environnement

```bash
# Fichier .env (développement local)
DEBUG=True
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://tastuser:password@db:5432/tastmanagement
ALLOWED_HOSTS=localhost,127.0.0.1,*

# Kubernetes ConfigMap
DEBUG=True
ALLOWED_HOSTS=*
DATABASE_URL=postgresql://tastuser:password@postgres:5432/tastmanagement

# Kubernetes Secrets
SECRET_KEY=<base64-encoded-secret>
POSTGRES_PASSWORD=<base64-encoded-password>
```

---

## ☸️ Administration Kubernetes

### Commandes Essentielles

```bash
# État général du cluster
kubectl get all -n tastmanagement

# Vérification des pods
kubectl get pods -n tastmanagement -o wide

# Logs des applications
kubectl logs -f deployment/tastmanagement-app -n tastmanagement

# Logs PostgreSQL
kubectl logs -f deployment/postgres -n tastmanagement

# Accès shell aux pods
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- /bin/bash

# Port forwarding pour accès local
kubectl port-forward service/tastmanagement-service 8000:80 -n tastmanagement
```

### Gestion des Déploiements

```bash
# Redémarrage des pods
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement

# Historique des déploiements
kubectl rollout history deployment/tastmanagement-app -n tastmanagement

# Rollback vers version précédente
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement

# Mise à l'échelle
kubectl scale deployment tastmanagement-app --replicas=5 -n tastmanagement

# Mise à jour de l'image
kubectl set image deployment/tastmanagement-app tastmanagement=ghcr.io/badraalou/task-management-cicd:v1.2.0 -n tastmanagement
```

### Configuration et Secrets

```bash
# Voir les ConfigMaps
kubectl get configmap -n tastmanagement
kubectl describe configmap tastmanagement-config -n tastmanagement

# Modifier une ConfigMap
kubectl edit configmap tastmanagement-config -n tastmanagement

# Voir les Secrets
kubectl get secrets -n tastmanagement
kubectl describe secret tastmanagement-secret -n tastmanagement

# Créer un nouveau secret
kubectl create secret generic new-secret --from-literal=key=value -n tastmanagement

# Encoder/décoder base64
echo -n "mon-secret" | base64
echo "bW9uLXNlY3JldA==" | base64 -d
```

### Surveillance et Debugging

```bash
# Événements du cluster
kubectl get events -n tastmanagement --sort-by='.lastTimestamp'

# Utilisation des ressources
kubectl top pods -n tastmanagement
kubectl top nodes

# Description détaillée
kubectl describe pod <pod-name> -n tastmanagement
kubectl describe service tastmanagement-service -n tastmanagement

# Vérification des endpoints
kubectl get endpoints -n tastmanagement

# Test de connectivité réseau
kubectl run test-pod --image=busybox -it --rm --restart=Never -- nslookup tastmanagement-service.tastmanagement.svc.cluster.local
```

---

## 🚀 Gestion de la Pipeline CI/CD

### Workflow GitHub Actions

La pipeline se déclenche automatiquement sur :
- Push sur la branche `main`
- Pull requests vers `main`
- Déclenchement manuel

### Étapes de la Pipeline

1. **Tests** : Tests unitaires Django avec PostgreSQL
2. **Build** : Construction de l'image Docker
3. **Push** : Envoi vers GitHub Container Registry
4. **Deploy** : Mise à jour des manifestes Kubernetes

### Surveillance de la Pipeline

```bash
# Via l'interface GitHub
https://github.com/BadraAlou/task-management-cicd/actions

# Via CLI (si gh installé)
gh run list
gh run view <run-id>
gh run logs <run-id>
```

### Variables et Secrets GitHub

```yaml
# Repository Secrets (Settings > Secrets and variables > Actions)
GHCR_TOKEN: <GitHub Personal Access Token>

# Repository Variables
IMAGE_NAME: badraalou/task-management-cicd
REGISTRY: ghcr.io
```

### Débogage de la Pipeline

```bash
# Vérifier l'image construite
docker pull ghcr.io/badraalou/task-management-cicd:latest
docker run --rm -it ghcr.io/badraalou/task-management-cicd:latest /bin/bash

# Tester localement
docker build -t test-image .
docker run -p 8000:8000 test-image

# Vérifier les manifestes mis à jour
git log --oneline -n 10
git show HEAD:k8s/deployment.yaml
```

---

## 🎯 Administration ArgoCD

### Installation et Configuration

```bash
# Installation ArgoCD
./scripts/install-argocd.sh

# Accès à l'interface web
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupération du mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Interface Web ArgoCD

- **URL** : https://localhost:8080
- **Username** : admin
- **Password** : (voir commande ci-dessus)

### Commandes ArgoCD CLI

```bash
# Installation CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login
argocd login localhost:8080

# Liste des applications
argocd app list

# Synchronisation manuelle
argocd app sync tastmanagement-app

# Logs de synchronisation
argocd app logs tastmanagement-app
```

### Configuration GitOps

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tastmanagement-app
spec:
  source:
    repoURL: https://github.com/BadraAlou/task-management-cicd.git
    path: k8s
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: tastmanagement
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🗄️ Gestion de la Base de Données

### Connexion à PostgreSQL

```bash
# Via kubectl
kubectl exec -it deployment/postgres -n tastmanagement -- psql -U tastuser -d tastmanagement

# Via port-forward
kubectl port-forward service/postgres 5432:5432 -n tastmanagement
psql -h localhost -U tastuser -d tastmanagement
```

### Commandes PostgreSQL Essentielles

```sql
-- Informations sur la base
\l
\dt
\d+ taskmaster_*

-- Utilisateurs et permissions
\du
SELECT * FROM pg_stat_activity;

-- Taille de la base
SELECT pg_size_pretty(pg_database_size('tastmanagement'));

-- Tables et données
SELECT schemaname,tablename,attname,n_distinct,correlation FROM pg_stats;
```

### Migrations Django

```bash
# Dans un pod Django
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- python manage.py showmigrations
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- python manage.py migrate
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- python manage.py makemigrations

# Création d'un superutilisateur
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- python manage.py createsuperuser
```

### Sauvegarde et Restauration

```bash
# Sauvegarde
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > backup.sql

# Restauration
kubectl exec -i deployment/postgres -n tastmanagement -- psql -U tastuser tastmanagement < backup.sql

# Sauvegarde avec compression
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser -Fc tastmanagement > backup.dump
```

---

## 📊 Monitoring et Logs

### Logs des Applications

```bash
# Logs en temps réel
kubectl logs -f deployment/tastmanagement-app -n tastmanagement

# Logs avec horodatage
kubectl logs deployment/tastmanagement-app -n tastmanagement --timestamps=true

# Logs des dernières heures
kubectl logs deployment/tastmanagement-app -n tastmanagement --since=2h

# Logs de tous les pods
kubectl logs -l app=tastmanagement-app -n tastmanagement --all-containers=true

# Logs PostgreSQL
kubectl logs deployment/postgres -n tastmanagement --tail=100
```

### Métriques et Surveillance

```bash
# Utilisation CPU/Mémoire
kubectl top pods -n tastmanagement
kubectl top nodes

# Événements système
kubectl get events -n tastmanagement --sort-by='.lastTimestamp' | head -20

# État des ressources
kubectl describe deployment tastmanagement-app -n tastmanagement
kubectl describe service tastmanagement-service -n tastmanagement
```

### Configuration des Logs Django

```python
# settings.py - Configuration logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

---

## 🔒 Sécurité

### Secrets Kubernetes

```bash
# Création de secrets sécurisés
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32) \
  --from-literal=DB_PASSWORD=$(openssl rand -base64 16) \
  -n tastmanagement

# Rotation des secrets
kubectl delete secret tastmanagement-secret -n tastmanagement
kubectl create secret generic tastmanagement-secret \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32) \
  -n tastmanagement
```

### Configuration Django Sécurisée

```python
# settings_prod.py
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### RBAC Kubernetes

```yaml
# rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: tastmanagement
  name: app-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list"]
```

### Audit et Conformité

```bash
# Vérification des permissions
kubectl auth can-i get pods --namespace=tastmanagement
kubectl auth can-i create secrets --namespace=tastmanagement

# Scan de sécurité des images
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image ghcr.io/badraalou/task-management-cicd:latest
```

---

## 🔧 Troubleshooting

### Problèmes Courants

#### 1. Pods en CrashLoopBackOff

```bash
# Diagnostic
kubectl describe pod <pod-name> -n tastmanagement
kubectl logs <pod-name> -n tastmanagement --previous

# Solutions courantes
- Vérifier les variables d'environnement
- Contrôler les secrets et configmaps
- Vérifier les health checks
- Examiner les ressources (CPU/mémoire)
```

#### 2. Service Inaccessible

```bash
# Vérifications
kubectl get svc -n tastmanagement
kubectl get endpoints -n tastmanagement
kubectl describe svc tastmanagement-service -n tastmanagement

# Test de connectivité
kubectl run test --image=busybox -it --rm --restart=Never -- wget -qO- http://tastmanagement-service.tastmanagement.svc.cluster.local
```

#### 3. Base de Données Inaccessible

```bash
# Vérification PostgreSQL
kubectl logs deployment/postgres -n tastmanagement
kubectl exec -it deployment/postgres -n tastmanagement -- pg_isready

# Test de connexion
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- python manage.py dbshell
```

#### 4. Pipeline CI/CD Échoue

```bash
# Vérifications GitHub Actions
- Contrôler les secrets GitHub (GHCR_TOKEN)
- Vérifier les permissions du token
- Examiner les logs de build Docker
- Contrôler la syntaxe des manifestes YAML
```

### Commandes de Diagnostic

```bash
# État complet du cluster
kubectl get all -A
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Ressources par namespace
kubectl get all -n tastmanagement
kubectl describe namespace tastmanagement

# Vérification des quotas
kubectl describe quota -n tastmanagement
kubectl describe limitrange -n tastmanagement

# Test de résolution DNS
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- nslookup postgres.tastmanagement.svc.cluster.local
```

---

## 🔄 Maintenance et Mises à Jour

### Mises à Jour Régulières

```bash
# 1. Mise à jour des images de base
docker pull python:3.11-slim
docker pull postgres:16-alpine

# 2. Mise à jour des dépendances Python
pip list --outdated
pip install --upgrade package-name

# 3. Mise à jour Kubernetes
kubectl version
# Suivre la documentation officielle pour les mises à jour

# 4. Mise à jour ArgoCD
kubectl get pods -n argocd
# Suivre la documentation ArgoCD
```

### Nettoyage et Optimisation

```bash
# Nettoyage Docker
docker system prune -a
docker volume prune

# Nettoyage Kubernetes
kubectl delete pod --field-selector=status.phase==Succeeded -n tastmanagement
kubectl delete pod --field-selector=status.phase==Failed -n tastmanagement

# Optimisation des ressources
kubectl top pods -n tastmanagement
# Ajuster les requests/limits dans les manifestes
```

### Planification des Maintenances

```yaml
# Exemple de fenêtre de maintenance
apiVersion: v1
kind: ConfigMap
metadata:
  name: maintenance-schedule
data:
  schedule: "0 2 * * 0"  # Dimanche 2h du matin
  duration: "2h"
  tasks: |
    - Sauvegarde base de données
    - Mise à jour sécurité
    - Nettoyage logs
    - Vérification monitoring
```

---

## ✅ Bonnes Pratiques

### Développement

```bash
# 1. Toujours tester localement avant push
./scripts/test-pipeline.sh

# 2. Utiliser des branches pour les features
git checkout -b feature/nouvelle-fonctionnalite
git push origin feature/nouvelle-fonctionnalite

# 3. Code review obligatoire
# Configurer les branch protection rules sur GitHub

# 4. Tests automatisés
python manage.py test
coverage run --source='.' manage.py test
```

### Déploiement

```bash
# 1. Déploiement progressif
kubectl patch deployment tastmanagement-app -n tastmanagement -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":"25%","maxSurge":"25%"}}}}'

# 2. Health checks appropriés
# Configurer liveness et readiness probes

# 3. Monitoring continu
# Surveiller les métriques et logs

# 4. Rollback rapide si problème
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement
```

### Sécurité

```bash
# 1. Rotation régulière des secrets
# Automatiser avec des scripts ou ArgoCD

# 2. Mise à jour sécurité
# Surveiller les CVE et mettre à jour rapidement

# 3. Principe du moindre privilège
# RBAC strict, pas de privilèges root

# 4. Audit régulier
# Logs, accès, permissions
```

### Monitoring

```bash
# 1. Alertes proactives
# Configurer des seuils d'alerte

# 2. Dashboards complets
# Grafana + Prometheus recommandés

# 3. Logs centralisés
# ELK Stack ou équivalent

# 4. Tests de charge réguliers
# Vérifier les performances
```

---

## 📞 Support et Contacts

### Ressources Utiles

- **Documentation Django** : https://docs.djangoproject.com/
- **Documentation Kubernetes** : https://kubernetes.io/docs/
- **Documentation ArgoCD** : https://argo-cd.readthedocs.io/
- **GitHub Actions** : https://docs.github.com/en/actions

### Commandes d'Urgence

```bash
# Arrêt d'urgence
kubectl scale deployment tastmanagement-app --replicas=0 -n tastmanagement

# Redémarrage rapide
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement

# Sauvegarde d'urgence
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > emergency-backup-$(date +%Y%m%d-%H%M%S).sql

# Logs d'urgence
kubectl logs deployment/tastmanagement-app -n tastmanagement --since=1h > emergency-logs.txt
```

---

## 📝 Changelog et Versions

### Version 1.0.0 (Actuelle)
- ✅ Pipeline CI/CD complète
- ✅ Déploiement Kubernetes
- ✅ Page d'accueil personnalisée
- ✅ ArgoCD GitOps
- ✅ Documentation complète

### Roadmap Futur
- [ ] Monitoring avec Prometheus/Grafana
- [ ] Certificats SSL automatiques
- [ ] Tests de charge automatisés
- [ ] Multi-environnements (dev/staging/prod)

---

**📚 Cette documentation est maintenue et mise à jour régulièrement. Pour toute question ou amélioration, créez une issue sur le repository GitHub.**
