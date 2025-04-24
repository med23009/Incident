from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import status
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from rest_framework import permissions

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = "email"
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Ajoute des champs personnalisés au token si besoin
        return token

    def validate(self, attrs):
        print('DEBUG attrs reçus:', attrs)
        email = attrs.get("email") or attrs.get("username")
        password = attrs.get("password")
        if not email or not password:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'detail': 'Email et mot de passe requis.'})
        User = get_user_model()
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'detail': 'Identifiants invalides.'})
        if not user.check_password(password):
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'detail': 'Identifiants invalides.'})
        # Authentification strictement par email
        data = super().validate({"email": user.email, "password": password})
        return data

from rest_framework_simplejwt.views import TokenObtainPairView
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [permissions.AllowAny]
