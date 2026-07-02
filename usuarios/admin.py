from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Usuario, CredencialBiometrica, Parentesco


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):
    list_display = ['username', 'email', 'rol', 'first_name', 'last_name', 'is_active']
    list_filter = ['rol', 'is_active']
    fieldsets = UserAdmin.fieldsets + (
        ('Información adicional', {'fields': ('rol', 'telefono', 'direccion', 'foto')}),
    )


@admin.register(CredencialBiometrica)
class CredencialBiometricaAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'creado']
    readonly_fields = ['credential_id', 'public_key', 'contador', 'creado']


@admin.register(Parentesco)
class ParentescoAdmin(admin.ModelAdmin):
    list_display = ['padre', 'hijo', 'parentesco', 'activo']
    list_filter = ['parentesco', 'activo']
