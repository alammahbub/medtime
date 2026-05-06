import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/medication_provider.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MedicationProvider())],
      child: const MedTimeApp(),
    ),
  );
}
