// import 'package:flutter/material.dart';
//
// /// 1. Data Model for Onboarding Content
// class OnboardingItem {
//   final String titlePrefix;
//   final String highlightedTitle;
//   final String description;
//   final String imagePath;
//
//   const OnboardingItem({
//     required this.titlePrefix,
//     required this.highlightedTitle,
//     required this.description,
//     required this.imagePath,
//   });
// }
//
// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});
//
//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }
//
// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController = PageController();
//   int _currentIndex = 0;
//
//   /// 2. Content for all 3 Onboarding Screens
//   final List<OnboardingItem> _onboardingPages = const [
//     OnboardingItem(
//       titlePrefix: 'Be the Reason for\nSomeone’s ',
//       highlightedTitle: 'Heartbeat',
//       description:
//       'Connect instantly with nearby verified patients and hospitals in urgent need of your blood type. A single donation saves up to three lives.',
//       imagePath: 'lib/core/constants/assets/animations/xco2_8jtl_220606.jpg',
//     ),
//     OnboardingItem(
//       titlePrefix: 'Verified & Trusted\nEmergency ',
//       highlightedTitle: 'Matching',
//       description:
//       'Hospital-backed requests and direct partner stock fulfillment ensure that every blood request is genuine, secure, and fast.',
//       imagePath: 'lib/core/constants/assets/animations/2706868.jpg',
//     ),
//     OnboardingItem(
//       titlePrefix: 'Real-time Alerts &\nInstant ',
//       highlightedTitle: 'Coordination',
//       description:
//       'Receive instant push notifications when someone nearby needs your blood group. Coordinate safely through private in-app chat.',
//       imagePath: 'lib/core/constants/assets/animations/6262.jpg',
//     ),
//   ];
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   void _onNextPressed() {
//     if (_currentIndex < _onboardingPages.length - 1) {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       _onGetStarted();
//     }
//   }
//
//   void _onGetStarted() {
//     // Navigate to Login or Role Selection Screen
//     // Example: context.go('/login');
//   }
//
//   void _onSkip() {
//     _pageController.animateToPage(
//       _onboardingPages.length - 1,
//       duration: const Duration(milliseconds: 200),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isLastPage = _currentIndex == _onboardingPages.length - 1;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (!isLastPage)
//             TextButton(
//               onPressed: _onSkip,
//               child: const Text(
//                 'Skip',
//                 style: TextStyle(
//                   color: Color(0xFF64748B),
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           const SizedBox(width: 12),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 3. Scrollable PageView Area
//             Expanded(
//               child: PageView.builder(
//                 controller: _pageController,
//                 itemCount: _onboardingPages.length,
//                 onPageChanged: (index) {
//                   setState(() => _currentIndex = index);
//                 },
//                 itemBuilder: (context, index) {
//                   final item = _onboardingPages[index];
//                   return LayoutBuilder(
//                     builder: (context, constraints) {
//                       return SingleChildScrollView(
//                         padding: const EdgeInsets.symmetric(horizontal: 28.0),
//                         child: ConstrainedBox(
//                           constraints: BoxConstraints(
//                             minHeight: constraints.maxHeight,
//                           ),
//                           child: IntrinsicHeight(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const SizedBox(height: 24),
//
//                                 // Image / Illustration Container
//                                 Center(
//                                   child: Container(
//                                     height: 310,
//                                     width: double.infinity,
//                                     decoration: BoxDecoration(
//                                       // color: const Color(0xFFFFF5F5),
//                                       borderRadius: BorderRadius.circular(26),
//                                     ),
//                                     padding: const EdgeInsets.all(20),
//                                     child: Image.asset(
//                                       item.imagePath,
//                                       fit: BoxFit.contain,
//                                       errorBuilder:
//                                           (context, error, stackTrace) =>
//                                       const Icon(
//                                         Icons.bloodtype,
//                                         size: 80,
//                                         color: Color(0xFFE53935),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//
//                                 const SizedBox(height: 32),
//
//                                 // Title with Highlighted Accent Text
//                                 RichText(
//                                   text: TextSpan(
//                                     style: const TextStyle(
//                                       fontSize: 30,
//                                       fontWeight: FontWeight.w800,
//                                       color: Color(0xFF1E293B),
//                                       height: 1.25,
//                                     ),
//                                     children: [
//                                       TextSpan(text: item.titlePrefix),
//                                       TextSpan(
//                                         text: item.highlightedTitle,
//                                         style: const TextStyle(
//                                           color: Color(0xFFE53935),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//
//                                 const SizedBox(height: 16),
//
//                                 // Subtitle / Description Text
//                                 Text(
//                                   item.description,
//                                   style: const TextStyle(
//                                     fontSize: 15,
//                                     color: Color(0xFF64748B),
//                                     height: 1.5,
//                                     fontWeight: FontWeight.w400,
//                                   ),
//                                 ),
//
//                                 const Spacer(),
//                                 const SizedBox(height: 16),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//
//             // 4. Bottom Controls: Indicator Dots (Left) + Next/Get Started Button (Right)
//             Padding(
//               padding: const EdgeInsets.only(
//                 left: 28.0,
//                 right: 28.0,
//                 bottom: 28.0,
//                 top: 8.0,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // --- Left: Animated Dynamic Dots ---
//                   Row(
//                     children: List.generate(
//                       _onboardingPages.length,
//                           (index) => AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         margin: const EdgeInsets.only(right: 8),
//                         height: 8,
//                         width: _currentIndex == index ? 28 : 8,
//                         decoration: BoxDecoration(
//                           color: _currentIndex == index
//                               ? const Color(0xFFE53935)
//                               : const Color(0xFFE2E8F0),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // --- Right: Dynamic Button (Arrow -> "Get Started") ---
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     curve: Curves.easeInOut,
//                     height: 52,
//                     width: isLastPage ? 160 : 58,
//                     clipBehavior: Clip.antiAlias,
//                     decoration: const BoxDecoration(),
//                     child: ElevatedButton(
//                       onPressed: _onNextPressed,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFE53935),
//                         elevation: 4,
//                         shadowColor: const Color(0xFFE53935).withOpacity(0.4),
//                         padding: EdgeInsets.zero,
//                         minimumSize: Size.zero,
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         shape: RoundedRectangleBorder(
//                           borderRadius:
//                           BorderRadius.circular(isLastPage ? 16 : 30),
//                         ),
//                       ),
//                       child: FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 200),
//                           transitionBuilder: (child, animation) =>
//                               FadeTransition(
//                                 opacity: animation,
//                                 child: child,
//                               ),
//                           child: isLastPage
//                               ? const Padding(
//                             key: ValueKey('get_started_btn'),
//                             padding:
//                             EdgeInsets.symmetric(horizontal: 16),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   'Get Started',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(width: 6),
//                                 Icon(
//                                   Icons.arrow_forward_rounded,
//                                   color: Colors.white,
//                                   size: 15,
//                                 ),
//                               ],
//                             ),
//                           )
//                               : const Icon(
//                             Icons.arrow_forward_rounded,
//                             key: ValueKey('arrow_btn'),
//                             color: Colors.white,
//                             size: 28,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



































import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 1. Data Model for Onboarding Content
class OnboardingItem {
  final String titlePrefix;
  final String highlightedTitle;
  final String description;
  final String imagePath;

  const OnboardingItem({
    required this.titlePrefix,
    required this.highlightedTitle,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  /// 2. Content for all 3 Onboarding Screens
  final List<OnboardingItem> _onboardingPages = const [
    OnboardingItem(
      titlePrefix: 'Be the Reason for\nSomeone’s ',
      highlightedTitle: 'Heartbeat',
      description:
      'Connect instantly with nearby verified patients and hospitals in urgent need of your blood type. A single donation saves up to three lives.',
      imagePath: 'lib/core/constants/assets/animations/xco2_8jtl_220606.jpg',
    ),
    OnboardingItem(
      titlePrefix: 'Verified & Trusted\nEmergency ',
      highlightedTitle: 'Matching',
      description:
      'Hospital-backed requests and direct partner stock fulfillment ensure that every blood request is genuine, secure, and fast.',
      imagePath: 'lib/core/constants/assets/animations/2706868.jpg',
    ),
    OnboardingItem(
      titlePrefix: 'Real-time Alerts &\nInstant ',
      highlightedTitle: 'Coordination',
      description:
      'Receive instant push notifications when someone nearby needs your blood group. Coordinate safely through private in-app chat.',
      imagePath: 'lib/core/constants/assets/animations/6262.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentIndex < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    // Navigate to the Login / Sign Up screen
    context.go('/login');
  }

  void _onSkip() {
    // Skipping should also take the user straight to Login, not just
    // jump to the last onboarding page — that was the previous behavior
    // but doesn't match user intent when tapping "Skip".
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentIndex == _onboardingPages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3. Scrollable PageView Area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = _onboardingPages[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),

                                // Image / Illustration Container
                                Center(
                                  child: Container(
                                    height: 310,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset(
                                      item.imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.bloodtype,
                                        size: 80,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Title with Highlighted Accent Text
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      height: 1.25,
                                    ),
                                    children: [
                                      TextSpan(text: item.titlePrefix),
                                      TextSpan(
                                        text: item.highlightedTitle,
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Subtitle / Description Text
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF64748B),
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const Spacer(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 4. Bottom Controls: Indicator Dots (Left) + Next/Get Started Button (Right)
            Padding(
              padding: const EdgeInsets.only(
                left: 28.0,
                right: 28.0,
                bottom: 28.0,
                top: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Left: Animated Dynamic Dots ---
                  Row(
                    children: List.generate(
                      _onboardingPages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentIndex == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? const Color(0xFFE53935)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // --- Right: Dynamic Button (Arrow -> "Get Started") ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 52,
                    width: isLastPage ? 160 : 58,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        elevation: 4,
                        shadowColor: const Color(0xFFE53935).withOpacity(0.4),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(isLastPage ? 16 : 30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                          child: isLastPage
                              ? const Padding(
                            key: ValueKey('get_started_btn'),
                            padding:
                            EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ],
                            ),
                          )
                              : const Icon(
                            Icons.arrow_forward_rounded,
                            key: ValueKey('arrow_btn'),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}