import 'package:flutter/foundation.dart';

/// Global controller for bottom navigation selected index.
class BottomNavController {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);
}
