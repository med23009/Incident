from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework import status
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from rest_framework import permissions

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Ajoute des champs personnalisés au token si besoin
        return token

    def validate(self, attrs):
        # Remplacer username par email
        email = attrs.get("email")
        password = attrs.get("password")
        User = get_user_model()
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise self.error_messages["no_active_account"]
        if not user.check_password(password):
            raise self.error_messages["no_active_account"]
        data = super().validate({"username": user.username, "password": password})
        return data

from rest_framework_simplejwt.views import TokenObtainPairView
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [permissions.AllowAny]
