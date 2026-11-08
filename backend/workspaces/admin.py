from django.contrib import admin
from .models import Workspace,WorkspacePhotos,WorkspaceFacilities,WorkspaceCapacity
# Register your models here.

admin.site.register(Workspace)
admin.site.register(WorkspacePhotos)
admin.site.register(WorkspaceFacilities)
admin.site.register(WorkspaceCapacity)