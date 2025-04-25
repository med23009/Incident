from rest_framework import generics, permissions, status, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Incident, IncidentImage
from .serializers import IncidentSerializer

class IncidentListCreateView(generics.ListCreateAPIView):
    queryset = Incident.objects.all().order_by('-created_at')
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def get_queryset(self):
        # Historique des incidents signalés par l'utilisateur connecté
        return Incident.objects.filter(user=self.request.user).order_by('-created_at')
class IncidentRetrieveView(generics.RetrieveAPIView):
    queryset = Incident.objects.all()
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]


class IncidentListCreateView(generics.ListCreateAPIView):
    queryset = Incident.objects.all().order_by('-created_at')
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # DEBUG: Afficher les headers pour vérifier Authorization
        print('HEADERS:', self.request.headers)
        print('HTTP_AUTHORIZATION:', self.request.META.get('HTTP_AUTHORIZATION'))
        print('auth_token (via champs formulaire):', self.request.data.get('auth_token'))
        # Validation des champs obligatoires
        data = self.request.data
        required_fields = ['type', 'latitude', 'longitude']
        for field in required_fields:
            if not data.get(field):
                raise serializers.ValidationError({field: 'Ce champ est obligatoire.'})
        # Création de l'incident
        incident = serializer.save(user=self.request.user)
        # Gestion des images
        images = self.request.FILES.getlist('images')
        for img in images:
            IncidentImage.objects.create(incident=incident, image=img)
        # Gestion de l'audio
        audio = self.request.FILES.get('audio_description')
        if audio:
            incident.audio_description = audio
            incident.save()