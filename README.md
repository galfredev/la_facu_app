# La Facu 🎓

**La Facu** es una plataforma de organización académica premium diseñada específicamente para estudiantes universitarios. Enfocada en la productividad y la estética minimalista, permite gestionar de forma integral el ciclo de vida del estudiante: desde el seguimiento de materias hasta la sincronización automática de horarios y tareas con Google Calendar.

---

## 🚀 Características Principales

- **Gestión Académica Completa**: Seguimiento detallado de materias, tareas y exámenes.
- **Agenda Dinámica e Interactiva**: Visualización semanal de horarios estructurada para facilitar la lectura rápida.
- **Sincronización Bidireccional**: Integración oficial con la API de Google Calendar para mantener tus eventos al día en todos tus dispositivos.
- **Notificaciones Inteligentes**: Sistema de recordatorios locales diseñado para que nunca pierdas una fecha de entrega o examen.
- **Estética "Coder" Minimalista**: Interfaz diseñada con tipografías **Outfit** y **JetBrains Mono**, inspirada en entornos de desarrollo modernos para maximizar la concentración.

---

## 🛠️ Stack Tecnológico

- **Framework**: [Flutter](https://flutter.dev) (Multiplataforma)
- **Gestión de Estado**: [Riverpod](https://riverpod.dev)
- **Persistencia de Datos**: [Isar Database](https://isar.dev) (Local Fast Storage)
- **Autenticación e Integración**: Google Cloud Console & Firebase Auth
- **Diseño**: Nordic Glassmorphism & Programmer Aesthetic

---

## 📦 Instalación y Desarrollo

### Requisitos Previos:
- Flutter SDK (Versión estable)
- Android SDK (Para compilación APK)
- Visual Studio con soporte C++ (Para la versión de Windows)

### Pasos para ejecución local:
1. Clonar el repositorio:
   ```bash
   git clone https://github.com/galfredev/la_facu_app.git
   ```
2. Obtener dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecutar aplicación:
   ```bash
   flutter run
   ```

---

## 🏗️ Distribución

### Generar APK (Android):
```bash
flutter build apk --release
```

### Generar MSIX (Windows Store):
```bash
flutter pub run msix:create
```

---

## 👤 Autor
**GalfreDev Team**  
Desarrollado con ❤️ para facilitarle la vida a los estudiantes.

---
© 2026 La Facu. Todos los derechos reservados.
