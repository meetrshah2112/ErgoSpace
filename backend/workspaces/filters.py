# filters.py
import django_filters
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from .models import Workspace,WorkspaceFacilities
from django.db.models import Q

class WorkspaceFilter(django_filters.FilterSet):
    lat = django_filters.NumberFilter(method='filter_by_location')
    lon = django_filters.NumberFilter(method='filter_by_location')
    amenities = django_filters.ModelMultipleChoiceFilter(
        field_name='amenities',
        to_field_name='id',
        queryset=WorkspaceFacilities.objects.all(),
        conjoined=True  # ensures all selected amenities are required
    )

    type  = django_filters.CharFilter(method='filter_by_type')

    search = django_filters.CharFilter(method='filter_by_keyword')

    class Meta:
        model = Workspace
        fields = ['lat', 'lon', 'amenities','search','type']

    def filter_by_location(self, queryset, name, value):
        lat = self.data.get('lat')
        lon = self.data.get('lon')
        if lat and lon:
            user_location = Point(float(lon), float(lat), srid=4326)
            return queryset.filter(location__distance_lte=(user_location, 10000))\
                           .annotate(distance=Distance('location', user_location))\
                           .order_by('distance')
        return queryset
    
    def filter_by_keyword(self, queryset, name, value):
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value) |
            # Q(address_1__icontains=value) |
            Q(city__icontains=value)
        )
    
    def filter_by_type(self,queryset,name,value):
        return queryset.filter(
            Q(workspace_type__icontains=value)
        )
