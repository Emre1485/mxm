import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class JoinCodeBox extends StatelessWidget {
  final String? joinCode;

  const JoinCodeBox({super.key, required this.joinCode});

  void _copyJoinCode(BuildContext context) {
    if (joinCode != null) {
      Clipboard.setData(ClipboardData(text: joinCode!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Join kodu kopyalandı!')));
    }
  }

  void _shareJoinCode() {
    if (joinCode != null) {
      Share.share('Join kodu: $joinCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (joinCode == null) {
      return const Center(
        child: Text(
          'Join Kodu yok',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _copyJoinCode(context),
      onLongPress: _shareJoinCode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Center(
          child: Text(
            'Join Kodu: $joinCode',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
