
from django.urls import path
from . import views

urlpatterns = [
        path('', views.get_all_breaches, name = 'all'),
        path('<int:breach_id>/', views.detail, name = 'detail'),
#        path('<>'),
        path('<str:state>/state/', views.breaches_by_state, name = 'state'),
        ]
