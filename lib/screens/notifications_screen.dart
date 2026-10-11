import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/store.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    final Pal pal = Pal.of(context);
    
    // Core content only, no Scaffold here
    return ListView.builder(
      itemCount: store.notifications.length,
      itemBuilder: (context, index) {
        final n = store.notifications[index];
        return ListTile(
          title: Text(n.title),
          subtitle: Text(n.message),
          leading: Icon(n.isRead ? Icons.notifications_none : Icons.notifications_active),
        );
      },
    );
  }
}
