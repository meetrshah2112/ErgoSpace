from django.db import migrations, models


class Migration(migrations.Migration):
    """Replace Windows-style backslash upload paths with portable forward-slash paths."""

    dependencies = [
        ('workspaces', '0002_workspacereviews'),
    ]

    operations = [
        migrations.AlterField(
            model_name='workspace',
            name='logo',
            field=models.ImageField(blank=True, default='logo.jpg', null=True, upload_to='workspace/logos/'),
        ),
        migrations.AlterField(
            model_name='workspace',
            name='background',
            field=models.ImageField(blank=True, default='background.jpg', null=True, upload_to='workspace/background/'),
        ),
        migrations.AlterField(
            model_name='workspacephotos',
            name='gallery',
            field=models.ImageField(upload_to='workspace/gallery/'),
        ),
    ]
