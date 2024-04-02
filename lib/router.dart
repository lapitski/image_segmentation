import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_segmentation/screens/home.dart';
import 'package:image_segmentation/screens/image_segmenter.dart';

class Routes {
  static const String home = '/';
  static const String segmenter = 'segmenter';
}

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: Routes.home,
      builder: (BuildContext context, GoRouterState state) {
        return const Home();
      },
      routes: <RouteBase>[
        GoRoute(
          path: Routes.segmenter,
          builder: (BuildContext context, GoRouterState state) {
            var map = state.extra as Map<String, String>;
            return ImageSegmenter(map['imagePath']!);
          },
        ),
      ],
    ),
  ],
);
