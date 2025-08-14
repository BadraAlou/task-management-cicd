from django.urls import path
from . import views

app_name = 'taskmaster'

urlpatterns = [
    path('', views.home, name='home'),
]
