# ⚽ GlobalScore

### Plataforma gamificada de predicciones deportivas — Versión Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/Estado-Riverpod-blue?style=flat-square)](https://riverpod.dev)

**[🌐 Versión Web (React)](https://globalscore.onrender.com/app)** · Reconstruida desde cero como app nativa en Flutter

---

## ¿Qué es GlobalScore?

GlobalScore es una **plataforma gamificada de predicciones de fútbol** donde los usuarios predicen resultados de partidos, ligas, premios individuales y el **Mundial 2026**. Compiten en rankings globales y ganan puntos, logros, títulos, coronas y banners de perfil.

La plataforma también incluye **GlobalAlbums** — un sistema de figuritas coleccionables inspirado en los álbumes Panini, donde las predicciones exactas desbloquean sobres con animaciones de apertura y efectos de rareza.

> Este repositorio es la **reescritura nativa en Flutter** de la app web original en React + Vite. Mismo backend de Supabase, sin cambios en la base de datos — experiencia completamente rediseñada desde mobile.

---

## 🛠️ Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter (última versión estable) |
| Lenguaje | Dart |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime) |
| Manejo de estado | `flutter_riverpod ^3.3.1` |
| Navegación | `go_router` |
| CDN de imágenes | Cloudinary (mismas URLs que la web) |
| Push Notifications | Firebase + `flutter_local_notifications` |
| Gráficas | `fl_chart` |
| Stack anterior | React 18 + Vite + Tailwind CSS + Framer Motion |

---

## ✨ Features

| # | Feature | Estado | Descripción |
|---|---|---|---|
| 01 | **Auth** | ✅ Listo | Login, registro, forgot/reset password vía Supabase Auth |
| 02 | **Dashboard** | ✅ Listo | Feed principal: partidos, ligas, premios |
| 03 | **Ranking** | ✅ Listo | Tabla global, podio visual, Hall of Fame |
| 04 | **Stats** | ✅ Listo | Gráficas de precisión, exactitud por día (`fl_chart`) |
| 05 | **Perfil** | ✅ Listo | Perfil público, tabs: Resumen / Historia / Logros / Campeonatos / Editar |
| 06 | **Historia** | ✅ Listo | Competiciones, equipos, jugadores, brackets de eliminatorias |
| 07 | **Notas** | ✅ Listo | Notas personales vinculadas a predicciones |
| 08 | **Notificaciones** | 🔄 En progreso | Centro de notificaciones + toggle de push |
| 09 | **Mundial 2026** | ✅ Listo | 12 grupos, bracket de 48 equipos, premios del torneo |
| 10 | **GlobalAlbums** | 🔄 En progreso | Figuritas coleccionables, pack opening, sistema de rareza |
| 11 | **Admin** | ⬜ Pendiente | Panel completo: partidos, ligas, premios, logros, banners |

---

## 🎮 Sistema de gamificación

```
Puntos por predicción:
  5 pts → Resultado exacto  (también genera un sobre de GlobalAlbums)
  3 pts → Resultado correcto (ganador/empate)
  0 pts → Fallo

Niveles        → Basados en puntos acumulados (20 pts por nivel)
Títulos        → Novato → Pronosticador → Oráculo → Leyenda
Logros         → 4 categorías: Inicio, Progreso, Precisión, Racha
Coronas        → Asignables por administrador
Banners        → Banners de perfil personalizados, asignados por admin
Rachas         → Racha actual + mejor racha personal
Campeonatos    → Historial de campeones mensuales
```

---

## 📒 GlobalAlbums

La feature más compleja — un sistema de figuritas coleccionables con animaciones completas:

```
Trigger     → Solo los resultados exactos (5 pts) generan sobres
Sobre       → 4 figuritas por sobre (jugador / equipo / copa / evento)
Rareza      → 5 niveles: 1★ 55% · 2★ 25% · 3★ 12% · 4★ 7.5% · 5★ GOAT 0.5%
Álbumes     → 13 álbumes en 3 categorías: Legendarios (5) · Estrellas (5) · Culto (3)
Boost       → Auto-boost cada 10 sobres abiertos (3 sobres con mejores probabilidades)

Animaciones:
  - Apertura de sobre con flap y flip de cartas
  - Efecto foil shimmer en las cartas
  - Marcos dinámicos según rareza
  - Explosión de partículas en cartas GOAT
  - Halo exclusivo para rareza GOAT
```

---

## 🏗️ Arquitectura

Arquitectura por features adaptada del proyecto React original:

```
lib/
├── main.dart
├── core/
│   └── router/
│       ├── app_router.dart           # Configuración de go_router
│       └── router_notifier.dart      # Lógica de redirección según auth
├── features/
│   ├── auth/presentation/            # login_page, register_page, auth_theme
│   ├── dashboard/
│   │   ├── data/                     # dashboard_service.dart (llamadas a Supabase)
│   │   ├── domain/                   # dashboard_provider.dart (Riverpod)
│   │   └── widgets/                  # match_card, league_card, award_card, podium
│   ├── ranking/                      # data / domain / presentation / widgets
│   ├── stats/                        # data / domain / presentation
│   ├── profile/
│   │   └── presentation/
│   │       ├── tabs/                 # overview, history, achievements, championships, edit
│   │       └── widgets/              # profile_hero_banner, clinical_list_item
│   ├── history/
│   │   └── presentation/
│   │       ├── pageCompes/           # Tabs de competición (grupos, knockout, standings)
│   │       ├── pageTeams/            # Tabs de equipo (resumen, palmarés, alineación)
│   │       ├── pagePlayers/          # Tabs de jugador (carrera, palmarés, equipos)
│   │       └── pageEvents/           # Tabs de evento (info, alineaciones, tabla)
│   ├── notes/                        # data / domain / presentation
│   ├── notifications/                # data / domain / presentation (🔄 en progreso)
│   ├── worldcup/                     # grupos, bracket eliminatorias, premios
│   └── albums/                       # presentation (🔄 en progreso)
└── shared/
    └── layout/
        └── scaffold_with_nav_bar.dart    # Shell de navegación inferior
```

Cada feature sigue el mismo patrón de tres capas:

- **`data/`** — Llamadas a Supabase, fetching de datos crudos
- **`domain/`** — Providers de Riverpod, modelos, lógica de negocio
- **`presentation/`** — Widgets, páginas, componentes de UI

---

## 🚀 Cómo correr el proyecto

### Requisitos previos

- Flutter SDK (última versión estable) — [guía de instalación](https://docs.flutter.dev/get-started/install)
- Dart SDK (incluido con Flutter)
- Proyecto de Supabase (el backend es compartido con la versión web)
- Proyecto de Firebase (para push notifications)

### Setup

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/globalscore_app.git
cd globalscore_app

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
# Crear lib/core/config/supabase_config.dart con tus claves:
# const supabaseUrl = 'TU_SUPABASE_URL';
# const supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';

# 4. Correr la app
flutter run
```

### Build para Android

```bash
# APK directo
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

---

## 🔗 Backend

La app Flutter se conecta al **mismo backend de Supabase** que la versión web:

- **PostgreSQL** — todas las tablas sin cambios
- **Supabase Auth** — autenticación por email/contraseña
- **Supabase Storage** — uploads de usuarios
- **Edge Functions** — lógica de negocio (generación de sobres, puntaje, etc.)
- **Realtime** — actualizaciones en vivo de resultados
- **Cloudinary** — CDN de imágenes (mismas URLs consumidas desde Flutter)

No se requirió ningún cambio en el backend para la migración.

---

## 📱 Contexto de la migración

Esta app es una reescritura nativa de [GlobalScore Web](https://globalscore.onrender.com/app) (React + Vite). El objetivo de la migración no fue una traducción literal sino un **rediseño completo mobile-first**:

- Animaciones nativas a 60/120fps usando el motor de renderizado de Flutter
- Transiciones `Hero`, `CustomPainter` y animaciones con física
- Un solo layout adaptativo en lugar de vistas desktop/mobile separadas
- Push notifications vía Firebase (reemplazando VAPID/Web Push)
- Distribución en Android (anteriormente era un TWA wrapper)

La versión web sigue activa en paralelo durante toda la migración.

---

<div align="center">

Hecho por Zentryx 

</div>