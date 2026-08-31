import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum AppTab { home, transactions, statistics, settings }

class HomeBottomNav extends StatefulWidget {
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
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 180);
  static const _holdDelay = Duration(milliseconds: 120);
  static const _tabs = AppTab.values;
  static const _lensSize = 64.0;

  final List<GlobalKey> _itemKeys = List<GlobalKey>.generate(
    AppTab.values.length,
    (_) => GlobalKey(),
  );
  final GlobalKey _layerKey = GlobalKey();

  /// Tab under the finger while holding. Independent of [widget.tab].
  int? _focusedIndex;
  bool _isPressing = false;
  bool _holdReady = false;
  int? _pointer;
  double _bubbleLeft = 0;
  double _bubbleTop = 0;
  double _bubbleWidth = 0;
  Duration _slide = Duration.zero;
  Timer? _holdTimer;

  late final AnimationController _press;

  int get _selectedIndex => widget.tab.index;

  bool get _bubbleVisible =>
      _isPressing && _holdReady && _focusedIndex != null && _bubbleWidth >= 8;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _press.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    final index = _indexAt(event.position);
    if (index == null) return;
    _pointer = event.pointer;
    _isPressing = true;
    _holdReady = false;
    _bubbleWidth = 0;
    _focusedIndex = index;
    _press.value = 0;
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDelay, _armBubble);
    setState(() {});
  }

  void _armBubble() {
    if (!mounted || !_isPressing || _focusedIndex == null) return;
    _syncBubble(animate: false);
    if (_bubbleWidth < 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isPressing || _focusedIndex == null) return;
        _syncBubble(animate: false);
        if (_bubbleWidth < 8) return;
        _showBubble();
      });
      return;
    }
    _showBubble();
  }

  void _showBubble() {
    if (!mounted || !_isPressing || _bubbleWidth < 8) return;
    _holdReady = true;
    _press.forward();
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || !_isPressing) return;
    final index = _indexAt(event.position);
    if (index == null || index == _focusedIndex) return;
    setState(() {
      _focusedIndex = index;
      if (_holdReady) _syncBubble(animate: true);
    });
  }

  void _endPress({required bool select}) {
    _pointer = null;
    _holdTimer?.cancel();
    final index = _focusedIndex;
    _isPressing = false;
    _holdReady = false;
    _focusedIndex = null;
    _bubbleWidth = 0;
    _press.value = 0;
    if (select && index != null) {
      widget.onTabSelected?.call(_tabs[index]);
    }
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _endPress(select: true);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _endPress(select: false);
  }

  int? _indexAt(Offset global) {
    final rects = <Rect>[];
    for (var i = 0; i < _itemKeys.length; i++) {
      final rect = _itemGlobalRect(i);
      if (rect == null) return _focusedIndex;
      rects.add(rect);
    }
    for (var i = 0; i < rects.length; i++) {
      if (global.dx >= rects[i].left && global.dx < rects[i].right) {
        return i;
      }
    }
    if (rects.length >= 4 &&
        global.dx >= rects[1].right &&
        global.dx < rects[2].left) {
      // FAB gap: keep the last tab focus. Never treat + as a tab.
      return _focusedIndex;
    }
    return _focusedIndex;
  }

  Rect? _itemGlobalRect(int index) {
    final box =
        _itemKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _itemLocalRect(int index) {
    final itemBox =
        _itemKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (itemBox == null ||
        stackBox == null ||
        !itemBox.hasSize ||
        !stackBox.hasSize) {
      return null;
    }
    final topLeft = stackBox.globalToLocal(itemBox.localToGlobal(Offset.zero));
    return topLeft & itemBox.size;
  }

  void _syncBubble({required bool animate}) {
    final index = _focusedIndex;
    if (index == null) return;
    final rect = _itemLocalRect(index);
    if (rect == null || rect.width < 8) return;
    _slide = animate ? _slideDuration : Duration.zero;
    _bubbleWidth = _lensSize;
    _bubbleLeft = rect.center.dx - _lensSize / 2;
    // Sit on the icon, slightly above the bar so the lens can overflow.
    _bubbleTop = (rect.top + 16) - _lensSize / 2;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = HomeBottomNav._bottomInset(context);
    final width = MediaQuery.sizeOf(context).width;
    final fabSize = HomeBottomNav._fabSizeFor(width);
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
            child: SizedBox(
              width: double.infinity,
              height: HomeBottomNav._barHeight + bottom,
            ),
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
            height: HomeBottomNav._barHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: NoSplash.splashFactory,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    clipBehavior: Clip.none,
                    child: Stack(
                      key: _layerKey,
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            _NavItem(
                              key: const Key('nav-home'),
                              measureKey: _itemKeys[0],
                              outlined: Icons.home_outlined,
                              filled: Icons.home,
                              label: 'Trang chủ',
                              selected: _selectedIndex == 0,
                              focused: _bubbleVisible && _focusedIndex == 0,
                              onTap: () =>
                                  widget.onTabSelected?.call(AppTab.home),
                            ),
                            _NavItem(
                              key: const Key('nav-transactions'),
                              measureKey: _itemKeys[1],
                              outlined: Icons.receipt_long_outlined,
                              filled: Icons.receipt_long,
                              label: 'Giao dịch',
                              selected: _selectedIndex == 1,
                              focused: _bubbleVisible && _focusedIndex == 1,
                              onTap: () => widget.onTabSelected?.call(
                                AppTab.transactions,
                              ),
                            ),
                            SizedBox(width: fabSize),
                            _NavItem(
                              key: const Key('nav-statistics'),
                              measureKey: _itemKeys[2],
                              outlined: Icons.bar_chart_outlined,
                              filled: Icons.bar_chart,
                              label: 'Thống kê',
                              selected: _selectedIndex == 2,
                              focused: _bubbleVisible && _focusedIndex == 2,
                              onTap: () =>
                                  widget.onTabSelected?.call(AppTab.statistics),
                            ),
                            _NavItem(
                              key: const Key('nav-settings'),
                              measureKey: _itemKeys[3],
                              outlined: Icons.settings_outlined,
                              filled: Icons.settings,
                              label: 'Cài đặt',
                              selected: _selectedIndex == 3,
                              focused: _bubbleVisible && _focusedIndex == 3,
                              onTap: () =>
                                  widget.onTabSelected?.call(AppTab.settings),
                            ),
                          ],
                        ),
                        if (_bubbleVisible)
                          AnimatedPositioned(
                            key: const Key('nav-focus-capsule'),
                            duration: _slide,
                            curve: Curves.easeOutCubic,
                            left: _bubbleLeft,
                            top: _bubbleTop,
                            width: _lensSize,
                            height: _lensSize,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _press,
                                builder: (context, _) {
                                  return _FocusLens(
                                    t: Curves.easeOutCubic.transform(
                                      _press.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
              child: _AddActionButton(
                size: fabSize,
                onPressed: widget.onAddPressed,
              ),
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
  static const _scaleUp = 0.10;
  static const _lift = 4.0;
  static const _plusScaleUp = 0.08;
  static const _releaseCurve = Cubic(0.22, 1.18, 0.36, 1);

  late final AnimationController _press;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _t = CurvedAnimation(
      parent: _press,
      curve: Curves.easeOutCubic,
      reverseCurve: _releaseCurve,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusSize = widget.size * 0.42;
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: 'Thêm giao dịch',
      child: Semantics(
        button: true,
        label: 'Thêm giao dịch',
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled ? (_) => _press.forward() : null,
          onPointerUp: enabled ? (_) => _press.reverse() : null,
          onPointerCancel: enabled ? (_) => _press.reverse() : null,
          child: GestureDetector(
            key: const Key('fab-add'),
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) {
                final t = _t.value;
                return Transform.translate(
                  offset: Offset(0, -_lift * t),
                  child: Transform.scale(
                    scale: 1.0 + _scaleUp * t,
                    child: SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (t > 0)
                            IgnorePointer(
                              key: const Key('fab-glass-lens'),
                              child: Transform.scale(
                                scale: 1.24,
                                child: _FocusLens(t: t),
                              ),
                            ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryDark,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.28 + 0.08 * t,
                                    ),
                                    blurRadius: 16 + 4 * t,
                                    offset: Offset(0, 6 - 2 * t),
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
                                  child: Transform.scale(
                                    scale: 1.0 + _plusScaleUp * t,
                                    child: CustomPaint(
                                      painter: _BoldPlusPainter(
                                        color: AppColors.yellow,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    required this.measureKey,
    required this.outlined,
    required this.filled,
    required this.label,
    required this.selected,
    required this.focused,
    this.onTap,
  });

  final GlobalKey measureKey;
  final IconData outlined;
  final IconData filled;
  final String label;
  final bool selected;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = selected || focused;
    final color = highlight ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: KeyedSubtree(
        key: measureKey,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          onTap: onTap,
          child: RepaintBoundary(
            child: AnimatedScale(
              scale: focused ? 1.16 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 44,
                    height: 26,
                    child: Icon(
                      highlight ? filled : outlined,
                      color: color,
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
                      fontWeight: selected
                          ? AppTypography.strongWeight
                          : AppTypography.titleWeight,
                      color: color,
                      letterSpacing: -0.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusLens extends StatelessWidget {
  const _FocusLens({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    if (t <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.86 + 0.14 * t,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0x331A1D26).withValues(alpha: 0.22 * t),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(painter: _GlassLensPainter(t: t)),
          ),
        ),
      ),
    );
  }
}

class _GlassLensPainter extends CustomPainter {
  const _GlassLensPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1.5;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12 * t),
            Colors.white.withValues(alpha: 0.05 * t),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(bounds),
    );

    canvas.drawCircle(
      center + const Offset(-1.1, 0),
      radius,
      Paint()
        ..color = const Color(0xFFFF5FA8).withValues(alpha: 0.28 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      center + const Offset(1.1, 0),
      radius,
      Paint()
        ..color = const Color(0xFF5EC8FF).withValues(alpha: 0.28 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final highlight = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius * 0.86),
        math.pi * 1.15,
        math.pi * 0.55,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassLensPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
