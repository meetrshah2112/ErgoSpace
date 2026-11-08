from rest_framework import serializers
from .models import Workspace,WorkspacePhotos,WorkspaceFacilities,WorkspaceCapacity,WorkspaceReviews
from users.serializers import UserSerializer
from users.models import User
import json
from django.contrib.gis.geos import Point
from rest_framework_gis.serializers import GeoFeatureModelSerializer 

class WorkspacePhotosSerialzer(serializers.ModelSerializer):

    class Meta:
        model = WorkspacePhotos
        fields = '__all__'



class WorkspaceFacilitiesSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkspaceFacilities
        fields = '__all__'

class WorkspaceCapacitySerializer(serializers.ModelSerializer):

    class Meta:
        model = WorkspaceCapacity
        fields = '__all__'

class PostReviewSerializer(serializers.ModelSerializer):
    by_user = UserSerializer(read_only=True)
    class Meta:
        model = WorkspaceReviews
        fields = '__all__'
        read_only_fields = ['by_user']

    def create(self, validated_data):
        validated_data['by_user'] = self.context['request'].user
        return super().create(validated_data) 

class WorkspaceSerializer(serializers.ModelSerializer): #GeoFeatureModelSerializer
    owner = UserSerializer(read_only=True)
    images = WorkspacePhotosSerialzer(many=True,read_only=True)
    uploaded_images = serializers.ListField(
        child=serializers.ImageField(allow_empty_file=False,use_url=False),
        write_only=True,
        required = False,
    )
    amenities = WorkspaceFacilitiesSerializer(many=True,read_only=True)

    capacity = WorkspaceCapacitySerializer(many=True,read_only=True)

    latitude = serializers.FloatField(write_only=True,required=False)
    longitude = serializers.FloatField(write_only=True,required=False)
    
    reviews = PostReviewSerializer(many=True,read_only=True)

    class Meta:
        model = Workspace
        fields = '__all__'
        # geo_field = "location"
        read_only_fields = ['owner','location']

    def create(self, validated_data):
        lat = validated_data.pop('latitude')
        lon = validated_data.pop('longitude')
        uploaded_images = validated_data.pop('uploaded_images', [])
        validated_data['owner'] = self.context['request'].user
        amenities_data = validated_data.pop('amenities', [])
        capacity_data = self.initial_data.get('capacity')
        validated_data['location'] = Point(lon, lat)
        Workspaces = Workspace.objects.create(**validated_data)


        ''' this thing is done becoz we are also sending photos with the request so drf cant parse
        the json , so we are manually parsing the json for amenties'''
        amenities_data = self.initial_data.get('amenities')
        if isinstance(amenities_data, str):
            amenities_data = json.loads(amenities_data)
        elif not amenities_data:
            amenities_data = []

        '''this is to store the instances of amenties if it is not there'''

        amenity_instance = []
        for amenity in amenities_data:
            name = str(amenity.get('name', '')).strip()
            if not name:
                continue
            obj,created = WorkspaceFacilities.objects.get_or_create(name=name)
            amenity_instance.append(obj)

        '''this  is  to set the amenities in the workspace'''

        Workspaces.amenities.set(amenity_instance)  # Set M2M data
        
        if isinstance(capacity_data,str):
            capacity_data = json.loads(capacity_data)
        elif not capacity_data:
            capacity_data = []


        request = self.context['request']
        for idx, capacity in enumerate(capacity_data):
            capacity.pop('image', None)
            WorkspaceCapacity.objects.create(
                workspace=Workspaces,
                image=request.FILES.get(f'capacity_image_{idx}'),
                **capacity,
            )
        


        for image in uploaded_images:
            WorkspacePhotos.objects.create(workspace=Workspaces, gallery=image)

        return Workspaces  
    
    def update(self, instance, validated_data):
        request = self.context.get('request')

        # Handle and remove non-model fields
        uploaded_images = validated_data.pop('uploaded_images', None)
        latitude = validated_data.pop('latitude', None)
        longitude = validated_data.pop('longitude', None)

        # Update basic model fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # Update location if lat/lon provided
        if latitude is not None and longitude is not None:
            instance.location = Point(longitude, latitude)

        instance.save()

        # Handle uploaded_images
        if uploaded_images:
            # Optionally clear previous images
            WorkspacePhotos.objects.filter(workspace=instance).delete()
            for image in uploaded_images:
                WorkspacePhotos.objects.create(workspace=instance, gallery=image)

        # Handle amenities
        amenities_data = request.data.get('amenities')
        if amenities_data:
            if isinstance(amenities_data, str):
                amenities_data = json.loads(amenities_data)
            amenity_instances = []
            for amenity in amenities_data:
                obj, _ = WorkspaceFacilities.objects.get_or_create(name=amenity['name'])
                amenity_instances.append(obj)
            instance.amenities.set(amenity_instances)

        # Handle capacity (clear old + recreate)
        capacity_data = request.data.get('capacity')
        if capacity_data:
            if isinstance(capacity_data, str):
                capacity_data = json.loads(capacity_data)

            # Clear old capacity records
            instance.capacity.all().delete()

            # Create new capacity records
            for idx, capacity in enumerate(capacity_data):
                capacity.pop('image', None)
                WorkspaceCapacity.objects.create(
                    workspace=instance,
                    image=request.FILES.get(f'capacity_image_{idx}'),
                    **capacity,
                )

        return instance

        

class WorkspaceLimitedDataSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    amenities = WorkspaceFacilitiesSerializer(many=True,read_only=True)
    distance = serializers.SerializerMethodField()
    capacity = WorkspaceCapacitySerializer(many=True, read_only=True)
    images = WorkspacePhotosSerialzer(many=True, read_only=True)
    rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()

    class Meta:
        model = Workspace
        fields = [
            'id',
            'name',
            'owner',
            'workspace_type',
            'description',
            'city',
            'location',
            'distance',
            'logo',
            'background',
            'images',
            'capacity',
            'rating',
            'review_count',
            'amenities',
        ]

    def get_rating(self, obj):
        ratings = [float(r.rating) for r in obj.reviews.all()]
        return round(sum(ratings) / len(ratings), 1) if ratings else None

    def get_review_count(self, obj):
        return obj.reviews.count()

    def get_distance(self, obj):
        if hasattr(obj, 'distance') and obj.distance:
            return round(obj.distance.km, 2)  # rounded to 2 decimal places
        return None



    