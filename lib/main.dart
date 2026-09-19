import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers with backoff by default. Our
      // screens own retry via explicit buttons / pull-to-refresh, so a dead
      // backend shouldn't spin every list provider in the background.
      retry: (retryCount, error) => null,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BLOOD-BRIDGE - Blood Donation App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryRed),
        scaffoldBackgroundColor: AppColors.bgGrey,
      ),
      routerConfig: router,
    );
  }
}
