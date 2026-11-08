"""
Django settings for the ErgoSpace backend.

All environment-specific values (secrets, database, hosts, CORS, cookies, payment keys)
are read from environment variables / a local `.env` file. See `.env.example`.
"""

import os
from pathlib import Path

from corsheaders.defaults import default_headers
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / '.env')


def env_bool(name, default=False):
    return os.getenv(name, str(default)).strip().lower() in ('1', 'true', 'yes', 'on')


def env_list(name, default=''):
    return [item.strip() for item in os.getenv(name, default).split(',') if item.strip()]


# --- Core -----------------------------------------------------------------

DEBUG = env_bool('DEBUG', False)

SECRET_KEY = os.getenv('SECRET_KEY')
if not SECRET_KEY:
    if DEBUG:
        # Only for local development when no .env has been created yet.
        SECRET_KEY = 'django-insecure-dev-only-change-me'
    else:
        raise RuntimeError('SECRET_KEY environment variable is required when DEBUG is False.')

# Hostnames only (no scheme, no port).
ALLOWED_HOSTS = env_list('ALLOWED_HOSTS', 'localhost,127.0.0.1')


# --- Applications -----------------------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.gis',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'users',
    'workspaces',
    'corsheaders',
    'booking',
    'django_filters',
    'django_extensions',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'ergospace.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ergospace.wsgi.application'


# --- CORS / CSRF / cookies -------------------------------------------------

# Full origins including scheme, e.g. http://localhost:5173
CORS_ALLOWED_ORIGINS = env_list('CORS_ALLOWED_ORIGINS')
CSRF_TRUSTED_ORIGINS = env_list('CSRF_TRUSTED_ORIGINS')
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = list(default_headers) + [
    'X-Amz-Date',
    'Access-Control-Request-Headers',
    'Access-Control-Allow-Headers',
    'Access-Control-Allow-Origin',
    'XMLHttpRequest',
]

# Local HTTP development: COOKIE_SECURE=False, COOKIE_SAMESITE=Lax
# HTTPS cross-site deployment: COOKIE_SECURE=True, COOKIE_SAMESITE=None
COOKIE_SECURE = env_bool('COOKIE_SECURE', False)
COOKIE_SAMESITE = os.getenv('COOKIE_SAMESITE', 'Lax')

SESSION_COOKIE_SECURE = COOKIE_SECURE
SESSION_COOKIE_SAMESITE = COOKIE_SAMESITE
CSRF_COOKIE_SECURE = COOKIE_SECURE
CSRF_COOKIE_SAMESITE = COOKIE_SAMESITE


# --- Database (PostgreSQL + PostGIS) ---------------------------------------

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv('DB_NAME', 'ergospace'),
        'USER': os.getenv('DB_USER', 'ergospace_user'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# Optional: only needed when GDAL/GEOS cannot be auto-detected (typically on Windows
# without Docker). Leave unset otherwise.
if os.getenv('GDAL_LIBRARY_PATH'):
    GDAL_LIBRARY_PATH = os.getenv('GDAL_LIBRARY_PATH')
if os.getenv('GEOS_LIBRARY_PATH'):
    GEOS_LIBRARY_PATH = os.getenv('GEOS_LIBRARY_PATH')


# --- Auth -------------------------------------------------------------------

AUTH_USER_MODEL = 'users.User'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'users.authentication.CustomTokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}


# --- Internationalization ---------------------------------------------------

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True


# --- Static & media files ---------------------------------------------------

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# --- Razorpay ---------------------------------------------------------------

RAZORPAY_PUBLIC_KEY = os.getenv('RAZORPAY_KEY_ID', '')
RAZORPAY_SECRET_KEY = os.getenv('RAZORPAY_KEY_SECRET', '')
