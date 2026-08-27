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

  static const _barHeight = 60.0;
  static const _androidMinSafeBottom = 10.0;

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

  static double _fabSizeFor(double width) {
    return (width * 0.14).clamp(54.0, 58.0);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = _bottomInset(context);
    final width = MediaQuery.sizeOf(context).width;
    final fabSize = _fabSizeFor(width);
    final fabLift = fabSize / 3;
    final sidePad = (width * 0.015).clamp(6.0, 12.0);
    final navMedia = MediaQuery.of(context);
    return MediaQuery(
      data: navMedia.copyWith(
        textScaler: navMedia.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.1,
        ),
      ),
      child: _OverflowHitTestStack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        IgnorePointer(
          child: SizedBox(width: double.infinity, height: _barHeight + bottom),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.navBar,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1A1D26),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          height: _barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  _NavItem(
                    key: const Key('nav-home'),
                    outlined: Icons.home_outlined,
                    filled: Icons.home,
                    label: 'Trang chủ',
                    active: tab == AppTab.home,
                    onTap: () => onTabSelected?.call(AppTab.home),
                  ),
                  _NavItem(
                    key: const Key('nav-transactions'),
                    outlined: Icons.receipt_long_outlined,
                    filled: Icons.receipt_long,
                    label: 'Giao dịch',
                    active: tab == AppTab.transactions,
                    onTap: () => onTabSelected?.call(AppTab.transactions),
                  ),
                  SizedBox(width: fabSize),
                  _NavItem(
                    key: const Key('nav-statistics'),
                    outlined: Icons.bar_chart_outlined,
                    filled: Icons.bar_chart,
                    label: 'Thống kê',
                    active: tab == AppTab.statistics,
                    onTap: () => onTabSelected?.call(AppTab.statistics),
                  ),
                  _NavItem(
                    key: const Key('nav-settings'),
                    outlined: Icons.settings_outlined,
                    filled: Icons.settings,
                    label: 'Cài đặt',
                    active: tab == AppTab.settings,
                    onTap: () => onTabSelected?.call(AppTab.settings),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -fabLift,
          left: 0,
          right: 0,
          height: fabSize,
          child: Center(
            child: _AddActionButton(size: fabSize, onPressed: onAddPressed),
          ),
        ),
      ],
    ),
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

class _AddActionButton extends StatefulWidget {
  const _AddActionButton({required this.size, this.onPressed});

  final double size;
  final VoidCallback? onPressed;

  @override
  State<_AddActionButton> createState() => _AddActionButtonState();
}

class _AddActionButtonState extends State<_AddActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onPressed?.call();
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final plusSize = widget.size * 0.42;
    return Tooltip(
      message: 'Thêm giao dịch',
      child: Semantics(
        button: true,
        label: 'Thêm giao dịch',
        child: GestureDetector(
          key: const Key('fab-add'),
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onPressed == null ? null : (_) => _press.forward(),
          onTapCancel: widget.onPressed == null ? null : _press.reverse,
          onTap: widget.onPressed == null ? null : _handleTap,
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, _) {
              final pressed = Curves.easeOut.transform(_press.value);
              return Transform.scale(
                scale: 1.0 - pressed * 0.06,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDark,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        const BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: plusSize,
                        height: plusSize,
                        child: CustomPaint(
                          painter: _BoldPlusPainter(color: AppColors.yellow),
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
    required this.outlined,
    required this.filled,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData outlined;
  final IconData filled;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppColors.primary : AppColors.textSecondary;
    final labelColor = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 44,
              height: 26,
              child: Icon(
                active ? filled : outlined,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: active
                    ? AppTypography.strongWeight
                    : AppTypography.titleWeight,
                color: labelColor,
                letterSpacing: -0.05,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
