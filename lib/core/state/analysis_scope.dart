import 'package:flutter/widgets.dart';

import 'analysis_store.dart';

class AnalysisScope extends InheritedNotifier<AnalysisStore> {
  const AnalysisScope({
    super.key,
    required AnalysisStore store,
    required super.child,
  }) : super(notifier: store);

  static AnalysisStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AnalysisScope>();
    assert(scope != null, 'AnalysisScope is missing above this widget.');
    return scope!.notifier!;
  }
}
