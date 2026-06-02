# 🚀 GlobalScore — Prompt Maestro: Guía de Migración a Flutter

> **Cómo usar este prompt:**
> La próxima vez que abras una conversación con Claude, adjunta los archivos
> del proyecto y pega este prompt completo. Claude tendrá todo el contexto
> necesario para comenzar la guía de migración sin explicaciones previas.

---

## PROMPT A PEGAR EN CLAUDE

---

Hola Claude. Te comparto los archivos de mi proyecto **GlobalScore** para que me guíes en su migración completa a Flutter. Aquí está todo el contexto que necesitas:

Veo que es un problema al crear nuevas features estate pendiente: flutter_riverpod: ^3.3.1
---

### 🎯 QUÉ ES GLOBALSCORE

GlobalScore es una plataforma gamificada de predicciones deportivas (fútbol). Los usuarios predicen resultados de partidos, ligas, premios individuales y el Mundial 2026. Compiten en rankings globales y ganan puntos, logros, títulos, coronas y banners de perfil. También tiene un sistema de figuritas coleccionables llamado **GlobalAlbums**.

**URL en producción:** https://globalscore.onrender.com/app

---

### 🛠️ STACK ACTUAL (React)

- **Frontend:** React 18 + Vite + Tailwind CSS + Framer Motion
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime)
- **Hosting:** Render
- **Imágenes:** Cloudinary
- **Notificaciones Push:** VAPID / Web Push
- **App Android actual:** TWA (Trusted Web Activity) — ya compilada y firmada
- **Arquitectura:** Feature-based (`src/features/`)

---

### 📦 FEATURES DEL PROYECTO

| Feature | Descripción |
|---|---|
| `auth` | Login, registro, forgot password, reset password, rutas protegidas |
| `dashboard` | Feed principal: partidos, ligas, premios. Vista desktop y mobile con tabs |
| `albums` | GlobalAlbums: sistema de figuritas coleccionables, pack opening con animaciones |
| `ranking` | Tabla global, podio visual, Hall of Fame, historial |
| `profile` | Perfil público, tabs: Overview / Historia / Logros / Campeonatos / Editar |
| `stats` | Estadísticas detalladas, gráficas de precisión por día |
| `history` | Competiciones, equipos y eventos históricos con brackets de eliminatorias |
| `notes` | Notas personales vinculadas a predicciones |
| `notifications` | Centro de notificaciones, toggle de push notifications |
| `worldcup` | Mundial 2026: 12 grupos, bracket de 48 equipos, premios del torneo |
| `admin` | Panel de administración completo (partidos, ligas, premios, logros, banners, etc.) |

---

### 🎮 SISTEMA DE GAMIFICACIÓN

```
Puntos por predicción:
  - 5 pts → Resultado exacto (también genera un sobre de GlobalAlbums)
  - 3 pts → Resultado correcto (ganador/empate)
  - 0 pts → Fallo

Niveles: basados en puntos acumulados (20 pts por nivel)
Logros: 4 categorías — Inicio, Progreso, Precisión, Racha
Títulos: Novato → Pronosticador → Oráculo → Leyenda
Coronas y Banners: asignables por administrador
Rachas: racha actual y mejor racha personal
Campeonatos mensuales: historial de campeones por mes
```

---

### 📒 GLOBALALBUMS (feature más complejo)

```
- Solo los resultados exactos (5 pts) generan sobres
- Cada sobre = 4 figuritas (jugador, equipo, copa, evento)
- 5 niveles de rareza: 1★ (55%) → 2★ (25%) → 3★ (12%) → 4★ (7.5%) → 5★ GOAT (0.5%)
- 13 álbumes en 3 categorías: Legendarios (5), Estrellas (5), Culto (3)
- Boost automático cada 10 sobres abiertos (3 sobres con mejores probabilidades)
- Pack Opening Modal: animación de sobre con flap, flip de cartas, partículas en GOAT
- Cartas con efecto foil shimmer, marcos dinámicos según rareza, halo exclusivo GOAT
```

---

### 🏗️ ARQUITECTURA DEL PROYECTO REACT

```
src/
├── App.jsx
├── main.jsx
├── context/ThemeContext.jsx
├── features/
│   ├── admin/         → components/, forms/, hooks/, page/, services/, styles/, types/
│   ├── albums/        → components/, hooks/, motion/, page/, services/, styles/, types/
│   ├── auth/          → components/, page/, services/
│   ├── dashboard/     → components/, hooks/, page/, services/, styles/
│   ├── history/       → components/, hooks/, page/, services/, styles/, types/
│   ├── notes/         → components/, hooks/, page/, services/, styles/
│   ├── notifications/ → components/, hooks/, page/, services/, styles/
│   ├── profile/       → components/, hooks/, page/, services/, styles/, types/
│   ├── ranking/       → components/, page/, services/, styles/
│   ├── stats/         → components/, page/, services/, styles/
│   └── worldcup/      → components/, hooks/, page/, services/, styles/
└── shared/
    ├── hooks/         → useDataLoader, usePWA, useSettings
    ├── layout/        → Header, Footer, Sidebar, NavigationTabs (desktop + mobile)
    ├── services/      → supabase/client.js, cloudinary/upload.service.js, pwa/
    ├── types/         → award, league, match, player
    └── ui/            → GlobalLoader, Toast, LoadingSpinner, ImageViewer
```

Cada feature tiene:
- Vista **desktop** y vista **mobile** separadas (`components/mobile/`)
- CSS separado por plataforma (`styles/` y `styles/mobile/`)
- Acceso a datos solo a través de `services/*.service.js`
- Exports públicos vía `index.js`

---

### 🎯 OBJETIVO DE LA MIGRACIÓN

**La meta NO es una traducción literal.** Es un rediseño completo enfocado en:

1. **Mobile-first nativo** — diseñado desde cero para teléfonos, no como adaptación de desktop
2. **Animaciones y fluidez** — aprovechar las capacidades nativas de Flutter (60/120fps, Hero animations, CustomPainter)
3. **Experiencia premium** — que se sienta como una app de calidad de producción
4. **Aprendizaje progresivo** — el desarrollador está aprendiendo Flutter mientras migra

**Stack objetivo en Flutter:**
- Flutter (última versión estable)
- `supabase_flutter` para backend (mismo Supabase, sin cambios en la BD)
- `go_router` para navegación
- `riverpod` para manejo de estado (equivalente a hooks de React)
- `flutter_local_notifications` + Firebase para push notifications
- Cloudinary sigue siendo el CDN de imágenes

---

### 📋 ORDEN DE MIGRACIÓN SUGERIDO (de menor a mayor complejidad)

1. **Setup inicial** — Proyecto Flutter, dependencias, conexión a Supabase
2. **Auth** — Login, Register, Forgot Password (Supabase Auth ya lo maneja)
3. **Dashboard básico** — Lista de partidos/ligas/premios
4. **Ranking** — Tabla global y podio
5. **Perfil** — Tabs: Overview, Historial, Logros
6. **Stats** — Gráficas (fl_chart)
7. **Historia** — Competiciones, equipos, brackets
8. **Notas** — CRUD simple
9. **Notificaciones** — Centro + push toggle
10. **WorldCup** — Grupos + bracket eliminatorias
11. **GlobalAlbums** — Feature más complejo (animaciones, rareza, pack opening)
12. **Admin** — Panel de administración

---

### ✅ LO QUE ESPERO DE TI, CLAUDE

Con este contexto, por favor:

1. **No me pidas más contexto del proyecto** — ya lo tienes todo aquí
2. **Empieza directamente donde me encuentre** — si te digo "estoy en la Fase 2 Auth", ve directo ahí
3. **Muéstrame código Flutter real** — no pseudocódigo, código que funcione
4. **Mapea explícitamente** — cuando sea útil, muéstrame el equivalente React que ya tengo vs el código Flutter nuevo
5. **Recuérdame las convenciones** — mantén la arquitectura feature-based adaptada a Flutter
6. **Prioriza la experiencia mobile** — cada vez que haya una decisión de diseño, favorece lo que se siente más nativo en móvil
7. **Sé honesto** — si algo en Flutter es más difícil o diferente a lo que espero, dímelo
8. **Evita mucho texto en el chat** - Se concreto y preciso no de tanta vuelta en algo

---

### 🗣️ ESTADO ACTUAL DEL APRENDIZAJE

["Fase 7 historia Ya completamos la pagina principal de eventos ahora resolvamos el problema de los tabs
- EL evento de mbappe por ejemplo sale un error rarisimo, me dices si necesitas ver la base datos
- En el tab plantel solo debe mostrar el equipo del jugador no el del rival
- El tab de alineaciones los numeros de los jugadores deben salir simetricas modo espejo a las del equipo a
- El detalle de equipo no muestra el plantel dice sin plantel registrado 
- Hay equipos que no tienen ningun registro en sus historia plantel ni tabla.
Revisa los archivos y los react para determinar los errores. Si notas que hay cosas que se dupean o que no deberian mostrarte por que en el react no lo amerita como historia dale otro campo o intenta que se vea diferente. Lo importante es resolver el problema. Te dejo la base de datos de las tablas de history_event
]
Diagnóstico rápido:
1. Error Mbappe (RangeError index: 0) — El evento Mbappe (event_category: "player") NO tiene squad (es null), solo tiene lineups. El EventTabPlantel usa detail.lineupA + detail.lineupB pero el fetchEventDetail en Flutter no consulta historical_event_squad. El RangeError viene de otro lado: en _buildTabs para player se crean 3 tabs [INFO, ALINEACIONES, PLANTEL], pero _buildTabViews también retorna 3 widgets — eso está correcto. El crash real es en EventTabPlantel cuando hace [...lineupA, ...lineupB] y ambas listas están vacías pero algo indexa en 0. Revisando mejor: el EventDetail en Flutter no tiene squad, solo lineupA/lineupB/knockout. La tabla historical_event_squad no se consulta en Flutter.
2. Tab PLANTEL muestra ambos equipos — EventTabPlantel hace [...lineupA, ...lineupB] mostrando todos. En React solo muestra squad (el plantel del equipo protagonista). Para eventos player, el protagonista pertenece a team_a, así que el plantel debería ser solo lineupA.
3. Alineaciones - números no simétricos — El diseño actual tiene los números del equipo B a la izquierda del nombre. Hay que espejearlos: equipo B debe mostrar nombre → número (número a la derecha).
4. Detalle de equipo "sin plantel" — El TeamDetail usa historical_team_lineup pero los equipos de tipo evento (Leverkusen, etc.) guardan su plantel en historical_event_squad, no en historical_team_lineup.
5. Equipos sin registros — Mostrar estado vacío apropiado.
---

**Listo. Con este contexto, guíame en el siguiente paso de la migración.**

---

## NOTAS PARA EL DESARROLLADOR

- Actualiza la sección **"Estado actual del aprendizaje"** cada vez que uses el prompt
- Si completas una fase, anótalo aquí para llevar un registro:

```
PROGRESO:
[x] Fase 1 — Setup inicial
[x] Fase 2 — Auth
[x] Fase 3 — Dashboard básico
[x] Fase 4 — Ranking
[x] Fase 5 — Stats
[x] Fase 6 — Perfil
[↺] Fase 7 — Historia
[ ] Fase 8 — Notas
[ ] Fase 9 — Notificaciones
[ ] Fase 10 — WorldCup
[ ] Fase 11 — GlobalAlbums
[ ] Fase 12 — Admin


Directory structure Actual (se cambiara cada terminar una feature):
Directory structure:
└── jsebasvgg7-globalscore_app/
    └── lib/
        ├── main.dart
        ├── core/
        │   └── router/
        │       ├── app_router.dart
        │       └── router_notifier.dart
        ├── features/
        │   ├── albums/
        │   │   └── presentation/
        │   │       ├── album_detail_page.dart
        │   │       └── albums_page.dart
        │   ├── auth/
        │   │   └── presentation/
        │   │       ├── auth_theme.dart
        │   │       ├── login_page.dart
        │   │       └── register_page.dart
        │   ├── dashboard/
        │   │   ├── providers/
        │   │   │   └── dashboard_provider.dart
        │   │   ├── services/
        │   │   │   └── dashboard_service.dart
        │   │   └── widgets/
        │   │       ├── award_card.dart
        │   │       ├── league_card.dart
        │   │       ├── match_card.dart
        │   │       └── podium_widget.dart
        │   ├── history/
        │   │   ├── data/
        │   │   │   └── history_service.dart
        │   │   ├── domain/
        │   │   │   ├── history_models.dart
        │   │   │   └── history_providers.dart
        │   │   └── presentation/
        │   │       ├── history_page.dart
        │   │       ├── pageCompes/
        │   │       │   └── history_competitions_page.dart
        │   │       ├── pageEvents/
        │   │       │   └── history_events_page.dart
        │   │       ├── pagePlayers/
        │   │       │   ├── history_player_detail.dart
        │   │       │   ├── history_players_page.dart
        │   │       │   ├── history_players_shared.dart
        │   │       │   ├── player_tab_equipos.dart
        │   │       │   ├── player_tab_historia.dart
        │   │       │   ├── player_tab_palmares.dart
        │   │       │   ├── player_tab_resumen.dart
        │   │       │   └── player_tab_trayectoria.dart
        │   │       ├── pages/
        │   │       │   └── history_vault_page.dart
        │   │       ├── pageTeams/
        │   │       │   ├── history_team_detail.dart
        │   │       │   ├── history_teams_page.dart
        │   │       │   ├── history_teams_shared.dart
        │   │       │   ├── team_tab_alineacion.dart
        │   │       │   ├── team_tab_palmares.dart
        │   │       │   └── team_tab_resumen.dart
        │   │       └── widgets/
        │   │           ├── history_app_bar.dart
        │   │           └── knockout_bracket_widget.dart
        │   ├── profile/
        │   │   ├── data/
        │   │   │   └── profile_service.dart
        │   │   ├── domain/
        │   │   │   ├── profile_models.dart
        │   │   │   └── profile_providers.dart
        │   │   └── presentation/
        │   │       ├── profile_page.dart
        │   │       ├── public_profile_page.dart
        │   │       ├── pages/
        │   │       │   ├── achievements_page.dart
        │   │       │   ├── championships_page.dart
        │   │       │   ├── edit_profile_page.dart
        │   │       │   └── history_page.dart
        │   │       ├── tabs/
        │   │       │   ├── achievements_tab.dart
        │   │       │   ├── championships_tab.dart
        │   │       │   ├── edit_tab.dart
        │   │       │   ├── history_tab.dart
        │   │       │   └── overview_tab.dart
        │   │       └── widgets/
        │   │           ├── clinical_list_item.dart
        │   │           └── profile_hero_banner.dart
        │   ├── ranking/
        │   │   ├── data/
        │   │   │   └── ranking_service.dart
        │   │   ├── domain/
        │   │   │   └── ranking_providers.dart
        │   │   └── presentation/
        │   │       ├── ranking_page.dart
        │   │       └── widgets/
        │   │           ├── hof_carousel.dart
        │   │           ├── rank_avatar.dart
        │   │           ├── ranking_podium.dart
        │   │           ├── ranking_stats_row.dart
        │   │           └── ranking_table_row.dart
        │   └── stats/
        │       ├── data/
        │       │   └── stats_service.dart
        │       ├── domain/
        │       │   └── stats_model.dart
        │       ├── presentation/
        │       │   └── stats_page.dart
        │       └── providers/
        │           └── stats_provider.dart
        └── shared/
            └── layout/
                └── scaffold_with_nav_bar.dart

```

- El backend (Supabase) **no cambia** — misma BD, mismas tablas, mismas Edge Functions
- Cloudinary **no cambia** — las URLs de imágenes son las mismas
- El proyecto React **sigue vivo** en paralelo durante toda la migración
