from django.urls import path
from . import views

urlpatterns = [
    path('create-booking/',views.WorkspaceBookingCreateView.as_view(),name='create-booking'),
    path('confirm-booking/',views.WorkspaceBookingConfirmView.as_view(),name='confirm-booking'),
    path('check-availability/',views.WorkspaceCheckAvailabilityAPIView.as_view(),name='check-availability'),
    path('mybookings/',views.MyBookings.as_view(),name='mybooking'),

]