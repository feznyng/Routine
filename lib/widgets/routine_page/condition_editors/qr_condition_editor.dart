import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/condition.dart';

class QrConditionWidget extends StatelessWidget {
  final Condition condition;
  final Function() onSaveQrCode;
  final bool isLoading;

  const QrConditionWidget({
    super.key,
    required this.condition,
    required this.onSaveQrCode,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: QrImageView(
            data: condition.data,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Icon(Icons.download),
            label: Text(isLoading ? 'Processing...' : 'Download QR Code'),
            onPressed: isLoading ? null : onSaveQrCode,
          ),
        ),
      ],
    );
  }
}
