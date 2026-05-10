import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/medication_provider.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Services with Safety Net
  try {
    // Try to initialize notifications but don't let a failure block the app
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('Notification initialization timed out'),
    );
  } catch (e) {
    debugPrint('Service Initialization Error: $e');
  }

  // 3. Launch App
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MedicationProvider())],
      child: const MedTimeApp(),
    ),
  );
}
