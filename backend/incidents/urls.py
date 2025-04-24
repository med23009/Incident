from django.urls import path
from .views import (
    IncidentListCreateView,
    IncidentRetrieveView,
    IncidentBatchCreateView,
)

urlpatterns = [
    path('', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('<int:pk>/', IncidentRetrieveView.as_view(), name='incident-detail'),
    path('batch/', IncidentBatchCreateView.as_view(), name='incident-batch-create'),
]
