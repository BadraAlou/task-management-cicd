# 🚀 Guide de Démarrage Rapide - TastManagement CI/CD

## ⚡ Démarrage en 5 Minutes

### 1. Prérequis Rapides
```bash
# Vérifiez que vous avez :
docker --version          # Docker 20.10+
kubectl version --client  # kubectl 1.20+
git --version             # Git 2.30+
```

### 2. Installation Express
```bash
# Clone et setup
git clone https://github.com/BadraAlou/task-management-cicd.git
cd task-management-cicd
chmod +x scripts/*.sh

# Démarrage local (développement)
./scripts/dev-setup.sh

# OU déploiement Kubernetes
./scripts/deploy.sh
```

### 3. Accès Immédiat
```bash
# Local (après dev-setup.sh)
http://localhost:8000

# Kubernetes (après deploy.sh)
kubectl port-forward service/tastmanagement-service 8000:80 -n tastmanagement
# Puis : http://localhost:8000
```

---

## 🎯 Commandes Essentielles

### Développement Local
```bash
# Démarrer l'environnement
./scripts/dev-setup.sh

# Arrêter l'environnement
docker compose down

# Logs en temps réel
docker compose logs -f web

# Shell Django
docker compose exec web python manage.py shell

# Migrations
docker compose exec web python manage.py migrate
```

### Production Kubernetes
```bash
# État du système
kubectl get all -n tastmanagement

# Logs application
kubectl logs -f deployment/tastmanagement-app -n tastmanagement

# Redémarrage
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement

# Accès shell
kubectl exec -it deployment/tastmanagement-app -n tastmanagement -- /bin/bash

# Scaling
kubectl scale deployment tastmanagement-app --replicas=5 -n tastmanagement
```

### Pipeline CI/CD
```bash
# Déclencher un déploiement
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main

# Surveiller la pipeline
# https://github.com/BadraAlou/task-management-cicd/actions

# Forcer un redéploiement
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement
```

---

## 🔧 Résolution Rapide de Problèmes

### Pod ne démarre pas
```bash
kubectl describe pod <pod-name> -n tastmanagement
kubectl logs <pod-name> -n tastmanagement
```

### Service inaccessible
```bash
kubectl get svc -n tastmanagement
kubectl port-forward service/tastmanagement-service 8000:80 -n tastmanagement
```

### Base de données inaccessible
```bash
kubectl logs deployment/postgres -n tastmanagement
kubectl exec -it deployment/postgres -n tastmanagement -- pg_isready
```

### Pipeline échoue
```bash
# Vérifier les secrets GitHub
# Settings > Secrets and variables > Actions
# GHCR_TOKEN doit être configuré
```

---

## 📱 URLs Importantes

- **Application** : http://localhost:8000
- **Admin Django** : http://localhost:8000/admin/
- **GitHub Actions** : https://github.com/BadraAlou/task-management-cicd/actions
- **GitHub Packages** : https://github.com/BadraAlou/task-management-cicd/pkgs/container/task-management-cicd

---

## 🆘 Support Rapide

**Problème urgent ?** Utilisez ces commandes :

```bash
# Logs d'urgence
kubectl logs deployment/tastmanagement-app -n tastmanagement --since=1h > logs.txt

# Sauvegarde d'urgence
kubectl exec deployment/postgres -n tastmanagement -- pg_dump -U tastuser tastmanagement > backup.sql

# Rollback d'urgence
kubectl rollout undo deployment/tastmanagement-app -n tastmanagement

# Arrêt d'urgence
kubectl scale deployment tastmanagement-app --replicas=0 -n tastmanagement
```

**📚 Documentation complète** : [ADMINISTRATION.md](./ADMINISTRATION.md)
