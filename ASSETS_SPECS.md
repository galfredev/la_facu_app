# Especificaciones de Logos y Assets - La Facu

## Logo Principal (App Icon)

### Android (Google Play)
- **1024x1024** px - Logo principal (obligatorio)
- **512x512** px - Logo para tienda
- **Adaptative Icon** - Para Android 8+

### iOS (App Store)
- **1024x1024** px - Logo principal (obligatorio)
- Genera automáticamente todos los tamaños desde 1024

### Windows (Microsoft Store)
- **150x150** px - Logo de tile pequeño
- **310x310** px - Logo de tile mediano  
- **310x150** px - Logo de tile ancho
- **50x50** px - Logo de lista de apps

---

## Screenshots para Google Play (mínimo 2, máximo 8)

### Phone Screenshots
- **1080x1920** px (9:16) - Vertical
- **1920x1080** px (16:9) - Horizontal

### Requisitos:
- Mínimo 2 screenshots
- Formato: PNG o JPEG
- Sin bordes ni frames de dispositivo
- Mostrar la app funcionando

###建议 contenido:
1. Dashboard principal con materias
2. Vista de calendario/horarios
3. Lista de tareas
4. Configuración de notificaciones
5. Login con Google

---

## Screenshots para App Store (mínimo 1, máximo 10)

### iPhone
- **6.7" Display**: 1290x2796 px
- **6.5" Display**: 1284x2778 px
- **5.5" Display**: 1242x2208 px

### iPad
- **12.9" Display**: 2048x2732 px

---

## Feature Graphic (Google Play)

- **1024x500** px - Banner promocional
- Fondo: Usar color o gradiente
- No incluir texto de título
- Mostrar logo y screenshot

---

## App Preview Video (Opcional pero recomendado)

### Google Play
- Duración: 30 segundos máximo
- Formato: MP4, WebM
- Resolución: 1080p o 4K

### App Store
- Duración: 15-30 segundos
- Formato: MOV o MP4
- Resolución: 1080p

---

## Tareas Pendientes

### Logo a crear:
- [ ] 1024x1024 PNG de alta calidad
- [ ] Versión clara y oscura del logo
- [ ] Logo sin fondo (PNG transparente)

### Screenshots a crear:
- [ ] 5-6 screenshots de la app funcionando
- [ ] Editar para quitar elementos sensibles
- [ ] Agregar textos descriptivos

### Assets a generar:
- [ ] Feature graphic 1024x500
- [ ] Iconos adaptativos para Android
- [ ] Actualizar iconos de iOS

---

## Ubicación de archivos

```
assets/
├── icon/
│   └── icon.png          # Logo actual (básico)
├── screenshots/
│   ├── phone_01.png      # Dashboard
│   ├── phone_02.png      # Calendario
│   ├── phone_03.png      # Tareas
│   ├── phone_04.png      # Configuración
│   └── feature_graphic.png
└── promotional/
    └── logo_light.png
    └── logo_dark.png
```
