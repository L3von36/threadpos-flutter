import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                    color: AppTheme.sage, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Sale complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text('Receipt #${sale.id} · ${clockLabel(sale.time)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.muted)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                            '${paymentMethodLabel(sale.method)} · ${sale.itemCount} item(s)',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.muted)),
                        Text(money(sale.total),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.terracotta)),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ...sale.lines.map(
                      (SaleLine l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                  '${l.name}${l.size.isEmpty ? '' : ' · ${l.size}'} × ${l.qty}',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.ink)),
                            ),
                            Text(money(l.lineTotal),
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.ink)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                style: AppTheme.primaryButton,
                onPressed: () =>
                    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
                child: const Text('Back to register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
