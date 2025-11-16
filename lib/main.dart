import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'illustrations/event_illustrations.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
 
void main() {
  runApp(const EventsApp());
}

class EventsApp extends StatelessWidget {
  const EventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Events Onboarding',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A62FF)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    this.images,
    this.illustration,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.centerContent = false,
    this.descriptionColor,
    this.visualAlignment = Alignment.topCenter,
    this.visualTopInset = 0,
    this.visualLeft,
    this.visualTop,
    this.visualWidth,
    this.visualHeight,
    this.imageHeightFactor,
    this.imageMaxHeight,
  }) : assert(
         (images != null && illustration == null) ||
             (images == null && illustration != null),
         'Provide either images or an illustration widget',
       );

  final List<String>? images;
  final Widget? illustration;
  final String title; 
  final String description;
  final String buttonLabel;
  final bool centerContent;
  final Color? descriptionColor;
  final Alignment visualAlignment;
  final double visualTopInset;
  final double? visualLeft; // نسبة من العرض (0.0 - 1.0)
  final double? visualTop; // نسبة من الارتفاع (0.0 - 1.0)
  final double? visualWidth; // نسبة من العرض (0.0 - 1.0)
  final double? visualHeight; // نسبة من الارتفاع (0.0 - 1.0)
  final double? imageHeightFactor;
  final double? imageMaxHeight;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _backgroundController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      illustration: OverlappingShapesIllustration(),
      title: 'Discover the best events near you',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do '
          'eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      buttonLabel: 'Next',
      centerContent: true,
      visualTopInset: 0,
    ),
    OnboardingPageData(
      illustration: CirclePlaceholderIllustration(),
      title: 'Easy payment & fast event ticketing',
      description: 'Easy payment & fast event ticketing',
      buttonLabel: 'Next',
      centerContent: true,
      descriptionColor: Color(0xFF9E9E9E),
      visualAlignment: Alignment.center,
      visualTopInset: 0,
    ),
    OnboardingPageData(
      images: ['assets/images/tt.png'],
      title: 'Stay connected & never miss a moment',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do '
          'eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      buttonLabel: 'Get Started',
      centerContent: true,
      descriptionColor: Color(0xFF9E9E9E),
      visualTopInset: 0,
      visualAlignment: Alignment.topCenter,
      visualLeft: 0.09,
      visualTop: 0.22,
      visualWidth: 0.82,
      visualHeight: 0.62,
    ),
  ];

  final List<_CircleConfig> _circleConfigs = const [
    _CircleConfig(
      begin: Alignment(-1.1, -0.9),
      end: Alignment(-0.7, -0.4),
      color: Color(0xFFFF8A65), // soft orange
      size: 26,
      delay: 0.0,
    ),
    _CircleConfig(
      begin: Alignment(1.0, -0.5),
      end: Alignment(0.7, -0.1),
      color: Color(0xFFE57373), // soft red
      size: 18,
      delay: 0.2,
    ),
    _CircleConfig(
      begin: Alignment(-0.6, 0.8),
      end: Alignment(-0.2, 0.6),
      color: Color(0xFF9575CD), // soft purple
      size: 20,
      delay: 0.4,
    ),
    _CircleConfig(
      begin: Alignment(0.8, 0.9),
      end: Alignment(0.5, 0.6),
      color: Color(0xFFFFB74D), // warm orange
      size: 14,
      delay: 0.6,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final isLastPage = _currentPage == _pages.length - 1;
    if (isLastPage) {
      _navigateToAuth();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          onBackRequested: (authContext) {
            Navigator.of(authContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const OnboardingScreen(),
              ),
            );
          },
          onCompleted: (authContext) {
            Navigator.of(authContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const HomeScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            _AnimatedCirclesBackground(
              animation: _backgroundController,
              configs: _circleConfigs,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _navigateToAuth,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _OnboardingContent(
                        data: page,
                        isActive: index == _currentPage,
                        pageIndex: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageDotsIndicator(
                        count: _pages.length,
                        currentIndex: _currentPage,
                      ),
                      const SizedBox(height: 24),
                      _GradientButton(
                        label: _pages[_currentPage].buttonLabel,
                        onPressed: _handleNext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatefulWidget {
  const _OnboardingContent({required this.data, required this.isActive, required this.pageIndex});

  final OnboardingPageData data;
  final bool isActive;
  final int pageIndex;

  @override
  State<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends State<_OnboardingContent> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildIllustration() {
      final hasCustomPosition = widget.data.visualLeft != null &&
          widget.data.visualTop != null &&
          widget.data.visualWidth != null &&
          widget.data.visualHeight != null;

      if (hasCustomPosition) {
        // لا نعيد Positioned هنا، سنستخدمه مباشرة في Stack
        return _OnboardingVisual(data: widget.data, skipPositioning: true);
      }
      return _OnboardingVisual(data: widget.data);
    }

    Widget buildTitle() {
      return Text(
        widget.data.title,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: const Color(0xFF1E1E1E),
          fontWeight:
              widget.data.centerContent ? FontWeight.w700 : FontWeight.w600,
          height: widget.data.centerContent ? 1.25 : 1.2,
        ),
        textAlign:
            widget.data.centerContent ? TextAlign.center : TextAlign.start,
      );
    }

    Widget buildSubtitle() {
      return Text(
        widget.data.description,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: widget.data.descriptionColor ?? const Color(0xFF707070),
          height: widget.data.centerContent ? 1.6 : 1.5,
          fontSize: widget.data.centerContent ? 14 : null,
        ),
        textAlign:
            widget.data.centerContent ? TextAlign.center : TextAlign.start,
      );
    }

    // إذا كان هناك موقع محدد، استخدم Stack
    final hasCustomPosition = widget.data.visualLeft != null &&
        widget.data.visualTop != null &&
        widget.data.visualWidth != null &&
        widget.data.visualHeight != null;

    if (hasCustomPosition) {
      return Padding(
        key: ValueKey(widget.data.title),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageLeft = constraints.maxWidth * widget.data.visualLeft!;
            final imageTop = constraints.maxHeight * widget.data.visualTop!;
            final imageWidth = constraints.maxWidth * widget.data.visualWidth!;
            final imageHeight = constraints.maxHeight * widget.data.visualHeight!;

            return SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: imageLeft,
                    top: imageTop,
                    width: imageWidth,
                    height: imageHeight,
                    child: buildIllustration(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: widget.data.centerContent
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        buildTitle(),
                        SizedBox(height: widget.data.centerContent ? 12 : 16),
                        buildSubtitle(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Padding(
        key: ValueKey(widget.data.title),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: widget.data.centerContent
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(child: buildIllustration()),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: widget.data.centerContent
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                buildTitle(),
                SizedBox(height: widget.data.centerContent ? 12 : 16),
                buildSubtitle(),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.images,
    this.heightFactor,
    this.maxHeight,
  });

  final List<String> images;
  final double? heightFactor;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSecondaryImage = images.length > 1;
        final targetHeightFactor = heightFactor ?? 0.65;
        final targetMaxHeight = maxHeight ?? 320.0;
        final primaryHeight =
            math.min(constraints.maxHeight * targetHeightFactor, targetMaxHeight);
        final secondarySize = math.min(primaryHeight * 0.48, targetMaxHeight * 0.5);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: primaryHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  images.first,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            if (hasSecondaryImage)
              Positioned(
                right: 0,
                bottom: 16,
                child: Container(
                  width: secondarySize,
                  height: secondarySize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      images[1],
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.data, this.skipPositioning = false});

  final OnboardingPageData data;
  final bool skipPositioning;

  @override
  Widget build(BuildContext context) {
    if (data.illustration != null) {
      return Padding(
        padding: EdgeInsets.only(top: data.visualTopInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heightFactor = data.centerContent ? 0.9 : 0.8;
            final maxDimension = data.centerContent ? 360.0 : 320.0;
            final maxHeight =
                math.min(constraints.maxHeight * heightFactor, maxDimension);

            return Align(
              alignment: data.visualAlignment,
              child: SizedBox(
                height: maxHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: maxDimension,
                    height: maxDimension,
                    child: data.illustration,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final images = data.images;
    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }

    // إذا كانت هناك قيم محددة للموقع والأبعاد وكان skipPositioning = false
    // (عندما skipPositioning = true، يتم التعامل مع التموضع في الـ parent)
    if (!skipPositioning &&
        data.visualLeft != null &&
        data.visualTop != null &&
        data.visualWidth != null &&
        data.visualHeight != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final imageLeft = constraints.maxWidth * data.visualLeft!;
          final imageTop = constraints.maxHeight * data.visualTop!;
          final imageWidth = constraints.maxWidth * data.visualWidth!;
          final imageHeight = constraints.maxHeight * data.visualHeight!;

          return Positioned(
            left: imageLeft,
            top: imageTop,
            width: imageWidth,
            height: imageHeight,
            child: _OnboardingIllustration(images: images),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: data.visualTopInset),
      child: _OnboardingIllustration(
        images: images,
        heightFactor: data.imageHeightFactor,
        maxHeight: data.imageMaxHeight,
      ),
    );
  }
}

class _PageDotsIndicator extends StatelessWidget {
  const _PageDotsIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6A62FF) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A62FF), Color(0xFF8A6DF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336A62FF),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AnimatedCirclesBackground extends StatelessWidget {
  const _AnimatedCirclesBackground({
    required this.animation,
    required this.configs,
  });

  final Animation<double> animation;
  final List<_CircleConfig> configs;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Stack(
            children: [
              for (final config in configs)
                Align(
                  alignment: _alignmentFor(config),
                  child: Container(
                    width: config.size,
                    height: config.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config.color.withValues(
                        alpha: math.min(
                          1.0,
                          math.max(0.0, 0.18 + 0.12 * animation.value),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Alignment _alignmentFor(_CircleConfig config) {
    final loopValue = (animation.value + config.delay) % 1.0;
    final mirroredValue = loopValue < 0.5
        ? loopValue * 2.0
        : (1.0 - loopValue) * 2.0;
    return Alignment.lerp(config.begin, config.end, mirroredValue)!;
  }
}

class _CircleConfig {
  const _CircleConfig({
    required this.begin,
    required this.end,
    required this.color,
    required this.size,
    required this.delay,
  });

  final Alignment begin;
  final Alignment end;
  final Color color;
  final double size;
  final double delay;
}
