from django.shortcuts import render
from rest_framework import generics
from rest_framework.views import APIView
from .models import Workspace,WorkspaceFacilities,WorkspaceReviews
from .serializers import WorkspaceSerializer,WorkspaceFacilitiesSerializer,WorkspaceLimitedDataSerializer,PostReviewSerializer
from rest_framework.parsers import MultiPartParser, FormParser
from users.permissions import IsProviderPermission,IsCustomerPermission,IsOwner
from rest_framework.permissions import IsAuthenticated
from users.authentication import CustomTokenAuthentication
from rest_framework.response import Response
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from .filters import WorkspaceFilter
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter

# Create your views here.

'''this api view will give list of amenties and will create amenties'''
class WorkspaceDetailedListCreateView(generics.ListCreateAPIView):
    queryset = Workspace.objects.all()
    parser_class = [MultiPartParser, FormParser]
    serializer_class = WorkspaceSerializer
    permission_classes = [IsAuthenticated,IsProviderPermission,IsOwner]

    def get_queryset(self,*args,**kwargs):
        qs =  super().get_queryset(*args,**kwargs)
        request = self.request
        user = request.user
        if user.user_type == 'provider':
            return qs.filter(owner=user)
        return qs
    



'''this api view is to retrive data of a single instance of workspace'''
class WorkspaceDetailedRetriveView(generics.RetrieveAPIView):
    queryset = Workspace.objects.all()
    serializer_class = WorkspaceSerializer

    def get_queryset(self,*args,**kwargs):
        qs =  super().get_queryset(*args,**kwargs)
        request = self.request
        user = request.user
        if user.user_type == 'provider':
            return qs.filter(owner=user)
        return qs


class WorkspaceLimitedListView(generics.ListAPIView):
    queryset = Workspace.objects.all()
    serializer_class = WorkspaceLimitedDataSerializer

    def get_queryset(self,*args,**kwargs):
        qs =  super().get_queryset(*args,**kwargs)
        request = self.request
        user = request.user
        if user.user_type == 'provider':
            return qs.filter(owner=user)
        return qs


'''this api view will give list of amenities'''
class WorkspaceFacilitiesGetView(generics.ListAPIView):
    queryset = WorkspaceFacilities.objects.all()
    serializer_class = WorkspaceFacilitiesSerializer



class WorkspaceSearchView(generics.ListAPIView):
    queryset = Workspace.objects.all()
    serializer_class = WorkspaceLimitedDataSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_class = WorkspaceFilter
    # search_fields = ['name', 'city', 'state', 'address_1','address_2','country','description'] 


class WorkspaceUpdateView(generics.UpdateAPIView):
    queryset = Workspace.objects.all()
    serializer_class = WorkspaceSerializer
    permission_classes = [IsAuthenticated,IsProviderPermission,IsOwner]
    
    def get_serializer(self, *args, **kwargs):
        kwargs['partial'] = True
        return super().get_serializer(*args, **kwargs)

class WorkspaceDeleteView(generics.DestroyAPIView):
    queryset = Workspace.objects.all()
    serializer_class = WorkspaceSerializer
    permission_classes = [IsAuthenticated,IsProviderPermission,IsOwner]

    def get_queryset(self, *args, **kwargs):
        qs = super().get_queryset(*args, **kwargs)
        user = self.request.user
        if user.user_type == 'provider':
            return qs.filter(owner=user)
        return qs
    
class PostReviewView(generics.ListCreateAPIView):
    queryset = WorkspaceReviews.objects.all()
    serializer_class = PostReviewSerializer
    permission_classes = [IsAuthenticated,IsCustomerPermission]

    def get_queryset(self):
        qs =  super().get_queryset()
        user = self.request.user
        return qs.filter(by_user_id=user.id)

class ReviewDeleteView(generics.DestroyAPIView):
    queryset = WorkspaceReviews.objects.all()
    serializer_class = PostReviewSerializer
    permission_classes = [IsAuthenticated,IsCustomerPermission,IsOwner]
