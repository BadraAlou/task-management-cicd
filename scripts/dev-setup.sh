#!/bin/bash

# Script de configuration pour le développement local

set -e

echo "🔧 Configuration de l'environnement de développement..."

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier que Docker Compose est installé
#if ! command -v docker-compose &> /dev/null; then
if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Construire et démarrer les services
echo "🏗️  Construction des images Docker..."
docker compose build

echo "🚀 Démarrage des services..."
docker compose up -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 10

# Exécuter les migrations Django
echo "🗄️  Exécution des migrations Django..."
docker compose exec web python manage.py migrate

# Créer un superutilisateur (optionnel)
echo "👤 Création d'un superutilisateur Django..."
docker compose exec web python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superutilisateur créé: admin/admin123')
else:
    print('Superutilisateur existe déjà')
"

# Afficher les informations de connexion
echo "✅ Environnement de développement prêt!"
echo "📋 Informations:"
echo "   Application: http://localhost:8000"
echo "   Admin Django: http://localhost:8000/admin"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "🔧 Commandes utiles:"
echo "   docker-compose logs -f web    # Voir les logs"
echo "   docker-compose down           # Arrêter les services"
echo "   docker-compose up -d          # Redémarrer les services"
