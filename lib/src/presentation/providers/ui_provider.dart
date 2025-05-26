// lib/providers/ui_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the ScrollController
final scrollControllerProvider = Provider.autoDispose<ScrollController>((ref) {
  final controller = ScrollController();

  controller.addListener(() {
    final currentFabVisibility = ref.read(isFabVisibleProvider);

    if (controller.position.pixels >= controller.position.maxScrollExtent &&
        currentFabVisibility) {
      ref.read(isFabVisibleProvider.notifier).state = false;
    } else if (controller.position.pixels <
            controller.position.maxScrollExtent &&
        !currentFabVisibility) {
      ref.read(isFabVisibleProvider.notifier).state = true;
    }
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

// StateProvider for FAB visibility
final isFabVisibleProvider = StateProvider.autoDispose<bool>((ref) => true);
