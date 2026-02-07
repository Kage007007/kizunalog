import 'package:flutter/material.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  await NotificationService.instance.initialize();
  runApp(const KizunaLogApp());
}
