# Saman Sports

Plataforma web de las actividades deportivas de la Universidad Metropolitana (UNIMET).

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome
```

## Estructura

- `lib/FirebaseServices.dart`: única fachada hacia Firebase.
- `lib/controllers/`: lógica de autenticación y del Home.
- `lib/views/`: pantallas y widgets.
- `lib/core/`: tema, textos, rutas y validadores.
- `docs/mockups/`: referencias visuales, no se cargan en la app.
