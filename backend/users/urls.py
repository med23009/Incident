from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views
from .views import CustomTokenObtainPairView

urlpatterns = [
    # Endpoint de login (retourne access + refresh token)
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),

    # Endpoint pour rafraîchir le token d'accès
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Endpoint d'enregistrement (création de compte)
    path('register/', views.RegisterView.as_view(), name='register'),
]
