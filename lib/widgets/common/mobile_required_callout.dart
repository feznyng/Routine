import 'package:flutter/material.dart';



class MobileRequiredCallout extends StatelessWidget {

  final String feature;
  

  final String? additionalInfo;

  const MobileRequiredCallout({
    super.key,
    required this.feature,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              additionalInfo != null 
                  ? '$feature requires a mobile device. $additionalInfo'
                  : '$feature requires a mobile device.',
            ),
          ),
        ],
      ),
    );
  }
}
