from rest_framework import serializers
from .models import Incident, IncidentImage

class IncidentImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = IncidentImage
        fields = ['id', 'image']

class IncidentSerializer(serializers.ModelSerializer):
    images = IncidentImageSerializer(many=True, read_only=True)

    class Meta:
        model = Incident
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'images']