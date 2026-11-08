from rest_framework import permissions

class IsProviderPermission(permissions.BasePermission):
    
    def has_permission(self, request, view):
        if request.user.user_type == 'customer':
            return False
        return super().has_permission(request, view)
    
class IsCustomerPermission(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.user.user_type == 'provider':
            return False
        return super().has_permission(request, view)
    
class IsOwner(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):

        if request.user.is_staff:
            return True
        
        return obj.id == request.user.id