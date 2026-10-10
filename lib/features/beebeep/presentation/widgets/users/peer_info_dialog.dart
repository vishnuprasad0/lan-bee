import 'package:flutter/material.dart';

import '../../../domain/services/relative_time.dart';
import '../../bloc/peers/peer_presence.dart';

Future<void> showPeerInfoDialog(BuildContext context, PeerPresence presence) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final peer = presence.peer;
      return AlertDialog(
        title: Text(peer.displayName.isEmpty ? 'Unknown' : peer.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(presence.isOnline ? 'Status: Online' : 'Status: Offline'),
            const SizedBox(height: 8),
            Text('IP: ${peer.host}'),
            Text('Port: ${peer.port}'),
            if (!presence.isOnline && presence.lastSeen != null) ...[
              const SizedBox(height: 8),
              Text(lastSeenLabel(presence.lastSeen, now: DateTime.now())),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
