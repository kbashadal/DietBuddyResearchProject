import 'package:dietbuddy/consts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'user_provider.dart';
import 'my_app.dart';

Future main() async {
  await loadEnv();
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}
