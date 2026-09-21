import 'package:flutter/material.dart';

import 'tutorial_steps.dart';

class TutorialTargets {
  TutorialTargets();

  final overview = GlobalKey(debugLabel: 'tutorial-overview');
  final income = GlobalKey(debugLabel: 'tutorial-income');
  final recurring = GlobalKey(debugLabel: 'tutorial-recurring');
  final spending = GlobalKey(debugLabel: 'tutorial-spending');
  final addButton = GlobalKey(debugLabel: 'tutorial-add');
  final amount = GlobalKey(debugLabel: 'tutorial-amount');
  final category = GlobalKey(debugLabel: 'tutorial-category');
  final save = GlobalKey(debugLabel: 'tutorial-save');
  final backup = GlobalKey(debugLabel: 'tutorial-backup');
  final restore = GlobalKey(debugLabel: 'tutorial-restore');
  final txList = GlobalKey(debugLabel: 'tutorial-tx-list');
  final txFilters = GlobalKey(debugLabel: 'tutorial-tx-filters');
  final statsMonth = GlobalKey(debugLabel: 'tutorial-stats-month');
  final statsCategories = GlobalKey(debugLabel: 'tutorial-stats-categories');

  GlobalKey keyFor(TutorialStep step) {
    return switch (step) {
      TutorialStep.welcome => overview,
      TutorialStep.addButton => addButton,
      TutorialStep.amount => amount,
      TutorialStep.category => category,
      TutorialStep.save => save,
      TutorialStep.txList => txList,
      TutorialStep.txFilters => txFilters,
      TutorialStep.statsMonth => statsMonth,
      TutorialStep.statsCategories => statsCategories,
      TutorialStep.income => income,
      TutorialStep.recurring => recurring,
      TutorialStep.spending => spending,
      TutorialStep.backup => backup,
      TutorialStep.restore => restore,
    };
  }
}

Widget tutorialAnchor({required GlobalKey? key, required Widget child}) {
  if (key == null) return child;
  return KeyedSubtree(key: key, child: child);
}

Rect? tutorialTargetRect({
  required GlobalKey targetKey,
  required BuildContext overlayContext,
}) {
  final targetContext = targetKey.currentContext;
  if (targetContext == null) return null;
  final targetBox = targetContext.findRenderObject();
  final overlayBox = overlayContext.findRenderObject();
  if (targetBox is! RenderBox || overlayBox is! RenderBox) return null;
  if (!targetBox.attached || !overlayBox.attached) return null;
  if (!targetBox.hasSize || !overlayBox.hasSize) return null;
  if (targetBox.size.isEmpty) return null;
  final topLeft = overlayBox.globalToLocal(
    targetBox.localToGlobal(Offset.zero),
  );
  return topLeft & targetBox.size;
}
