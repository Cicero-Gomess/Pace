# pace_tcc

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Rodar o Pace no Android físico

O backend deve ser iniciado aceitando conexões da rede local:

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Por padrão o app usa `192.168.1.8:8000` no Android. Para usar outro notebook/IP sem editar o código:

```powershell
flutter run -d SEU_DEVICE_ID --dart-define=PACE_API_HOST=192.168.1.25
```

O celular e o computador precisam estar na mesma rede. O nome do app Android é **Pace** e o launcher usa a logo do Pace.
