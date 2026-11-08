from django.urls import path
from . import views

urlpatterns = [
    path('',views.WorkspaceLimitedListView.as_view(http_method_names=['get']),name='workspace-list'),
    path('new-workspace/',views.WorkspaceDetailedListCreateView.as_view(),name='workspace-create-list'),
    path('amenities/',views.WorkspaceFacilitiesGetView.as_view(),name='amenities-get'),
    path('<int:pk>/',views.WorkspaceDetailedRetriveView.as_view(),name='workspace-detailed'),
    path('search/',views.WorkspaceSearchView.as_view(),name='search'),
    path('<int:pk>/delete/',views.WorkspaceDeleteView.as_view(),name='workspace-delete'),
    path('<int:pk>/update/',views.WorkspaceUpdateView.as_view(),name='workspace-update'),
    path('reviews/',views.PostReviewView.as_view(),name='post-review'),
    path('reviews/<int:pk>/delete/',views.ReviewDeleteView.as_view(),name='post-delete'),
]