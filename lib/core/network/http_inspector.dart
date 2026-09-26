import 'package:alice/alice.dart';
import 'package:flutter/foundation.dart';
import 'package:yb_staff_app/core/utils/navigator_key.dart';

final Alice? httpInspector =
    kDebugMode ? (Alice()..setNavigatorKey(appNavigatorKey)) : null;
