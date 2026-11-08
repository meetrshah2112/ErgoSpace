from django.contrib.auth.models import BaseUserManager


'''
    this is  the custom user manager, we have made this becoz by default to login or create super user in django
    we need to enter username and as our project need only email we have created this manager it will take 
    only email and passsword to create a user and super user and it will sync the email and username. 
'''
class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')
        email = self.normalize_email(email)
        extra_fields.setdefault('username', email)  # sync username with email
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('username', email)  # sync username with email

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)