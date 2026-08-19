import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDemoMode = ref.watch(repositoryModeProvider) == RepositoryMode.mock;
    final apiLoginAvailable = ref.watch(apiLoginAvailableProvider);
    final loading = auth.status == AuthStatus.loading;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'TRANSMUTE',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDemoMode
                            ? 'Explore a local, resettable training record.'
                            : _registering
                            ? 'Begin your private training record.'
                            : 'Your private training record.',
                      ),
                      const SizedBox(height: 24),
                      if (isDemoMode)
                        Text(
                          'Use the fully interactive local fixture without changing your real Transmute record.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else ...[
                        TextFormField(
                          controller: _username,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (value) => (value?.trim().length ?? 0) < 3
                              ? 'Enter a 3–64 character username.'
                              : null,
                        ),
                        if (_registering) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _displayName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Display name (optional)',
                            ),
                            validator: (value) =>
                                value != null &&
                                    value.trim().isNotEmpty &&
                                    (value.trim().length < 2 ||
                                        value.trim().length > 80)
                                ? 'Use 2–80 characters.'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (value) => (value?.length ?? 0) < 8
                              ? 'Enter an 8–128 character password.'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Color(0xffA33B36)),
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loading
                            ? null
                            : isDemoMode
                            ? _demoLogin
                            : _submit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isDemoMode
                                  ? 'Demo Login'
                                  : _registering
                                  ? 'Create account'
                                  : 'Sign in',
                            ),
                            if (loading) ...[
                              const SizedBox(width: 10),
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isDemoMode) ...[
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => setState(() {
                                  _registering = !_registering;
                                }),
                          child: Text(
                            _registering
                                ? 'Already have an account? Sign in'
                                : 'Create an account',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: loading ? null : _demoLogin,
                          child: const Text('Demo Login'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Demo mode is local and never changes your real record.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (isDemoMode && apiLoginAvailable)
                        TextButton(
                          onPressed: loading ? null : _useRealLogin,
                          child: const Text('Sign in to your account instead'),
                        ),
                    ],
                  ),
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

  void _useRealLogin() {
    ref.read(repositoryModeProvider.notifier).select(RepositoryMode.api);
  }
}
