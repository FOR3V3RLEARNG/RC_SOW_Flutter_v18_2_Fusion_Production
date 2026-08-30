import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RcSowApp(state: AppState.seeded()));
}
