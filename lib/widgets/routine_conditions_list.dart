import 'dart:io';
import 'package:Routine/widgets/routine_page/condition_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/routine.dart';
import '../models/condition.dart';
import '../pages/qr_scanner_page.dart';

class RoutineConditionsList extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onRoutineUpdated;

  const RoutineConditionsList({
    super.key,
    required this.routine,
    this.onRoutineUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (!routine.isActive || routine.conditions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ...routine.conditions.map((condition) => _buildConditionItem(context, condition)),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionItem(BuildContext context, Condition condition) {
    final isMet = routine.isConditionMet(condition);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _handleConditionTap(context, condition),
        child: Row(
          children: [
            Icon(ConditionTypeUtils.getIcon(condition.type), size: 16),
            const SizedBox(width: 8),
            Checkbox(
              value: isMet,
              onChanged: (_) => _handleConditionTap(context, condition),
            ),
            Expanded(
              child: Text(
                _getConditionDescription(condition),
                style: TextStyle(
                  decoration: isMet ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getConditionDescription(Condition condition) {
    if (condition.name != null && condition.name!.isNotEmpty) {
      return condition.name! + (condition.proximity != null ? ' (${condition.proximity!.toInt()} m)' : '');
    }
    
    switch (condition.type) {
      case ConditionType.location:
        if (condition.latitude != null && condition.longitude != null) {
          return 'Location';
        }
        return 'Location: Not set';
      case ConditionType.nfc:
        return 'NFC Tag';
      case ConditionType.qr:
        return 'QR Code';
      case ConditionType.health:
        return 'Health: ${condition.activityType ?? 'Not set'}';
      case ConditionType.todo:
        return condition.name ?? 'To-do item';
    }
  }

  void _handleConditionTap(BuildContext context, Condition condition) {
    final isMet = routine.isConditionMet(condition);
    
    // If the condition is already completed, show a confirmation dialog
    if (isMet) {
      _showUncompleteConfirmationDialog(context, condition);
      return;
    }
    
    // Handle different condition types
    switch (condition.type) {
      case ConditionType.todo:
        // Todo conditions can be completed directly
        routine.completeCondition(condition);
        if (onRoutineUpdated != null) {
          onRoutineUpdated!();
        }
        break;
        
      case ConditionType.location:
        // Check current location against condition location
        _handleLocationCondition(context, condition);
        break;
        
      case ConditionType.qr:
        // Open QR code scanner for QR conditions
        _handleQrCondition(context, condition);
        break;
        
      case ConditionType.nfc:
        // Handle NFC condition
        _handleNfcCondition(context, condition);
        break;
        
      default:
        // Show a placeholder dialog for other condition types
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Complete ${condition.type.toString().split('.').last} Condition'),
            content: const Text('This condition type is not yet implemented.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }

  void _handleQrCondition(BuildContext context, Condition condition) {
    // Check if running on a mobile device
    bool isMobileDevice = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    
    if (isMobileDevice) {
      // Navigate to the QR scanner page on mobile devices
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => QrScannerPage(
            onCodeScanned: (scannedData) {
              // Compare scanned data with condition data
              if (scannedData == condition.data) {
                // QR code matches, complete the condition
                routine.completeCondition(condition);
                if (onRoutineUpdated != null) {
                  onRoutineUpdated!();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR code verified! Condition completed.')),
                );
              } else {
                // QR code doesn't match
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid QR code. Please try again with the correct code.')),
                );
              }
            },
          ),
        ),
      );
    } else {
      // Show a dialog on desktop platforms
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mobile Device Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_android,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'QR code scanning is only available on mobile devices.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handleNfcCondition(BuildContext context, Condition condition) async {
    // Check if running on a mobile device
    bool isMobileDevice = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    
    if (!isMobileDevice) {
      // Show a dialog on desktop platforms
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mobile Device Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_android,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'NFC scanning is only supported on mobile devices. Please use a mobile device.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Check if NFC is available
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC is not available on this device')),
          );
        }
        return;
      }

      // Start NFC session
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          // Read NDEF message from the tag
          String? tagData;
          if (tag.data.containsKey('ndef')) {
            final ndef = Ndef.from(tag);
            if (ndef != null) {
              // Try to read the NDEF message
              final cachedMessage = ndef.cachedMessage;
              if (cachedMessage != null) {
                // Look for text records
                for (final record in cachedMessage.records) {
                  if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown && 
                      record.type.length == 1 && 
                      record.type[0] == 0x54) { // 'T' for text record
                    final payload = record.payload;
                    if (payload.length > 1) {
                      final languageCodeLength = payload[0] & 0x3F;
                      // Skip language code and get the text
                      final textBytes = payload.sublist(1 + languageCodeLength);
                      tagData = String.fromCharCodes(textBytes);
                      break;
                    }
                  }
                }
              }
            }
          }

          // Check if we got data from the tag
          if (tagData != null) {
            // Compare tag data with condition data
            if (tagData == condition.data) {
              // NFC tag matches, complete the condition
              routine.completeCondition(condition);
              if (onRoutineUpdated != null) {
                onRoutineUpdated!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NFC tag verified! Condition completed.')),
                );
              }
            } else {
              // NFC tag doesn't match
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid NFC tag. Please try scanning again.')),
                );
              }
            }
          } else {
            // No NDEF data found on the tag
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data found on this NFC tag. Please try scanning again.')),
              );
            }
          }
        } catch (e) {
          // Close the scanning dialog if open
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error reading NFC tag: $e')),
            );
          }
        } finally {
          // Stop the NFC session
          NfcManager.instance.stopSession();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing NFC: $e')),
        );
      }
    }
  }

  void _handleLocationCondition(BuildContext context, Condition condition) async {
    if (condition.latitude == null || condition.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not set for this condition')),
      );
      return;
    }
    
    try {
      // First, check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        // If still denied after request, show error
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Cannot check location condition.')),
          );
          return;
        }
        
        // Add a small delay after permission is granted to allow the system to update
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
        );
        return;
      }
      
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        condition.latitude!,
        condition.longitude!,
      );
      
      final proximity = condition.proximity ?? 100; // Default to 100 meters if not set
      
      if (distance <= proximity) {
        // User is within the proximity radius
        routine.completeCondition(condition);
        if (onRoutineUpdated != null) {
          onRoutineUpdated!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location condition completed!')),
        );
      } else {
        // User is not within the proximity radius
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${distance.toInt()} meters away from the target location. Please move within ${proximity.toInt()} meter${proximity == 1.0 ? '' : 's'}.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking location: $e')),
      );
    }
  }

  void _showUncompleteConfirmationDialog(BuildContext context, Condition condition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uncomplete Condition'),
        content: const Text('Are you sure you want to mark this condition as not completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              routine.completeCondition(condition, complete: false);
              if (onRoutineUpdated != null) {
                onRoutineUpdated!();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Uncomplete'),
          ),
        ],
      ),
    );
  }
}
