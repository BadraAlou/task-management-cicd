# TastManagement - Pipeline CI/CD avec GitOps

Une application Django avec une pipeline CI/CD complète utilisant GitHub Actions, Docker, Kubernetes et ArgoCD.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│  Container Reg  │
│                 │    │     (CI/CD)     │    │     (GHCR)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ArgoCD        │◀───│   Kubernetes    │◀───│   GitOps Sync   │
│   (GitOps)      │    │    Cluster      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Démarrage rapide

### Développement local

1. **Configuration de l'environnement de développement :**
   ```bash
   ./scripts/dev-setup.sh
   ```

2. **Accès à l'application :**
   - Application : http://localhost:8000
   - Admin Django : http://localhost:8000/admin (admin/admin123)

### Déploiement en production

1. **Prérequis :**
   - Cluster Kubernetes configuré
   - kubectl configuré
   - Accès au repository GitHub

2. **Installation d'ArgoCD :**
   ```bash
   ./scripts/install-argocd.sh
   ```

3. **Déploiement de l'application :**
   ```bash
   ./scripts/deploy.sh
   ```

## 📁 Structure du projet

```
my-ci-cd/
├── tastmanagement/          # Application Django
├── k8s/                     # Manifestes Kubernetes
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres.yaml
│   └── deployment.yaml
├── argocd/                  # Configuration ArgoCD
│   ├── namespace.yaml
│   └── application.yaml
├── scripts/                 # Scripts de déploiement
│   ├── install-argocd.sh
│   ├── deploy.sh
│   └── dev-setup.sh
├── .github/workflows/       # GitHub Actions
│   └── ci-cd.yml
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
└── requirements.txt
```

## 🔄 Pipeline CI/CD

### 1. Continuous Integration (CI)
- **Tests automatisés** sur chaque push/PR
- **Analyse de couverture** de code
- **Build Docker** automatique

### 2. Continuous Deployment (CD)
- **Push automatique** vers GitHub Container Registry
- **Mise à jour** des manifestes Kubernetes
- **Déploiement GitOps** via ArgoCD

### 3. GitOps avec ArgoCD
- **Synchronisation automatique** des manifestes
- **Rollback** automatique en cas d'échec
- **Interface web** pour monitoring

## 🛠️ Configuration

### Variables d'environnement

#### Développement (docker-compose.yml)
- `DEBUG=False`
- `DATABASE_URL=postgresql://...`

#### Production (Kubernetes)
- ConfigMap : `tastmanagement-config`
- Secret : `tastmanagement-secret`

### GitHub Actions Secrets
Configurez ces secrets dans votre repository GitHub :
- `GITHUB_TOKEN` (automatique)

### ArgoCD Application
Modifiez `argocd/application.yaml` :
```yaml
source:
  repoURL: https://github.com/VOTRE-USERNAME/my-ci-cd.git
```

## 🔧 Commandes utiles

### Développement local
```bash
# Démarrer l'environnement
docker-compose up -d

# Voir les logs
docker-compose logs -f web

# Exécuter des commandes Django
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser

# Arrêter l'environnement
docker-compose down
```

### Kubernetes
```bash
# Vérifier le statut
kubectl get pods -n tastmanagement
kubectl get services -n tastmanagement

# Voir les logs
kubectl logs -f deployment/tastmanagement-app -n tastmanagement

# Port-forward pour accès local
kubectl port-forward svc/tastmanagement-service 8000:80 -n tastmanagement
```

### ArgoCD
```bash
# Accès à l'interface ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🔐 Sécurité

- **Secrets Kubernetes** pour les données sensibles
- **Variables d'environnement** séparées par environnement
- **RBAC** configuré pour ArgoCD
- **Network Policies** (à implémenter selon vos besoins)

## 📊 Monitoring

- **Liveness/Readiness probes** configurées
- **Logs centralisés** via kubectl
- **Interface ArgoCD** pour le monitoring GitOps

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request

## 📝 Notes importantes

- **Remplacez `USERNAME`** dans les fichiers par votre nom d'utilisateur GitHub
- **Générez une nouvelle SECRET_KEY** pour la production
- **Configurez votre domaine** dans l'Ingress Kubernetes
- **Adaptez les ressources** (CPU/Memory) selon vos besoins

## 🆘 Dépannage

### Problèmes courants

1. **Image Docker non trouvée**
   - Vérifiez que l'image est bien pushée vers GHCR
   - Vérifiez les permissions du repository

2. **Pods en CrashLoopBackOff**
   - Vérifiez les logs : `kubectl logs <pod-name> -n tastmanagement`
   - Vérifiez la configuration des secrets et configmaps

3. **ArgoCD ne synchronise pas**
   - Vérifiez l'URL du repository dans `application.yaml`
   - Vérifiez les permissions d'accès au repository
