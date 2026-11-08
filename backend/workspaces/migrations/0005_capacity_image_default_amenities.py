from django.db import migrations, models

DEFAULT_AMENITIES = [
    'High-speed WiFi', 'Air conditioning', 'Coffee & tea', 'Printer & scanner',
    'Meeting rooms', 'Power backup', 'Parking', 'Lockers', 'Projector',
    'Whiteboard', 'Cafeteria', 'Phone booths', 'Reception', 'CCTV security',
    'Ergonomic chairs', '24/7 access',
]


def seed_amenities(apps, schema_editor):
    Facilities = apps.get_model('workspaces', 'WorkspaceFacilities')
    for name in DEFAULT_AMENITIES:
        Facilities.objects.get_or_create(name=name)


class Migration(migrations.Migration):

    dependencies = [
        ('workspaces', '0004_alter_workspacereviews_workspace'),
    ]

    operations = [
        migrations.AddField(
            model_name='workspacecapacity',
            name='image',
            field=models.ImageField(blank=True, null=True, upload_to='workspace/seats/'),
        ),
        migrations.RunPython(seed_amenities, migrations.RunPython.noop),
    ]
