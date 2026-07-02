from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import Usuario


class RegistroForm(UserCreationForm):
    TIPO_REGISTRO = [
        ('profesor', 'Profesor / Docente'),
        ('padre', 'Padre de Familia'),
    ]

    rol = forms.ChoiceField(choices=TIPO_REGISTRO, label='Tipo de cuenta')
    first_name = forms.CharField(max_length=30, label='Nombres')
    last_name = forms.CharField(max_length=30, label='Apellidos')
    email = forms.EmailField(required=False, label='Correo electrónico')
    dni = forms.CharField(max_length=8, required=False, label='DNI')
    telefono = forms.CharField(max_length=15, required=False, label='Teléfono')

    class Meta:
        model = Usuario
        fields = ['username', 'first_name', 'last_name', 'email', 'dni', 'telefono', 'rol', 'password1', 'password2']

    def save(self, commit=True):
        user = super().save(commit=False)
        user.rol = self.cleaned_data['rol']
        user.dni = self.cleaned_data.get('dni') or None
        if commit:
            user.save()
        return user
