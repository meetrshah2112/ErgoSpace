from django.db import models
# from django.contrib.gis.db import models
from users.models import User
from django.contrib.gis.db import models as gis_models
# Create your models here.

class WorkspaceFacilities(models.Model):
    # workspace = models.ManyToManyField(Workspace,related_name='facilities')
    name = models.CharField(max_length=100,unique=True)
    def __str__(self):
        return f"{self.name}({self.id})"



'''
    This is the workspace models it stores the data abouut the workspaces and hotdesks both.
'''
class Workspace(models.Model):
    WORKSPACE_TYPE_CHOICES = {
        'Workspace' :'Workspace',
        'Hotdesk' : 'Hotdesk',
    }
    name = models.CharField(max_length=150)
    location = gis_models.PointField(srid=4326,blank=True,null=True)
    # latitude = models.DecimalField(max_digits=10,decimal_places=8,blank=True,null=True)
    # longitude = models.DecimalField(max_digits=11,decimal_places=8,null=True,blank=True)
    # point = models.PointField()
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    workspace_type = models.CharField(choices=WORKSPACE_TYPE_CHOICES,max_length=9)
    description = models.TextField(null=True,blank=True)
    address_1 = models.TextField(null=True,blank=True)
    address_2 = models.TextField(null=True,blank=True)
    pincode = models.IntegerField(null=True,blank=True)
    city = models.TextField(null=True,blank=True)
    state = models.TextField(null=True,blank=True)
    country = models.TextField(null=True,blank=True)
    start_time = models.TimeField(null=True,blank=True)
    end_time = models.TimeField(null=True,blank=True)
    insta = models.URLField(null=True,blank=True)
    facebook = models.URLField(null=True,blank=True)
    # rate_per_day = models.DecimalField(max_digits=15,decimal_places=2,null=True,blank=True)
    # rate_per_month = models.DecimalField(max_digits=15,decimal_places=2,null=True,blank=True)
    # rate_per_hour = models.DecimalField(max_digits=15,decimal_places=2,null=True,blank=True)
    logo = models.ImageField(default='logo.jpg',upload_to='workspace/logos/',null=True,blank=True)
    background = models.ImageField(default='background.jpg',upload_to='workspace/background/',null=True,blank=True)
    amenities = models.ManyToManyField(WorkspaceFacilities, blank=True, related_name='amenitiies')
    # created_at = models.DateTimeField(auto_now_add=True,blank=True)
    # updates_at = models.DateTimeField(auto_now=True,blank=True,null=True)

    def __str__(self):
        return "%s" % (self.name)


'''
    this model is to store the image gallery of the workspace
'''
class WorkspacePhotos(models.Model):
    workspace = models.ForeignKey(Workspace,on_delete=models.CASCADE,related_name='images')
    gallery = models.ImageField(upload_to='workspace/gallery/')

    def __str__(self):
        return "%s" % (self.workspace.name)
    
class WorkspaceCapacity(models.Model):
    workspace = models.ForeignKey(Workspace,on_delete=models.CASCADE,null=True,related_name='capacity')
    name =  models.CharField(max_length=200,default='workspace')
    description = models.TextField(blank=True,null=True)
    capacity = models.IntegerField(blank=True,null=True)
    rate_per_hour = models.IntegerField(blank=True,null=True)
    rate_per_day = models.IntegerField(blank=True,null=True)
    rate_per_month = models.IntegerField(blank=True,null=True)
    image = models.ImageField(upload_to='workspace/seats/',null=True,blank=True)

    def __str__(self):
        return  f"{self.id} {self.name} {self.workspace}"


class WorkspaceReviews(models.Model):
    Workspace = models.ForeignKey(Workspace,on_delete=models.CASCADE,related_name='reviews')
    by_user = models.ForeignKey(User,on_delete=models.CASCADE)
    rating = models.DecimalField(max_digits=3,decimal_places=1)
    review = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.id} {self.by_user.full_name}"
    



    







