from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Incident
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

class IncidentBatchCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = IncidentSerializer(data=request.data, many=True)
        serializer.is_valid(raise_exception=True)
        for incident_data in serializer.validated_data:
            Incident.objects.create(user=request.user, **incident_data)
        return Response({'status': 'batch incidents created'}, status=status.HTTP_201_CREATED)

class IncidentListCreateView(generics.ListCreateAPIView):
    queryset = Incident.objects.all().order_by('-created_at')
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        incident = serializer.save(user=self.request.user)
        images = self.request.FILES.getlist('images')
        for img in images:
            IncidentImage.objects.create(incident=incident, image=img)