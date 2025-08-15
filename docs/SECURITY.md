# 🔒 Guide de Sécurité - TastManagement CI/CD

## 🎯 Vue d'Ensemble de la Sécurité

Ce guide couvre tous les aspects de sécurité pour l'application TastManagement, depuis le développement jusqu'à la production, en passant par la pipeline CI/CD et l'infrastructure Kubernetes.

---

## 🏗️ Architecture de Sécurité

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │───▶│   GitHub Repo   │───▶│ GitHub Actions  │
│   (2FA + GPG)   │    │  (Branch Prot.) │    │ (Secrets Vault) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ArgoCD        │◀───│   Kubernetes    │◀───│     GHCR        │
│   (RBAC + TLS)  │    │ (RBAC + NetPol) │    │ (Private Reg.)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   PostgreSQL    │
                       │ (Encrypted DB)  │
                       └─────────────────┘
```

---

## 🔐 Gestion des Secrets

### 1. Secrets Kubernetes

#### Création Sécurisée
```bash
# Génération de secrets forts
SECRET_KEY=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 32)

# Création du secret
kubectl create secret generic tastmanagement-secret \
  --from-literal=SECRET_KEY="$SECRET_KEY" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  -n tastmanagement
```

#### Chiffrement au Repos
```yaml
# encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <base64-encoded-32-byte-key>
  - identity: {}
```

#### Rotation des Secrets
```bash
#!/bin/bash
# rotate-secrets.sh
NEW_SECRET_KEY=$(openssl rand -base64 32)
NEW_DB_PASSWORD=$(openssl rand -base64 16)

# Mise à jour du secret
kubectl patch secret tastmanagement-secret -n tastmanagement \
  -p='{"data":{"SECRET_KEY":"'$(echo -n $NEW_SECRET_KEY | base64)'"}}'

# Redémarrage pour appliquer
kubectl rollout restart deployment/tastmanagement-app -n tastmanagement
```

### 2. Secrets GitHub Actions

#### Configuration Recommandée
```bash
# Repository Secrets (Settings > Secrets and variables > Actions)
GHCR_TOKEN=<github_personal_access_token>  # Permissions: packages:write
DB_PASSWORD=<database_password>
SECRET_KEY=<django_secret_key>

# Environment Secrets (pour production)
PROD_DB_HOST=<production_database_host>
PROD_SECRET_KEY=<production_secret_key>
```

#### Token GitHub Sécurisé
```bash
# Permissions minimales requises
- contents:read
- packages:write
- actions:read

# Expiration recommandée : 90 jours maximum
# Régénération automatique conseillée
```

---

## 🛡️ Sécurité de l'Application Django

### 1. Configuration de Production

```python
# settings_prod.py - Configuration sécurisée
import os
from decouple import config

# Sécurité de base
DEBUG = False
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# Sécurité HTTPS
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS = 31536000  # 1 an
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Cookies sécurisés
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Strict'
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Strict'

# Headers de sécurité
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

# Content Security Policy
CSP_DEFAULT_SRC = ("'self'",)
CSP_SCRIPT_SRC = ("'self'", "'unsafe-inline'")
CSP_STYLE_SRC = ("'self'", "'unsafe-inline'")
CSP_IMG_SRC = ("'self'", "data:", "https:")
CSP_FONT_SRC = ("'self'",)

# Logging sécurisé
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'security': {
            'format': '{asctime} {levelname} {name} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'security_file': {
            'level': 'WARNING',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/django/security.log',
            'maxBytes': 1024*1024*15,  # 15MB
            'backupCount': 10,
            'formatter': 'security',
        },
    },
    'loggers': {
        'django.security': {
            'handlers': ['security_file'],
            'level': 'WARNING',
            'propagate': True,
        },
    },
}
```

### 2. Validation et Sanitisation

```python
# validators.py
import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

def validate_secure_password(password):
    """Validation de mot de passe sécurisé"""
    if len(password) < 12:
        raise ValidationError(_('Le mot de passe doit contenir au moins 12 caractères.'))
    
    if not re.search(r'[A-Z]', password):
        raise ValidationError(_('Le mot de passe doit contenir au moins une majuscule.'))
    
    if not re.search(r'[a-z]', password):
        raise ValidationError(_('Le mot de passe doit contenir au moins une minuscule.'))
    
    if not re.search(r'\d', password):
        raise ValidationError(_('Le mot de passe doit contenir au moins un chiffre.'))
    
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise ValidationError(_('Le mot de passe doit contenir au moins un caractère spécial.'))

def sanitize_input(value):
    """Sanitisation des entrées utilisateur"""
    import html
    import bleach
    
    # Échapper les caractères HTML
    value = html.escape(value)
    
    # Nettoyer avec bleach
    allowed_tags = ['b', 'i', 'u', 'em', 'strong']
    value = bleach.clean(value, tags=allowed_tags, strip=True)
    
    return value
```

### 3. Protection CSRF et XSS

```python
# middleware.py
from django.middleware.csrf import CsrfViewMiddleware
from django.http import HttpResponseForbidden

class SecurityHeadersMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        
        # Headers de sécurité
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
        
        return response

# views.py
from django.views.decorators.csrf import csrf_protect
from django.utils.decorators import method_decorator

@method_decorator(csrf_protect, name='dispatch')
class SecureView(View):
    def post(self, request):
        # Validation CSRF automatique
        data = sanitize_input(request.POST.get('data', ''))
        # Traitement sécurisé...
```

---

## ☸️ Sécurité Kubernetes

### 1. RBAC (Role-Based Access Control)

```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tastmanagement-sa
  namespace: tastmanagement

---
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
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tastmanagement-binding
  namespace: tastmanagement
subjects:
- kind: ServiceAccount
  name: tastmanagement-sa
  namespace: tastmanagement
roleRef:
  kind: Role
  name: tastmanagement-role
  apiGroup: rbac.authorization.k8s.io
```

### 2. Network Policies

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
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to: []  # DNS
    ports:
    - protocol: UDP
      port: 53

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-netpol
  namespace: tastmanagement
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: tastmanagement-app
    ports:
    - protocol: TCP
      port: 5432
```

### 3. Pod Security Standards

```yaml
# pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: tastmanagement-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### 4. Security Context

```yaml
# deployment.yaml (extrait)
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      serviceAccountName: tastmanagement-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: tastmanagement
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-log
          mountPath: /var/log
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-log
        emptyDir: {}
```

---

## 🐳 Sécurité Docker

### 1. Dockerfile Sécurisé

```dockerfile
# Dockerfile sécurisé
FROM python:3.11-slim

# Créer un utilisateur non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Mise à jour sécurisée
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Répertoire de travail
WORKDIR /app

# Copier et installer les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir gunicorn

# Copier le code source
COPY . .

# Créer répertoires nécessaires
RUN mkdir -p /app/staticfiles /app/logs \
    && chown -R appuser:appuser /app

# Passer à l'utilisateur non-root
USER appuser

# Variables d'environnement sécurisées
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=tastmanagement.settings_prod

# Port non-privilégié
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Commande de démarrage
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120", "tastmanagement.wsgi:application"]
```

### 2. Scan de Sécurité

```bash
# Scan avec Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image ghcr.io/badraalou/task-management-cicd:latest

# Scan avec Clair
docker run -d --name clair-db arminc/clair-db:latest
docker run -p 6060:6060 --link clair-db:postgres -d --name clair arminc/clair-local-scan:latest
```

### 3. Image Signing

```bash
# Signature avec Cosign
cosign generate-key-pair
cosign sign --key cosign.key ghcr.io/badraalou/task-management-cicd:latest

# Vérification
cosign verify --key cosign.pub ghcr.io/badraalou/task-management-cicd:latest
```

---

## 🔒 Sécurité Base de Données

### 1. Configuration PostgreSQL

```sql
-- Configuration sécurisée PostgreSQL
-- postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'ca.crt'
ssl_crl_file = 'server.crl'

-- Chiffrement des connexions
ssl_min_protocol_version = 'TLSv1.2'
ssl_max_protocol_version = 'TLSv1.3'

-- Logging sécurisé
log_connections = on
log_disconnections = on
log_statement = 'mod'
log_min_duration_statement = 1000

-- Authentification
password_encryption = scram-sha-256
```

### 2. Utilisateurs et Permissions

```sql
-- Création d'utilisateurs avec permissions minimales
CREATE USER tastapp WITH PASSWORD 'secure_password';
CREATE DATABASE tastmanagement OWNER tastapp;

-- Permissions minimales
GRANT CONNECT ON DATABASE tastmanagement TO tastapp;
GRANT USAGE ON SCHEMA public TO tastapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO tastapp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO tastapp;

-- Révocation des permissions par défaut
REVOKE ALL ON SCHEMA public FROM public;
REVOKE CREATE ON SCHEMA public FROM public;
```

### 3. Chiffrement des Données

```sql
-- Extension de chiffrement
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Chiffrement des données sensibles
CREATE TABLE users_secure (
    id SERIAL PRIMARY KEY,
    username VARCHAR(150) NOT NULL,
    email_encrypted BYTEA,
    phone_encrypted BYTEA
);

-- Fonctions de chiffrement/déchiffrement
CREATE OR REPLACE FUNCTION encrypt_data(data TEXT, key TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, key);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrypt_data(encrypted_data BYTEA, key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(encrypted_data, key);
END;
$$ LANGUAGE plpgsql;
```

---

## 🚨 Monitoring de Sécurité

### 1. Logs de Sécurité

```yaml
# fluentd-security.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-security-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*tastmanagement*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
      time_key time
      time_format %Y-%m-%dT%H:%M:%S.%NZ
    </source>
    
    <filter kubernetes.**>
      @type grep
      <regexp>
        key log
        pattern (ERROR|CRITICAL|security|authentication|authorization)
      </regexp>
    </filter>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      index_name security-logs
    </match>
```

### 2. Alertes de Sécurité

```yaml
# prometheus-security-rules.yaml
groups:
- name: security
  rules:
  - alert: HighFailedLogins
    expr: rate(django_login_failures_total[5m]) > 10
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Taux élevé d'échecs de connexion"
      
  - alert: SuspiciousActivity
    expr: rate(django_security_events_total[5m]) > 5
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Activité suspecte détectée"
      
  - alert: UnauthorizedAccess
    expr: rate(kubernetes_audit_unauthorized_total[5m]) > 1
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Tentative d'accès non autorisé"
```

### 3. Audit Kubernetes

```yaml
# audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  namespaces: ["tastmanagement"]
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  - group: "apps"
    resources: ["deployments"]
    
- level: Request
  namespaces: ["tastmanagement"]
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings"]
```

---

## 🔧 Tests de Sécurité

### 1. Tests Automatisés

```python
# tests/test_security.py
import unittest
from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse

class SecurityTestCase(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            password='securepassword123!'
        )

    def test_csrf_protection(self):
        """Test protection CSRF"""
        response = self.client.post('/admin/login/', {
            'username': 'testuser',
            'password': 'securepassword123!'
        })
        self.assertEqual(response.status_code, 403)  # CSRF token manquant

    def test_xss_protection(self):
        """Test protection XSS"""
        malicious_script = '<script>alert("XSS")</script>'
        response = self.client.post('/search/', {
            'q': malicious_script
        })
        self.assertNotContains(response, '<script>')

    def test_sql_injection_protection(self):
        """Test protection injection SQL"""
        malicious_query = "'; DROP TABLE users; --"
        response = self.client.get('/users/', {
            'search': malicious_query
        })
        self.assertEqual(response.status_code, 200)
        # Vérifier que la table existe toujours
        self.assertTrue(User.objects.exists())

    def test_security_headers(self):
        """Test headers de sécurité"""
        response = self.client.get('/')
        self.assertIn('X-Content-Type-Options', response)
        self.assertIn('X-Frame-Options', response)
        self.assertIn('X-XSS-Protection', response)
```

### 2. Tests de Pénétration

```bash
#!/bin/bash
# penetration-test.sh

echo "🔍 Tests de pénétration automatisés"

# Test OWASP ZAP
docker run -t owasp/zap2docker-stable zap-baseline.py \
    -t http://localhost:8000 \
    -J zap-report.json

# Test Nikto
docker run --rm sullo/nikto \
    -h http://localhost:8000 \
    -output nikto-report.txt

# Test SSL/TLS
docker run --rm drwetter/testssl.sh \
    --jsonfile ssl-report.json \
    localhost:8000

# Test des ports
nmap -sS -O localhost

echo "✅ Tests terminés - Vérifiez les rapports"
```

### 3. Audit de Code

```bash
# Audit avec Bandit (Python)
bandit -r . -f json -o bandit-report.json

# Audit avec Safety (dépendances Python)
safety check --json --output safety-report.json

# Audit avec Semgrep
semgrep --config=auto --json --output=semgrep-report.json .

# Audit Docker avec Hadolint
hadolint Dockerfile > hadolint-report.txt
```

---

## 📋 Checklist de Sécurité

### Développement
- [ ] Validation et sanitisation des entrées
- [ ] Protection CSRF activée
- [ ] Headers de sécurité configurés
- [ ] Secrets non hardcodés
- [ ] Tests de sécurité automatisés
- [ ] Audit de code régulier

### Infrastructure
- [ ] RBAC configuré
- [ ] Network Policies appliquées
- [ ] Secrets chiffrés au repos
- [ ] Images scannées
- [ ] Utilisateurs non-root
- [ ] Monitoring de sécurité

### Base de Données
- [ ] Chiffrement en transit (SSL/TLS)
- [ ] Utilisateurs avec permissions minimales
- [ ] Logs d'audit activés
- [ ] Sauvegardes chiffrées
- [ ] Accès réseau restreint

### CI/CD
- [ ] Branch protection activée
- [ ] Secrets sécurisés
- [ ] Scan d'images automatique
- [ ] Tests de sécurité dans pipeline
- [ ] Signature d'images
- [ ] Audit des déploiements

---

## 🆘 Réponse aux Incidents

### 1. Procédure d'Urgence

```bash
#!/bin/bash
# incident-response.sh

echo "🚨 RÉPONSE À INCIDENT DE SÉCURITÉ"

# 1. Isolation immédiate
kubectl scale deployment tastmanagement-app --replicas=0 -n tastmanagement
echo "✅ Application isolée"

# 2. Sauvegarde des preuves
kubectl logs deployment/tastmanagement-app -n tastmanagement > incident-logs-$(date +%Y%m%d-%H%M%S).log
kubectl get events -n tastmanagement > incident-events-$(date +%Y%m%d-%H%M%S).log

# 3. Notification
curl -X POST https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK \
    -H 'Content-type: application/json' \
    --data '{"text":"🚨 INCIDENT DE SÉCURITÉ DÉTECTÉ - Application isolée"}'

# 4. Analyse forensique
docker run --rm -v $(pwd):/data alpine/git clone https://github.com/your-org/incident-toolkit.git /data/toolkit

echo "🔍 Incident documenté - Démarrer l'analyse forensique"
```

### 2. Communication de Crise

```markdown
# Template de Communication d'Incident

## INCIDENT DE SÉCURITÉ - [NIVEAU]

**Date/Heure** : [TIMESTAMP]
**Détecté par** : [SYSTÈME/PERSONNE]
**Impact** : [DESCRIPTION]

### Actions Immédiates
- [ ] Application isolée
- [ ] Preuves sauvegardées
- [ ] Équipe sécurité notifiée
- [ ] Investigation démarrée

### Prochaines Étapes
- [ ] Analyse forensique
- [ ] Correction des vulnérabilités
- [ ] Tests de sécurité
- [ ] Redéploiement sécurisé

### Communication
- [ ] Équipe technique informée
- [ ] Management notifié
- [ ] Clients informés (si nécessaire)
- [ ] Autorités contactées (si requis)
```

---

## 📚 Ressources et Formation

### Documentation de Référence
- **OWASP Top 10** : https://owasp.org/www-project-top-ten/
- **CIS Kubernetes Benchmark** : https://www.cisecurity.org/benchmark/kubernetes
- **NIST Cybersecurity Framework** : https://www.nist.gov/cyberframework
- **Django Security** : https://docs.djangoproject.com/en/stable/topics/security/

### Outils Recommandés
- **Scanning** : Trivy, Clair, Snyk
- **SAST** : Bandit, Semgrep, SonarQube
- **DAST** : OWASP ZAP, Burp Suite
- **Monitoring** : Falco, Prometheus, Grafana

### Formation Continue
- Certification CKS (Certified Kubernetes Security Specialist)
- Formation OWASP
- Veille sécurité CVE/NVD
- Exercices de simulation d'incidents

---

**🔒 La sécurité est un processus continu. Cette documentation doit être mise à jour régulièrement et les pratiques adaptées aux nouvelles menaces.**
