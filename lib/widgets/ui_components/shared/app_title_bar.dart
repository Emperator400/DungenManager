import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_notifier.dart';
import '../../../viewmodels/update_viewmodel.dart';
import '../../update_dialog.dart';
import 'app_logo.dart';

class AppTitleBar extends StatefulWidget {
  const AppTitleBar({required this.navigatorKey, super.key});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  Future<void> _onUpdateTap(UpdateViewModel vm) async {
    await vm.checkForUpdate();
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    if (vm.availableUpdate != null) {
      await showUpdateDialogIfNeeded(ctx, forceShow: true);
    } else {
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        const SnackBar(content: Text('Du verwendest die neueste Version!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final themeNotifier = context.watch<ThemeNotifier>();

    return Material(
      color: C.bgPanel,
      child: SizedBox(
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const AppLogo(size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'DungenManager',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          // Update Badge
          Consumer<UpdateViewModel>(
            builder: (_, vm, __) => _UpdateBtn(
              hasUpdate: vm.hasUpdateAvailable,
              onTap: () => _onUpdateTap(vm),
            ),
          ),
          // Dark / Light Mode Toggle
          _WindowButton(
            icon: themeNotifier.isDark ? Icons.light_mode : Icons.dark_mode,
            onTap: themeNotifier.toggle,
          ),
          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Container(width: 1, color: C.border),
          ),
          // Window controls
          _WindowButton(
            icon: Icons.remove,
            onTap: windowManager.minimize,
          ),
          _WindowButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            onTap: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WindowButton(
            icon: Icons.close,
            onTap: windowManager.close,
            isClose: true,
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBtn extends StatefulWidget {
  const _UpdateBtn({required this.hasUpdate, required this.onTap});

  final bool hasUpdate;
  final VoidCallback onTap;

  @override
  State<_UpdateBtn> createState() => _UpdateBtnState();
}

class _UpdateBtnState extends State<_UpdateBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 46,
          height: 48,
          color: _hovered ? C.bgHover : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.download_outlined, size: 15, color: _hovered ? C.text : C.textSoft),
              if (widget.hasUpdate)
                Positioned(
                  top: 11, right: 11,
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: C.green, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final hoverBg = widget.isClose ? const Color(0xFFC42B1C) : C.bgHover;
    final iconColor = (_isHovered && widget.isClose)
        ? Colors.white
        : _isHovered
            ? C.text
            : C.textSoft;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 46,
          height: 48,
          color: _isHovered ? hoverBg : Colors.transparent,
          child: Icon(widget.icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
