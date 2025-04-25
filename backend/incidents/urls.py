from django.urls import path
from .views import (
    IncidentListCreateView,
    IncidentRetrieveView,
)

urlpatterns = [
    path('', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('<int:pk>/', IncidentRetrieveView.as_view(), name='incident-detail'),
]
