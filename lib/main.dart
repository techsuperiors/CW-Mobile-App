import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Core
import 'collectivWork.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    // DeviceOrientation.landscapeLeft,
    // DeviceOrientation.landscapeRight,
  ]);

  runApp(const CollectivWorkApp());
}