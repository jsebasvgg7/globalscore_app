import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  String  _firstName = 'Jugador';
  String  _initials  = 'JU';
  String? _avatarUrl;
  bool    _isAdmin   = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('name, avatar_url, is_admin')
          .eq('auth_id', uid)
          .maybeSingle();
      if (data != null && mounted) {
        final name = (data['name'] as String? ?? 'Jugador');
        setState(() {
          _firstName = name.split(' ').first;
          _initials  = name.length >= 2
              ? name.substring(0, 2).toUpperCase()
              : name.toUpperCase();
          _avatarUrl = data['avatar_url'] as String?;
          _isAdmin   = data['is_admin'] == true;
        });
      }
    } catch (_) {}
  }

  // ✅ Navega al branch 4 (perfil) y sincroniza el bottom nav
  void _goToProfile() {
    widget.navigationShell.goBranch(
      4,
      initialLocation: 4 == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _GsColors.cream,
      body: Column(
        children: [
          _GsTopBar(
            firstName:  _firstName,
            initials:   _initials,
            avatarUrl:  _avatarUrl,
            isAdmin:    _isAdmin,
            onWorld:    () => context.push('/worldcup'),
            onNotif:    () => context.push('/notifications'),
            onProfile:  _goToProfile, // ✅ usa goBranch, no push
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: _GsBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        isAdmin:      _isAdmin,
        onTap: (branchIndex) {
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.navigationShell.currentIndex,
          );
        },
        onTrophy: () {
          widget.navigationShell.goBranch(
            0,
            initialLocation: 0 == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TOP BAR
// ═══════════════════════════════════════════════════════════

class _GsTopBar extends StatefulWidget {
  final String   firstName;
  final String   initials;
  final String?  avatarUrl;
  final bool     isAdmin;
  final VoidCallback onWorld;
  final VoidCallback onNotif;
  final VoidCallback onProfile;

  const _GsTopBar({
    required this.firstName,
    required this.initials,
    required this.avatarUrl,
    required this.isAdmin,
    required this.onWorld,
    required this.onNotif,
    required this.onProfile,
  });

  @override
  State<_GsTopBar> createState() => _GsTopBarState();
}

class _GsTopBarState extends State<_GsTopBar> {
  String _clock = '';

  @override
  void initState() {
    super.initState();
    _tick();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      _tick();
      return true;
    });
  }

  void _tick() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _clock = '$h:$m');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 18, right: 18,
      ),
      decoration: const BoxDecoration(
        color: _GsColors.cream,
        border: Border(bottom: BorderSide(color: _GsColors.border, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.firstName,
            style: const TextStyle(
              fontFamily: _GsColors.fontMono,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _GsColors.dark,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          _TopBtn(icon: Icons.language_outlined, onTap: widget.onWorld),
          const SizedBox(width: 8),
          _TopBtn(
            icon: Icons.notifications_outlined,
            hasDot: true,
            onTap: widget.onNotif,
          ),
          const SizedBox(width: 8),
          _AvatarBtn(
            initials:  widget.initials,
            avatarUrl: widget.avatarUrl,
            onTap:     widget.onProfile,
          ),
        ],
      ),
    );
  }
}

class _TopBtn extends StatefulWidget {
  final IconData icon;
  final bool     hasDot;
  final VoidCallback onTap;

  const _TopBtn({required this.icon, this.hasDot = false, required this.onTap});

  @override
  State<_TopBtn> createState() => _TopBtnState();
}

class _TopBtnState extends State<_TopBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 36, height: 36,
        transform: _pressed
            ? (Matrix4.identity()..translate(1.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _GsColors.cream,
          border: Border.all(color: _GsColors.border, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(widget.icon, size: 15, color: _GsColors.muted),
            if (widget.hasDot)
              Positioned(
                top: 7, right: 7,
                child: Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBtn extends StatefulWidget {
  final String   initials;
  final String?  avatarUrl;
  final VoidCallback onTap;

  const _AvatarBtn({required this.initials, this.avatarUrl, required this.onTap});

  @override
  State<_AvatarBtn> createState() => _AvatarBtnState();
}

class _AvatarBtnState extends State<_AvatarBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 36, height: 36,
        transform: _pressed
            ? (Matrix4.identity()..translate(1.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _GsColors.accent,
          border: Border.all(color: _GsColors.border, width: 1.5),
        ),
        child: widget.avatarUrl != null
            ? Image.network(widget.avatarUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(widget.initials))
            : _Initials(widget.initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: _GsColors.fontMono,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BOTTOM NAV
// ═══════════════════════════════════════════════════════════

class _GsBottomNav extends StatelessWidget {
  final int  currentIndex;
  final bool isAdmin;
  final void Function(int) onTap;
  final VoidCallback onTrophy;

  const _GsBottomNav({
    required this.currentIndex,
    required this.isAdmin,
    required this.onTap,
    required this.onTrophy,
  });

  @override
  Widget build(BuildContext context) {
    // branchIndex: 0=dashboard, 1=ranking, 2=albums, 3=stats, 4=profile
    final leftItems = [
      // ✅ Admin usa branch 2 (albums) como placeholder hasta tener branch admin
      // o simplemente navega con context.push cuando esté listo
      if (isAdmin)
        const _NavItem(
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield,
          label: 'Admin',
          branchIndex: 2, // ✅ branch válido (albums) hasta tener el branch admin
        )
      else
        const _NavItem(
          icon: Icons.museum_outlined,
          activeIcon: Icons.museum,
          label: 'Álbums',
          branchIndex: 2,
        ),
      const _NavItem(
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events,
        label: 'Ranking',
        branchIndex: 1,
      ),
    ];

    final rightItems = [
      const _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Stats',
        branchIndex: 3,
      ),
      const _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Perfil',
        branchIndex: 4,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _GsColors.cream,
        border: Border(top: BorderSide(color: _GsColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              ...leftItems.map((item) => Expanded(
                child: _BottomNavButton(
                  item: item,
                  isActive: currentIndex == item.branchIndex,
                  onTap: () => onTap(item.branchIndex),
                ),
              )),
              Expanded(
                child: _TrophyButton(
                  isActive: currentIndex == 0,
                  onTap: onTrophy,
                ),
              ),
              ...rightItems.map((item) => Expanded(
                child: _BottomNavButton(
                  item: item,
                  isActive: currentIndex == item.branchIndex,
                  onTap: () => onTap(item.branchIndex),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BottomNavButton> createState() => _BottomNavButtonState();
}

class _BottomNavButtonState extends State<_BottomNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isActive ? widget.item.activeIcon : widget.item.icon,
              size: 19,
              color: widget.isActive ? _GsColors.dark : _GsColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrophyButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _TrophyButton({required this.isActive, required this.onTap});

  @override
  State<_TrophyButton> createState() => _TrophyButtonState();
}

class _TrophyButtonState extends State<_TrophyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -11,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                transform: _pressed
                    ? (Matrix4.identity()..translate(2.0, 2.0))
                    : Matrix4.identity(),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _GsColors.accent,
                  boxShadow: _pressed
                      ? const [BoxShadow(color: Color(0x661B14A0), offset: Offset(1, 1), blurRadius: 0)]
                      : const [BoxShadow(color: Color(0x661B14A0), offset: Offset(3, 3), blurRadius: 0)],
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 22,
                  color: widget.isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final int      branchIndex;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.branchIndex,
  });
}

abstract class _GsColors {
  static const Color cream   = Color(0xFFF0EDE8);
  static const Color surface = Color(0xFFE8E4DE);
  static const Color border  = Color(0xFFC4BFB8);
  static const Color dark    = Color(0xFF1A1A2E);
  static const Color accent  = Color(0xFF5B4FD8);
  static const Color muted   = Color(0xFF88887D);

  static const String fontMono = 'DM Mono';
}