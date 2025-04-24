from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from .models import User

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = "email"

    def validate(self, attrs):
        email = attrs.get("email")
        password = attrs.get("password")

        if not email or not password:
            raise serializers.ValidationError({'detail': 'Email et mot de passe requis.'})

        User = get_user_model()
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError({'detail': 'Identifiants invalides.'})

        if not user.check_password(password):
            raise serializers.ValidationError({'detail': 'Identifiants invalides.'})

        if not user.is_active:
            raise serializers.ValidationError({'detail': 'Ce compte est désactivé.'})

        refresh = self.get_token(user)
        access = refresh.access_token

        return {
            'refresh': str(refresh),
            'access': str(access),
            'user_id': user.id,
            'email': user.email,
            'role': user.role
        }

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'role', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(
            email=validated_data['email'],
            role=validated_data.get('role', 'citizen'),
            username=validated_data['email']  # pour compatibilité Django
        )
        user.set_password(password)
        user.is_active = True
        user.save()
        return user

    def validate(self, data):
        if not data.get('email'):
            raise serializers.ValidationError({'email': 'Email obligatoire.'})
        if not data.get('password'):
            raise serializers.ValidationError({'password': 'Mot de passe obligatoire.'})
        return data
