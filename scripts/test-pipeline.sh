#!/bin/bash

# Script de test pour valider la pipeline CI/CD

set -e

echo "🧪 Test de la pipeline CI/CD..."

# Test 1: Vérifier que Docker fonctionne
echo "1️⃣  Test Docker..."
if ! docker --version &> /dev/null; then
    echo "❌ Docker n'est pas installé ou ne fonctionne pas"
    exit 1
fi
echo "✅ Docker OK"

# Test 2: Build de l'image Docker
echo "2️⃣  Test du build Docker..."
docker build -t tastmanagement-test . || {
    echo "❌ Échec du build Docker"
    exit 1
}
echo "✅ Build Docker OK"

# Test 3: Vérifier les manifestes Kubernetes
echo "3️⃣  Test des manifestes Kubernetes..."
for file in k8s/*.yaml; do
    if ! kubectl apply --dry-run=client -f "$file" &> /dev/null; then
        echo "❌ Manifeste invalide: $file"
        exit 1
    fi
done
echo "✅ Manifestes Kubernetes OK"

# Test 4: Vérifier la syntaxe YAML
echo "4️⃣  Test de la syntaxe YAML..."
for file in k8s/*.yaml argocd/*.yaml .github/workflows/*.yml docker-compose.yml; do
    if [[ -f "$file" ]]; then
        python -c "import yaml; yaml.safe_load(open('$file'))" || {
            echo "❌ Syntaxe YAML invalide: $file"
            exit 1
        }
    fi
done
echo "✅ Syntaxe YAML OK"

# Test 5: Vérifier les scripts
echo "5️⃣  Test des scripts..."
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        bash -n "$script" || {
            echo "❌ Syntaxe bash invalide: $script"
            exit 1
        }
    fi
done
echo "✅ Scripts OK"

echo "🎉 Tous les tests passent! La pipeline est prête."
echo ""
echo "📋 Prochaines étapes:"
echo "1. Pusher le code vers GitHub"
echo "2. Configurer les secrets GitHub si nécessaire"
echo "3. Modifier les URLs dans les manifestes avec votre repository"
echo "4. Déployer sur votre cluster Kubernetes"
