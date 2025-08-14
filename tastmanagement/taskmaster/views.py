from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    """
    Vue pour la page d'accueil personnalisée
    """
    context = {
        'title': 'TastManagement - Bienvenue',
        'app_name': 'TastManagement',
        'description': 'Application de gestion des tâches avec pipeline CI/CD',
        'features': [
            'Pipeline CI/CD automatisée avec GitHub Actions',
            'Déploiement Kubernetes avec ArgoCD',
            'Base de données PostgreSQL',
            'Interface moderne et responsive'
        ]
    }
    return render(request, 'taskmaster/home.html', context)
