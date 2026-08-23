import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'services/db_service.dart';
import 'store/doubt_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing (fresh install/CI) — solve attempt par clear error dikhega.
    debugPrint('[solver] .env load nahi hua — API calls error denge jab tak set na ho');
  }
  runApp(MultiProvider(
    providers: [
      Provider<DbService>(create: (_) => DbService()),
      ChangeNotifierProvider<DoubtStore>(create: (ctx) => DoubtStore(ctx.read<DbService>())),
    ],
    child: const SolverApp(),
  ));
}

class SolverApp extends StatelessWidget {
  const SolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doubt Solver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RootShell(),
    );
  }
}
