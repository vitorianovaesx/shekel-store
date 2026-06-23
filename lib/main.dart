import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  BackupService.start();
  runApp(const ShekelApp());
}
