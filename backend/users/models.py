from django.db import models
from django.contrib.auth.models import AbstractUser
from .managers import UserManager
# Create your models here.


'''
    this it the custom user model which extended from Default User model.
    we have added user type files , we set email to be unique .
    username_filed tells django to use the email feild as a primary identitfier 
    required files tell what fields are requried to login or register.
    objects define what usermanager u want to use , we have used custom user manager which taskes only email and password to login and not username
    save function saves the username same as email.
    str functions return username and user type
'''
class User(AbstractUser):
    user_type_choices = (
        ('customer','Customer'),
        ('provider','Provider'),
    )
    user_type = models.CharField(max_length=10,choices=user_type_choices)

    email =  models.EmailField(unique=True)

    username = models.CharField(max_length=150, blank=True, null=True, unique=False)


    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def save(self,*args,**kwargs):
        if self.email:
            self.username = self.email
        super().save(*args,**kwargs)

    def __str__(self):
        return f"{self.username} ({self.user_type})"
    
    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'