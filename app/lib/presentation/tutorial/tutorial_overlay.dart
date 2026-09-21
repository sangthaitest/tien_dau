import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'tutorial_steps.dart';
import 'tutorial_targets.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.targetKey,
    required this.onContinue,
    required this.onSkip,
    this.isLast = false,
  });

  final TutorialStep step;
  final GlobalKey targetKey;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final bool isLast;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _moveDuration = Duration(milliseconds: 340);
  static const _fadeDuration = Duration(milliseconds: 280);

  late final AnimationController _fade;
  Rect _hole = Rect.zero;
  int _retries = 0;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: _fadeDuration)
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step ||
        oldWidget.targetKey != widget.targetKey) {
      _retries = 0;
      WidgetsBinding.instance.addPostFrameCallback(_measure);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final rect = tutorialTargetRect(
      targetKey: widget.targetKey,
      overlayContext: context,
    );
    if (rect == null) {
      if (_retries < 24) {
        _retries += 1;
        WidgetsBinding.instance.addPostFrameCallback(_measure);
      }
      return;
    }
    _retries = 0;
    final pad = math.max(rect.shortestSide * 0.06, 8.0);
    final next = rect.inflate(pad);
    if (_rectNearlyEqual(_hole, next)) return;
    setState(() => _hole = next);
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.step.copy;
    final last = widget.isLast;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic),
        child: Material(
          type: MaterialType.transparency,
          child: TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: _hole),
            duration: _moveDuration,
            curve: Curves.easeInOutCubic,
            builder: (context, animated, _) {
              final hole = animated ?? _hole;
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          hole: hole,
                          shape: widget.step.holeShape,
                          radius: widget.step.holeRadius(hole.size),
                          overlayColor: AppColors.dark
                              ? const Color(0xCC07090C)
                              : const Color(0xCC1A1D26),
                          ringColor: AppColors.primary.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                  CustomSingleChildLayout(
                    delegate: _TooltipLayout(
                      hole: hole,
                      padding: MediaQuery.paddingOf(context),
                      size: MediaQuery.sizeOf(context),
                      preferAbove: widget.step.preferTooltipAbove,
                    ),
                    child: Semantics(
                      container: true,
                      label: copy.title,
                      child: _TutorialCard(
                        title: copy.title,
                        description: copy.description,
                        primaryLabel: last ? 'Bắt đầu sử dụng' : 'Tiếp tục',
                        showSkip: !last,
                        onPrimary: widget.onContinue,
                        onSkip: widget.onSkip,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.showSkip,
    required this.onPrimary,
    required this.onSkip,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final bool showSkip;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSkip)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('tutorial-skip'),
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Bỏ qua'),
                ),
              ),
            Text(
              title,
              key: const Key('tutorial-title'),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: AppTypography.extraWeight,
                height: 1.25,
                letterSpacing: -0.25,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              key: const Key('tutorial-description'),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: AppTypography.bodyWeight,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('tutorial-next'),
              onPressed: onPrimary,
              child: Text(
                primaryLabel,
                style: AppTypography.button(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipLayout extends SingleChildLayoutDelegate {
  const _TooltipLayout({
    required this.hole,
    required this.padding,
    required this.size,
    required this.preferAbove,
  });

  final Rect hole;
  final EdgeInsets padding;
  final Size size;
  final bool preferAbove;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final side = math.max(size.width * 0.06, padding.horizontal / 2);
    final maxWidth = math.min(size.width - side * 2, size.shortestSide * 0.92);
    return BoxConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: size.height - padding.vertical - size.height * 0.08,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final side = math.max(this.size.width * 0.06, padding.left);
    final minLeft = side;
    final maxLeft = math.max(minLeft, size.width - side - childSize.width);
    var left = hole.center.dx - childSize.width / 2;
    if (hole == Rect.zero) {
      left = (size.width - childSize.width) / 2;
    }
    left = left.clamp(minLeft, maxLeft);

    final gap = math.max(this.size.shortestSide * 0.018, 10.0);
    final minTop = padding.top + gap;
    final maxTop = size.height - padding.bottom - childSize.height - gap;
    final below = hole.bottom + gap;
    final above = hole.top - gap - childSize.height;
    final spaceBelow = size.height - padding.bottom - below;
    final spaceAbove = hole.top - padding.top;

    double top;
    final useAbove =
        preferAbove ||
        (spaceBelow < childSize.height && spaceAbove > spaceBelow);
    if (hole == Rect.zero) {
      top = size.height * 0.38;
    } else if (useAbove) {
      top = above;
    } else {
      top = below;
    }
    if (maxTop < minTop) {
      top = minTop;
    } else {
      top = top.clamp(minTop, maxTop);
    }
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _TooltipLayout oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.padding != padding ||
        oldDelegate.size != size ||
        oldDelegate.preferAbove != preferAbove;
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.shape,
    required this.radius,
    required this.overlayColor,
    required this.ringColor,
  });

  final Rect hole;
  final TutorialHoleShape shape;
  final double radius;
  final Color overlayColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    if (hole.width <= 1 || hole.height <= 1) {
      canvas.drawRect(bounds, Paint()..color = overlayColor);
      return;
    }
    final holePath = Path();
    if (shape == TutorialHoleShape.circle) {
      holePath.addOval(
        Rect.fromCircle(center: hole.center, radius: hole.shortestSide / 2),
      );
    } else {
      holePath.addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    }
    final overlay = Path()
      ..addRect(bounds)
      ..addPath(holePath, Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = overlayColor);
    canvas.drawPath(
      holePath,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.shape != shape ||
        oldDelegate.radius != radius ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.ringColor != ringColor;
  }
}

bool _rectNearlyEqual(Rect a, Rect b) {
  return (a.left - b.left).abs() < 0.5 &&
      (a.top - b.top).abs() < 0.5 &&
      (a.width - b.width).abs() < 0.5 &&
      (a.height - b.height).abs() < 0.5;
}
