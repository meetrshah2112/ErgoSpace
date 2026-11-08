from rest_framework import serializers
from .models import WorkspaceBooking,WorkspaceCapacity
from users.serializers import UserSerializer
from users.models import User
from workspaces.serializers import WorkspaceCapacitySerializer,WorkspaceSerializer
from django.conf import settings
import razorpay
from rest_framework_gis.serializers import GeoFeatureModelSerializer 


class WorkspaceBookingSerializer(serializers.ModelSerializer):
    booked_by = UserSerializer(read_only=True)
    owner =   serializers.SerializerMethodField()
    # seat = serializers.PrimaryKeyRelatedField(queryset=WorkspaceCapacity.objects.all())
    seat_details = WorkspaceCapacitySerializer(source='seat',read_only=True)
    class Meta:
        model = WorkspaceBooking
        fields = '__all__'
        read_only_fields = ['amount','order_id','status','payment_id','signature_id']

    def create(self, validated_data):
        validated_data['booked_by'] = self.context['request'].user
        return super().create(validated_data)
    
    def get_owner(self,obj):
        return {
            "id":obj.seat.workspace.owner.id,
            "name":f"{obj.seat.workspace.owner.first_name} {obj.seat.workspace.owner.last_name}",
            "email":obj.seat.workspace.owner.email,
        }

    def get_workspace(self,obj):
        return{
            "id" : obj.seat.workspace.id,
            "name": obj.seat.workspace.name,
            "description" : obj.seat.workspace.description,
            "location":{
                "Latitude":obj.seat.workspace.location.y,
                "Longitude":obj.seat.workspace.location.x,
            },
            "start_time":obj.seat.workspace.start_time,
            "end_time":obj.seat.workspace.end_time,
            "address_1":obj.seat.workspace.address_1,
            "address_2":obj.seat.workspace.address_2,
            "address_1":obj.seat.workspace.address_1,
            "city":obj.seat.workspace.city,
            "state":obj.seat.workspace.state,
            "country":obj.seat.workspace.country,   
        }
    

