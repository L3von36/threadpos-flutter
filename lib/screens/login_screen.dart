import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/store.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Column(
                    children: <Widget>[
                      SizedBox(height: 8),
                      _BrandMark(),
                      SizedBox(height: 12),
                      Text('ThreadPOS',
                          textAlign: TextAlign.center,
                          style: AppTheme.brand),
                      SizedBox(height: 3),
                      Text('Boutique point of sale',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.muted)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _roleCard(UserRole.seller, 'Seller',
                      'Ring up sales on the floor', Icons.storefront),
                  const SizedBox(height: 10),
                  _roleCard(UserRole.manager, 'Manager',
                      'Dashboards & control center', Icons.insights),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        AppTheme.input('Email', icon: Icons.mail_outline),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Enter your email'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration:
                        AppTheme.input('Password', icon: Icons.lock_outline),
                    validator: (String? v) =>
                        (v == null || v.length < 4)
                            ? 'At least 4 characters'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: AppTheme.primaryButton,
                    onPressed: _signIn,
                    child: const Text('Sign in to workspace'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demo mode — any email & password works offline.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
      UserRole role, String title, String subtitle, IconData icon) {
    final bool selected = _selected == role;
    return GestureDetector(
      onTap: () => setState(() => _selected = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.terracotta.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: selected ? AppTheme.terracotta : AppTheme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppTheme.terracotta : AppTheme.creamDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppTheme.ink, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.muted)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color:
                  selected ? AppTheme.terracotta : AppTheme.muted,
              size: 19,
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
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.terracotta,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.checkroom, color: Colors.white, size: 26),
    );
  }
}
