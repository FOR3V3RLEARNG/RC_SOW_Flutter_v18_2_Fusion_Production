import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'services/production_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = await ProductionBackendFactory.create();
  final state = AppState.production(backend: backend);
  await state.bootstrapSession();
  runApp(RcSowApp(state: state));
}
