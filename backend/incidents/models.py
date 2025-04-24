from django.db import models
from django.conf import settings

class Incident(models.Model):
    INCIDENT_TYPE_CHOICES = [
        ('fire', 'Incendie'),
        ('accident', 'Accident'),
        ('other', 'Autre'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='incidents')
    type = models.CharField(max_length=20, choices=INCIDENT_TYPE_CHOICES)
    description = models.TextField()
    audio_description = models.FileField(upload_to='incidents/audio/', null=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.type.title()} signalé par {self.user.username} le {self.created_at}"

class IncidentImage(models.Model):
    incident = models.ForeignKey(Incident, related_name='images', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='incidents/photos/')

    def __str__(self):
        return f"Image pour incident {self.incident.id}"