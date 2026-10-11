import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/store.dart';
import '../../theme/app_theme.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    
    // Core content only.
    return ListView.builder(
      itemCount: store.products.length,
      itemBuilder: (context, index) {
        final p = store.products[index];
        return ListTile(
          title: Text(p.name),
          subtitle: Text('Stock: ${p.stock}'),
        );
      },
    );
  }
}
