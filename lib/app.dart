import 'package:flutter/material.dart';

import 'ui/home_map_page.dart';

class MtSanAndresApp extends StatelessWidget {
  const MtSanAndresApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0E7C86);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MT San Andres',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        visualDensity: VisualDensity.standard,
      ),
      home: home ?? const HomeMapPage(),
    );
  }
}
