// // import 'package:flutter/material.dart';
// //
// // class SplashScreen extends StatefulWidget {
// //   const SplashScreen({super.key});
// //
// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }
// //
// // class _SplashScreenState extends State<SplashScreen> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         color: Colors.redAccent,
// //         width: double.infinity,
// //         height: double.infinity,
// //         child: Center(
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.center,
// //                 children: [
// //                   const Icon(
// //                     Icons.water_drop,
// //                     color: Colors.white,
// //                     size: 36,
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Text(
// //                     'BloodLink',
// //                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 4),
// //               Padding(
// //                 padding: const EdgeInsets.only(left: 34),
// //                 child: Text(
// //                   'Donate because you can',
// //                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                     color: Colors.white70,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _logoController;
//   late final Animation<double> _fadeAnimation;
//   late final Animation<double> _scaleAnimation;
//   late final Animation<Offset> _taglineSlideAnimation;
//
//   late final AnimationController _dotsController;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Logo + text entrance animation
//     _logoController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//
//     _fadeAnimation = CurvedAnimation(
//       parent: _logoController,
//       curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _logoController,
//         curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
//       ),
//     );
//
//     _taglineSlideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.4),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _logoController,
//         curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
//       ),
//     );
//
//     // Looping dots animation
//     _dotsController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat();
//
//     _logoController.forward();
//   }
//
//   @override
//   void dispose() {
//     _logoController.dispose();
//     _dotsController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         color: Colors.redAccent,
//         width: double.infinity,
//         height: double.infinity,
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: ScaleTransition(
//                   scale: _scaleAnimation,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.water_drop,
//                             color: Colors.white,
//                             size: 39,
//                           ),
//                           const SizedBox(width: 9),
//                           Text(
//                             'BloodLink',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineMedium
//                                 ?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 0),
//                       Padding(
//                         padding: const EdgeInsets.only(left: 29),
//                         child: SlideTransition(
//                           position: _taglineSlideAnimation,
//                           child: FadeTransition(
//                             opacity: _fadeAnimation,
//                             child: Text(
//                               'Donate because you can',
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(
//                                 color: Colors.white70,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               _LoadingDots(controller: _dotsController),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _LoadingDots extends StatelessWidget {
//   const _LoadingDots({required this.controller});
//
//   final AnimationController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: controller,
//       builder: (context, child) {
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(3, (index) {
//             // Stagger each dot's bounce by offsetting its phase
//             final delay = index * 0.2;
//             final t = (controller.value - delay) % 1.0;
//             final bounce = t < 0
//                 ? 0.0
//                 : (t < 0.5
//                 ? Curves.easeOut.transform(t * 2)
//                 : Curves.easeIn.transform((1 - t) * 2));
//
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: Transform.translate(
//                 offset: Offset(0, -8 * bounce),
//                 child: Opacity(
//                   opacity: 0.5 + (0.5 * bounce),
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }





































import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _taglineSlideAnimation;

  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Logo + text entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Looping dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoController.forward();

    // Navigate to onboarding after 3.5 seconds
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    context.go('/onboarding');
    // If not using go_router, replace the line above with:
    // Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.redAccent,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 39,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'BloodBridge',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      Padding(
                        padding: const EdgeInsets.only(left: 29),
                        child: SlideTransition(
                          position: _taglineSlideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Donate because you can',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _LoadingDots(controller: _dotsController),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Stagger each dot's bounce by offsetting its phase
            final delay = index * 0.2;
            final t = (controller.value - delay) % 1.0;
            final bounce = t < 0
                ? 0.0
                : (t < 0.5
                ? Curves.easeOut.transform(t * 2)
                : Curves.easeIn.transform((1 - t) * 2));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Opacity(
                  opacity: 0.5 + (0.5 * bounce),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}