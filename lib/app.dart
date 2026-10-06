import 'package:flutter/material.dart';

import 'ui/home_map_page.dart';

class AmsMapaApp extends StatelessWidget {
  const AmsMapaApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0E7C86);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AMS MAPA',
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
