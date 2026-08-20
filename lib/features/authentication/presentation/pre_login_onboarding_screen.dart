import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PreLoginOnboardingScreen extends StatefulWidget {
  const PreLoginOnboardingScreen({super.key});

  @override
  State<PreLoginOnboardingScreen> createState() =>
      _PreLoginOnboardingScreenState();
}

class _PreLoginOnboardingScreenState extends State<PreLoginOnboardingScreen> {
  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      stage: '01 — NIGREDO',
      operation: 'THE BLACKENING',
      title: 'Begin with the\nraw material.',
      description:
          'Record the work as it is. Every set, meal, recovery day, and missed mark becomes material for change.',
    ),
    _OnboardingSlide(
      stage: '02 — ALBEDO',
      operation: 'THE WHITENING',
      title: 'Separate signal\nfrom noise.',
      description:
          'Bring training, recovery, and nutrition into one clear record. Patterns emerge when the work is stripped to what matters.',
    ),
    _OnboardingSlide(
      stage: '03 — RUBEDO',
      operation: 'THE REDDENING',
      title: 'Turn insight\ninto form.',
      description:
          'See the pattern, keep what works, and refine the process until effort becomes evidence.',
    ),
  ];

  int _page = 0;

  void _advance() {
    if (_page == _slides.length - 1) {
      context.go('/login?mode=register');
      return;
    }
    setState(() => _page += 1);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLastSlide = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 24,
                end: 24,
                top: 10,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Wordmark(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _SlideContent(
                        key: ValueKey(_page),
                        page: _page,
                        slide: slide,
                      ),
                    ),
                  ),
                  _PrimaryButton(
                    label: isLastSlide ? 'Create account' : 'Continue',
                    onPressed: _advance,
                  ),
                  SizedBox(
                    height: 34,
                    child: isLastSlide
                        ? Align(
                            alignment: Alignment.bottomLeft,
                            child: Text.rich(
                              TextSpan(
                                style: _accountPromptStyle,
                                children: [
                                  const TextSpan(
                                    text: 'Already have an account? ',
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: InkWell(
                                      onTap: () => context.go('/login'),
                                      child: const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: _body,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                          decorationColor: _oxide,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({super.key, required this.page, required this.slide});

  final int page;
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        _TransmutationMotif(page: page),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 35),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slide.stage, style: _stageStyle),
                  const SizedBox(height: 13),
                  Text(slide.operation, style: _operationStyle),
                  const SizedBox(height: 13),
                  Text(slide.title, style: _titleStyle),
                  const SizedBox(height: 19),
                  Text(slide.description, style: _descriptionStyle),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/transmute/ouroboros.svg',
          width: 38,
          height: 38,
          colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
        ),
        const SizedBox(width: 10),
        const Text('TRANSMUTE', style: _wordmarkStyle),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: _paper,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _TransmutationMotif extends StatelessWidget {
  const _TransmutationMotif({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    if (page == 2) return const _RubedoMotif();
    return Positioned(
      right: -70,
      top: 5,
      child: SizedBox(
        height: 410,
        width: 410,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 24,
              top: 24,
              child: Container(
                height: 365,
                width: 365,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: page == 0
                        ? _ink.withValues(alpha: 0.25)
                        : _oxide.withValues(alpha: 0.30),
                    width: 3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 72,
              top: 71,
              child: Container(
                height: 270,
                width: 270,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xffA95B5B).withValues(alpha: 0.35),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: page == 0 ? 133 : 125,
              child: Transform.rotate(
                angle: 0.34,
                child: Container(
                  height: page == 0 ? 100 : 90,
                  width: page == 0 ? 170 : 160,
                  color: _paper,
                ),
              ),
            ),
            Positioned(
              bottom: page == 0 ? 20 : 16,
              left: page == 0 ? 38 : 25,
              child: Transform.rotate(
                angle: -0.40,
                child: Container(
                  height: page == 0 ? 84 : 80,
                  width: 133,
                  color: _paper,
                ),
              ),
            ),
            if (page == 0) ...[
              Positioned(
                left: 84,
                top: 53,
                child: Container(
                  height: 72,
                  width: 95,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _ink.withValues(alpha: 0.30)),
                      top: BorderSide(color: _ink.withValues(alpha: 0.30)),
                    ),
                  ),
                ),
              ),
              _Symbol(
                asset: 'assets/transmute/putrefaction.svg',
                left: 40,
                top: 72,
                width: 190,
                height: 190,
                opacity: 0.38,
              ),
              _Symbol(
                asset: 'assets/transmute/black-sulfur.svg',
                left: 191,
                top: 218,
                width: 116,
                height: 116,
                opacity: 0.52,
              ),
            ] else ...[
              _Symbol(
                asset: 'assets/transmute/water.svg',
                left: 230,
                top: 54,
                width: 112,
                height: 112,
                opacity: 0.58,
              ),
              _Symbol(
                asset: 'assets/transmute/purify.svg',
                left: 87,
                top: 205,
                width: 122,
                height: 122,
                opacity: 0.46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RubedoMotif extends StatelessWidget {
  const _RubedoMotif();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -150,
      top: 0,
      child: Transform.rotate(
        angle: 0.14,
        child: Opacity(
          opacity: 0.25,
          child: SvgPicture.asset(
            'assets/transmute/ouroboros.svg',
            width: 500,
            height: 500,
            colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol({
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
  });

  final String asset;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: SvgPicture.asset(
          asset,
          width: width,
          height: height,
          colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.stage,
    required this.operation,
    required this.title,
    required this.description,
  });

  final String stage;
  final String operation;
  final String title;
  final String description;
}

const _paper = Color(0xffF4EFE7);
const _ink = Color(0xff101015);
const _body = Color(0xff222328);
const _oxide = Color(0xff6D79A0);

const _wordmarkStyle = TextStyle(
  color: _ink,
  fontSize: 15,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.1,
);

const _stageStyle = TextStyle(color: _oxide, fontSize: 12, letterSpacing: 1.5);

const _operationStyle = TextStyle(
  color: _body,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.1,
);

const _titleStyle = TextStyle(
  color: _ink,
  fontSize: 49,
  fontWeight: FontWeight.w900,
  height: 47 / 49,
  letterSpacing: -2.8,
);

const _descriptionStyle = TextStyle(
  color: _body,
  fontSize: 17,
  fontWeight: FontWeight.w500,
  height: 27 / 17,
);

const _accountPromptStyle = TextStyle(
  color: _body,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
