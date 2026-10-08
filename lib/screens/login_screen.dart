import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selected = UserRole.seller;
  final TextEditingController _email =
      TextEditingController(text: 'hanna@threadpos.et');
  final TextEditingController _password =
      TextEditingController(text: 'shop1234');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    context.read<Store>().login(_selected, _email.text.trim());
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _showForgotPassword(BuildContext context) {
    final Pal pal = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Reset your password'),
        content: Text(
          'We will send a reset link to your work email.\n\n'
          'Demo mode: any credentials work offline, so nothing '
          'needs to be sent right now.',
          style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: pal.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: TextStyle(color: pal.muted)),
          ),
          PressableScale(
            child: FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                showSnack(context,
                    'Reset link sent to ${_email.text.trim()}');
              },
              child: const Text('Send link'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    final Store store = context.watch<Store>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Appearance switch, top-right.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ThemeToggle(
                  dark: isDark,
                  onToggle: () => store.setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StaggerIn(
                          index: 0,
                          dy: 16,
                          child: Column(
                            children: <Widget>[
                              const _BrandMark(),
                              const SizedBox(height: 12),
                              Text('ThreadPOS',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.brand(context)),
                              const SizedBox(height: 3),
                              Text('Boutique point of sale',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: pal.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        StaggerIn(
                          index: 1,
                          child: _roleCard(UserRole.seller, 'Seller',
                              'Ring up sales on the floor', Icons.storefront),
                        ),
                        const SizedBox(height: 10),
                        StaggerIn(
                          index: 2,
                          child: _roleCard(UserRole.manager, 'Manager',
                              'Dashboards & control center', Icons.insights),
                        ),
                        const SizedBox(height: 22),
                        StaggerIn(
                          index: 3,
                          child: TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AppTheme.input(context, 'Email',
                                icon: Icons.mail_outline),
                            validator: (String? v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter your email'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggerIn(
                          index: 4,
                          child: TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: AppTheme.input(context, 'Password',
                                icon: Icons.lock_outline),
                            validator: (String? v) =>
                                (v == null || v.length < 4)
                                    ? 'At least 4 characters'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StaggerIn(
                          index: 4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: PressableScale(
                              onTap: () => _showForgotPassword(context),
                              pressedScale: 0.94,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 2),
                                child: Text('Forgot password?',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: pal.accent)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        StaggerIn(
                          index: 5,
                          child: PressableScale(
                            child: FilledButton(
                              style: AppTheme.primaryButton(context),
                              onPressed: _signIn,
                              child: const Text('Sign in to workspace'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggerIn(
                          index: 6,
                          child: Text(
                            'Demo mode — any email & password works offline.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 11, color: pal.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
      UserRole role, String title, String subtitle, IconData icon) {
    final Pal pal = Pal.of(context);
    final bool selected = _selected == role;
    return PressableScale(
      onTap: () => setState(() => _selected = role),
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.out,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? pal.softAccent : pal.surface,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: selected ? pal.accent : pal.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: Motion.base,
              curve: Motion.out,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? pal.accent : pal.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: Motion.fast,
                switchInCurve: Motion.pop,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(selected),
                  color: selected ? Colors.white : pal.ink,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: pal.ink)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: pal.muted)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: Motion.fast,
              switchInCurve: Motion.pop,
              transitionBuilder: (Widget child, Animation<double> anim) =>
                  ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
                child: child,
              ),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                key: ValueKey<bool>(selected),
                color: selected ? pal.accent : pal.muted,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final Pal pal = Pal.of(context);
    return PopIn(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: pal.accent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.checkroom, color: Colors.white, size: 26),
      ),
    );
  }
}
