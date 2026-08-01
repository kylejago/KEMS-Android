import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/setup_screen.dart';
import 'state/app_controller.dart';
import 'theme/kems_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialise();
  runApp(KemsApp(controller: controller));
}

class KemsApp extends StatefulWidget {
  const KemsApp({super.key, required this.controller});
  final AppController controller;

  @override
  State<KemsApp> createState() => _KemsAppState();
}

class _KemsAppState extends State<KemsApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KEMS Companion',
        debugShowCheckedModeBanner: false,
        theme: KemsTheme.dark(),
        home: widget.controller.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : widget.controller.configured
                ? HomeShell(controller: widget.controller)
                : SetupScreen(controller: widget.controller),
      );
}
