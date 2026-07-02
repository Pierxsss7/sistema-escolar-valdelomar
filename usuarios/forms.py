from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import Usuario


class RegistroForm(UserCreationForm):
    TIPO_REGISTRO = [
        ('padre', 'Padre de Familia'),
    ]

    first_name = forms.CharField(max_length=30, label='Nombres')
    last_name = forms.CharField(max_length=30, label='Apellidos')
    email = forms.EmailField(required=False, label='Correo electrónico')
    telefono = forms.CharField(max_length=15, required=False, label='Teléfono')

    class Meta:
        model = Usuario
        fields = ['username', 'first_name', 'last_name', 'email', 'telefono', 'password1', 'password2']

    def save(self, commit=True):
        user = super().save(commit=False)
        user.rol = 'padre'
        if commit:
            user.save()
        return user
