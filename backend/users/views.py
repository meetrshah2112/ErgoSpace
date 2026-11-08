from django.shortcuts import render
from .serializers import UserRegisterSerializer,UserLoginSerializer,UserSerializer
from rest_framework import generics,status
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from .models import User
from rest_framework.permissions import AllowAny,IsAuthenticated
from .permissions import IsOwner
from django.contrib.auth import logout
from django.middleware.csrf import get_token
from django.conf import settings
# Create your views here.


'''
    User Register View
'''
class UserRegisterView(generics.CreateAPIView):

    serializer_class = UserRegisterSerializer
    permission_classes = [AllowAny]
    

'''
    User login view 
    this view takes email and password then authenticates with the database  data and then it creates a token
    which is then sent in thr response
'''
class UserLoginView(APIView):

    permission_classes = [AllowAny]

    def post(self,request):
        serializer = UserLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data
        token , created = Token.objects.get_or_create(user=user)
        response = Response({
            'Token':token.key,
            'Full_name':f"{user.first_name} {user.last_name}",
            'username': user.username,
            'user_type': user.user_type,
            'id': user.id,
        },status=status.HTTP_200_OK)
        response.set_cookie('Token', token.key, samesite=settings.COOKIE_SAMESITE, httponly=True, secure=settings.COOKIE_SECURE)
        response.set_cookie('csrftoken', get_token(request), httponly=False, secure=settings.COOKIE_SECURE, samesite=settings.COOKIE_SAMESITE)
        return response
    

''' 
    User Logout view
    this is the user logout view 
    here we are deleteing the token from the database token model
    we are also using django built in logout method which logs out session.
    we are returing the status 200 and loggedd out succesfully message
'''
class UserLogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self,request):
        try:
            request.user.auth_token.delete()
            logout(request)
            response = Response({'message':"User Logged out Successfully"},status=status.HTTP_200_OK)
            response.set_cookie('Token','', samesite=settings.COOKIE_SAMESITE, httponly=True, secure=settings.COOKIE_SECURE, expires='1970-01-01T00:00:00Z', max_age=0)
            # response.delete_cookie('Token')
        except:
            response = Response({"message":"Cant logout the User"},status=status.HTTP_404_NOT_FOUND)

        return response

        
class UserProfileView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated,IsOwner]

    def get_object(self):
        queryset = self.filter_queryset(self.get_queryset())
        obj = queryset.get(pk=self.request.user.id)
        self.check_object_permissions(self.request,obj)
        return obj


class UserProfileUpdateView(generics.UpdateAPIView):
    queryset=User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated,IsOwner] 

    def get_object(self):
        queryset = self.filter_queryset(self.get_queryset())
        obj = queryset.get(pk=self.request.user.id)
        self.check_object_permissions(self.request,obj)
        return obj

