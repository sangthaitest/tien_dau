import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

void traceInteraction(String name) {
  developer.Timeline.instantSync(name);
  if (const bool.fromEnvironment('TD_PERF')) {
    debugPrint('TD_PERF $name');
  }
}
