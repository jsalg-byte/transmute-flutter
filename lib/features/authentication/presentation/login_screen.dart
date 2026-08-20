import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initiallyRegistering = false});

  final bool initiallyRegistering;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _registering = widget.initiallyRegistering;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyRegistering != widget.initiallyRegistering) {
      _registering = widget.initiallyRegistering;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _displayNameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDemoMode = ref.watch(repositoryModeProvider) == RepositoryMode.mock;
    final loading = auth.status == AuthStatus.loading;
    final registration = _registering && !isDemoMode;
    final formMode = !isDemoMode;
    final eyebrow = registration ? 'BEGIN THE RECORD' : 'RETURN TO THE WORK';
    final title = registration ? 'Create an\naccount.' : 'Sign in.';
    final description = registration
        ? 'Set up your training space and start turning inputs into evidence.'
        : 'Pick up where you left off and keep building the record.';

    return Scaffold(
      backgroundColor: _paper,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 24,
                  end: 24,
                  top: 10,
                  bottom: 20,
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    const _BackgroundOuroboros(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthHeader(
                          registering: registration,
                          onHome: () => context.go('/'),
                          onToggle: () => context.go(
                            registration ? '/login' : '/login?mode=register',
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: SingleChildScrollView(
                              reverse: true,
                              padding: const EdgeInsets.only(
                                top: 112,
                                bottom: 8,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 560,
                                ),
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(eyebrow, style: _eyebrowStyle),
                                      const SizedBox(height: 16),
                                      Text(title, style: _titleStyle),
                                      const SizedBox(height: 18),
                                      Text(
                                        isDemoMode
                                            ? 'Explore a local, resettable training record without changing your real account.'
                                            : description,
                                        style: _descriptionStyle,
                                      ),
                                      const SizedBox(height: 40),
                                      if (formMode) ...[
                                        _LedgerField(
                                          controller: _username,
                                          autofocus: true,
                                          label: 'Username',
                                          hintText: registration
                                              ? 'Choose a username'
                                              : 'Your username',
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => registration
                                              ? _displayNameFocus.requestFocus()
                                              : _passwordFocus.requestFocus(),
                                          validator: (value) =>
                                              (value?.trim().length ?? 0) < 3
                                              ? 'Enter a 3–64 character username.'
                                              : null,
                                        ),
                                        if (registration) ...[
                                          const SizedBox(height: 24),
                                          _LedgerField(
                                            controller: _displayName,
                                            focusNode: _displayNameFocus,
                                            label: 'Display Name (optional)',
                                            hintText:
                                                'What should we call you?',
                                            autofillHints: const [
                                              AutofillHints.name,
                                            ],
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            onSubmitted: (_) =>
                                                _passwordFocus.requestFocus(),
                                            validator: (value) =>
                                                value != null &&
                                                    value.trim().isNotEmpty &&
                                                    (value.trim().length < 2 ||
                                                        value.trim().length >
                                                            80)
                                                ? 'Use 2–80 characters.'
                                                : null,
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        _LedgerField(
                                          controller: _password,
                                          focusNode: _passwordFocus,
                                          label: 'Password',
                                          hintText: registration
                                              ? 'At least 8 characters'
                                              : 'Your password',
                                          autofillHints: [
                                            registration
                                                ? AutofillHints.newPassword
                                                : AutofillHints.password,
                                          ],
                                          obscureText: true,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => _submit(),
                                          validator: (value) =>
                                              (value?.length ?? 0) < 8
                                              ? 'Enter an 8–128 character password.'
                                              : null,
                                        ),
                                      ],
                                      if (auth.error != null) ...[
                                        const SizedBox(height: 16),
                                        _Notice(message: auth.error!),
                                      ],
                                      const SizedBox(height: 31),
                                      _PrimaryAuthButton(
                                        label: isDemoMode
                                            ? 'Demo Login'
                                            : registration
                                            ? 'Register'
                                            : 'Sign in',
                                        loading: loading,
                                        onPressed: loading
                                            ? null
                                            : isDemoMode
                                            ? _demoLogin
                                            : _submit,
                                      ),
                                      if (!isDemoMode && !registration) ...[
                                        const SizedBox(height: 10),
                                        Center(
                                          child: TextButton(
                                            onPressed: loading
                                                ? null
                                                : _demoLogin,
                                            style: TextButton.styleFrom(
                                              foregroundColor: _oxide,
                                            ),
                                            child: const Text('Use demo login'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_registering) {
      await controller.register(
        _username.text.trim(),
        _password.text,
        displayName: _displayName.text.trim().isEmpty
            ? null
            : _displayName.text.trim(),
      );
    } else {
      await controller.login(_username.text.trim(), _password.text);
    }
  }

  Future<void> _demoLogin() async {
    ref.read(repositoryModeProvider.notifier).select(RepositoryMode.mock);
    await ref
        .read(authControllerProvider.notifier)
        .login('demo', 'transmute-demo');
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.registering,
    required this.onHome,
    required this.onToggle,
  });

  final bool registering;
  final VoidCallback onHome;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onHome,
          child: Row(
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
          ),
        ),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(
            foregroundColor: _ink,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            registering ? 'Sign in' : 'Register',
            style: _headerLinkStyle,
          ),
        ),
      ],
    );
  }
}

class _BackgroundOuroboros extends StatelessWidget {
  const _BackgroundOuroboros();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -212,
      top: -28,
      child: Transform.rotate(
        angle: 0.14,
        child: Opacity(
          opacity: 0.12,
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

class _LedgerField extends StatelessWidget {
  const _LedgerField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.autofillHints,
    required this.textInputAction,
    required this.onSubmitted,
    required this.validator,
    this.focusNode,
    this.autofocus = false,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final String? Function(String?) validator;
  final bool autofocus;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          autofillHints: autofillHints,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: _inputStyle,
          cursorColor: _oxide,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: _hintStyle,
            contentPadding: const EdgeInsets.only(top: 11, bottom: 12),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _oxide),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _oxide, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _destructive),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _destructive, width: 2),
            ),
            errorStyle: const TextStyle(color: _destructive),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: _paper,
          elevation: 0,
          disabledBackgroundColor: _ink.withValues(alpha: 0.55),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (loading) ...[
              const SizedBox(width: 10),
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: _paper, strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _destructive, width: 2)),
        ),
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          message,
          style: const TextStyle(
            color: _destructive,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

const _paper = Color(0xffF4EFE7);
const _ink = Color(0xff101015);
const _body = Color(0xff222328);
const _oxide = Color(0xff667798);
const _destructive = Color(0xffA95B5B);

const _wordmarkStyle = TextStyle(
  color: _ink,
  fontFamily: 'Spectral',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.1,
);

const _headerLinkStyle = TextStyle(
  decoration: TextDecoration.underline,
  decorationColor: _destructive,
  decorationThickness: 1,
  fontFamily: 'Spectral',
  fontSize: 14,
  fontWeight: FontWeight.w800,
);

const _eyebrowStyle = TextStyle(
  color: _oxide,
  fontFamily: 'Spectral',
  fontSize: 12,
  letterSpacing: 1.5,
);

const _titleStyle = TextStyle(
  color: _ink,
  fontFamily: 'Spectral',
  fontSize: 54,
  fontWeight: FontWeight.w900,
  height: 52 / 54,
  letterSpacing: -3,
);

const _descriptionStyle = TextStyle(
  color: _body,
  fontSize: 17,
  fontWeight: FontWeight.w500,
  height: 27 / 17,
);

const _labelStyle = TextStyle(
  color: _body,
  fontSize: 14,
  fontWeight: FontWeight.w800,
);

const _inputStyle = TextStyle(
  color: _ink,
  fontSize: 17,
  fontWeight: FontWeight.w500,
);

const _hintStyle = TextStyle(
  color: Color(0xff858187),
  fontSize: 17,
  fontWeight: FontWeight.w500,
);
