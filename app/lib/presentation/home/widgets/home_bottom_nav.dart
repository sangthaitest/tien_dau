import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum AppTab { home, transactions, statistics, settings }

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.onAddPressed,
    this.tab = AppTab.home,
    this.onTabSelected,
  });

  final VoidCallback? onAddPressed;
  final AppTab tab;
  final ValueChanged<AppTab>? onTabSelected;

  static const _barHeight = 78.0;
  static const _fabSize = 72.0;
  static const _fabLift = 18.0;
  static const _notchMargin = 7.0;

  /// Demo `--safe-bottom`. Android often reports 0 while drawing
  /// edge-to-edge, which clips the nav labels against the screen edge.
  static const _androidMinSafeBottom = 22.0;

  static double _bottomInset(BuildContext context) {
    final inset = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    if (Theme.of(context).platform == TargetPlatform.android) {
      return math.max(inset, _androidMinSafeBottom);
    }
    return inset;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = _bottomInset(context);
    return _OverflowHitTestStack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Must be full-width: a height-only SizedBox shrinks to 0 under Column,
        // so the plus paints overflowing but cannot receive taps.
        IgnorePointer(
          child: SizedBox(width: double.infinity, height: _barHeight + bottom),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _NotchedBarPainter(
              color: AppColors.navBar,
              borderColor: AppColors.cardBorder,
              fabSize: _fabSize,
              fabLift: _fabLift,
              notchMargin: _notchMargin,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          height: _barHeight,
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                _NavItem(
                  key: const Key('nav-home'),
                  icon: Icons.home_outlined,
                  label: 'Trang chủ',
                  active: tab == AppTab.home,
                  onTap: () => onTabSelected?.call(AppTab.home),
                ),
                _NavItem(
                  key: const Key('nav-transactions'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Giao dịch',
                  active: tab == AppTab.transactions,
                  onTap: () => onTabSelected?.call(AppTab.transactions),
                ),
                const Expanded(child: SizedBox.shrink()),
                _NavItem(
                  key: const Key('nav-statistics'),
                  icon: Icons.bar_chart_outlined,
                  label: 'Thống kê',
                  active: tab == AppTab.statistics,
                  onTap: () => onTabSelected?.call(AppTab.statistics),
                ),
                _NavItem(
                  key: const Key('nav-settings'),
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt',
                  active: tab == AppTab.settings,
                  onTap: () => onTabSelected?.call(AppTab.settings),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -_fabLift,
          left: 0,
          right: 0,
          height: _fabSize,
          child: Center(
            child: _AddActionButton(size: _fabSize, onPressed: onAddPressed),
          ),
        ),
      ],
    );
  }
}

/// Lets the protruding FAB receive taps that sit above the nav's layout box.
class _OverflowHitTestStack extends Stack {
  const _OverflowHitTestStack({
    super.alignment,
    super.clipBehavior,
    super.children,
  });

  @override
  _RenderOverflowHitTestStack createRenderObject(BuildContext context) {
    return _RenderOverflowHitTestStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverflowHitTestStack renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class _RenderOverflowHitTestStack extends RenderStack {
  _RenderOverflowHitTestStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) ||
        (size.contains(position) && hitTestSelf(position))) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.color,
    required this.borderColor,
    required this.fabSize,
    required this.fabLift,
    required this.notchMargin,
  });

  final Color color;
  final Color borderColor;
  final double fabSize;
  final double fabLift;
  final double notchMargin;

  Path _path(Size size) {
    final host = Offset.zero & size;
    final guest = Rect.fromCircle(
      center: Offset(size.width / 2, fabSize / 2 - fabLift),
      radius: fabSize / 2 + notchMargin,
    );
    return const CircularNotchedRectangle().getOuterPath(host, guest);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawPath(path, Paint()..color = color);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -2, size.width, fabSize - fabLift + 18));
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fabSize != fabSize ||
        oldDelegate.fabLift != fabLift ||
        oldDelegate.notchMargin != notchMargin;
  }
}

class _AddActionButton extends StatefulWidget {
  const _AddActionButton({required this.size, this.onPressed});

  final double size;
  final VoidCallback? onPressed;

  @override
  State<_AddActionButton> createState() => _AddActionButtonState();
}

class _AddActionButtonState extends State<_AddActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _press;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_skipAmbient) {
        _enter.value = 1;
        return;
      }
      _enter.forward().then((_) => _playIdleGlow());
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _press.dispose();
    _glow.dispose();
    super.dispose();
  }

  bool get _skipAmbient {
    return !TickerMode.valuesOf(context).enabled ||
        MediaQuery.disableAnimationsOf(context) ||
        WidgetsBinding.instance.runtimeType.toString().contains(
          'TestWidgetsFlutterBinding',
        );
  }

  Future<void> _playIdleGlow() async {
    if (!mounted || _skipAmbient) return;
    for (var i = 0; i < 2; i++) {
      if (!mounted) return;
      await _glow.forward();
      if (!mounted) return;
      await _glow.reverse();
    }
  }

  void _handleTap() {
    widget.onPressed?.call();
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final yellow = AppColors.yellow;
    final plus = AppColors.primary;
    return RepaintBoundary(
      child: Tooltip(
        message: 'Thêm giao dịch',
        child: Semantics(
          button: true,
          label: 'Thêm giao dịch',
          child: GestureDetector(
            key: const Key('fab-add'),
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onPressed == null
                ? null
                : (_) => _press.forward(),
            onTapCancel: widget.onPressed == null ? null : _press.reverse,
            onTap: widget.onPressed == null ? null : _handleTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([_enter, _press, _glow]),
              builder: (context, _) {
                final enterScale = Tween<double>(begin: 0.86, end: 1.0)
                    .transform(
                      Curves.easeOutBack.transform(
                        _enter.value.clamp(0.0, 1.0),
                      ),
                    );
                final pressed = _press.status == AnimationStatus.reverse
                    ? 1.0 - Curves.easeOutBack.transform(1.0 - _press.value)
                    : Curves.easeOut.transform(_press.value);
                final glow = 0.28 + _glow.value * 0.14;
                final scale = enterScale * (1.0 - pressed * 0.07);
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(yellow, Colors.white, 0.18)!,
                            yellow,
                            Color.lerp(yellow, const Color(0xFFE0A820), 0.16)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: yellow.withValues(alpha: glow),
                            blurRadius: 22 + _glow.value * 8,
                            spreadRadius: 1 + _glow.value * 1.4,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: const Color(0x14000000),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: CustomPaint(
                            painter: _BoldPlusPainter(color: plus),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BoldPlusPainter extends CustomPainter {
  const _BoldPlusPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    final inset = size.width * 0.06;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      Offset(inset, center.dy),
      Offset(size.width - inset, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, inset),
      Offset(center.dx, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoldPlusPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 50,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              )
            else
              SizedBox(
                width: 50,
                height: 32,
                child: Icon(icon, color: color, size: 25),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active
                    ? AppTypography.titleWeight
                    : AppTypography.metadataWeight,
                color: color,
                letterSpacing: -0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
