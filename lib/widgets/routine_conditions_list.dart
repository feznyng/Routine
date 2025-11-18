import 'dart:collection';

import 'package:Routine/util.dart';
import 'package:Routine/widgets/routine_page/condition_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/routine.dart';
import '../models/condition.dart';
import '../pages/qr_scanner_page.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

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
    if ((!routine.canCompleteConditions && !routine.isActive) || routine.conditions.isEmpty) {
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
        onTap: () async => await _handleConditionTap(context, condition),
        child: Row(
          children: [
            Icon(ConditionTypeUtils.getIcon(condition.type), size: 16),
            const SizedBox(width: 8),
            Checkbox(
              value: isMet,
              onChanged: (_) async => await _handleConditionTap(context, condition),
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

  Future<void> _handleConditionTap(BuildContext context, Condition condition) async {
    final isMet = routine.isConditionMet(condition);
    if (isMet) {
      _showUncompleteConfirmationDialog(context, condition);
      return;
    }
    switch (condition.type) {
      case ConditionType.todo:
        // Todo conditions can be completed directly
        await routine.completeCondition(condition);
        if (onRoutineUpdated != null) {
          onRoutineUpdated!();
        }
        break;
        
      case ConditionType.location:
        await _handleLocationCondition(context, condition);
        break;
        
      case ConditionType.qr:
        await _handleQrCondition(context, condition);
        break;
        
      case ConditionType.nfc:
        await _handleNfcCondition(context, condition);
        break;
        
      default:
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

  Future<void> _handleQrCondition(BuildContext context, Condition condition) async {
    bool isMobileDevice = !Util.isDesktop();
    
    if (isMobileDevice) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => QrScannerPage(
            onCodeScanned: (scannedData) async {
              if (scannedData == condition.data) {
                await routine.completeCondition(condition);
                if (onRoutineUpdated != null) {
                  onRoutineUpdated!();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR code verified! Condition completed.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid QR code. Please try again with the correct code.')),
                );
              }
            },
          ),
        ),
      );
    } else {
      await showDialog(
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

  Future<void> _handleNfcCondition(BuildContext context, Condition condition) async {
    bool isMobileDevice = !Util.isDesktop();
    
    if (!isMobileDevice) {
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
      NfcAvailability isAvailable = await NfcManager.instance.checkAvailability();
      if (isAvailable != NfcAvailability.enabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC is not available on this device')),
          );
        }
        return;
      }
      await NfcManager.instance.startSession(pollingOptions: HashSet.of(NfcPollingOption.values), onDiscovered: (NfcTag tag) async {
        try {
          String? tagData;
          
          final Ndef? ndef = Ndef.from(tag);
          if (ndef != null) {
            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage != null) {
              for (final record in cachedMessage.records) {
                if (record.typeNameFormat == TypeNameFormat.wellKnown && 
                    record.type.length == 1 && 
                    record.type[0] == 0x54) { // 'T' for text record
                  final payload = record.payload;
                  if (payload.length > 1) {
                    final languageCodeLength = payload[0] & 0x3F;
                    final textBytes = payload.sublist(1 + languageCodeLength);
                    tagData = String.fromCharCodes(textBytes);
                    break;
                  }
                }
              }
            }
          }
          if (tagData != null) {
            if (tagData == condition.data) {
              await routine.completeCondition(condition);
              if (onRoutineUpdated != null) {
                onRoutineUpdated!();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NFC tag verified! Condition completed.')),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid NFC tag. Please try scanning again.')),
                );
              }
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data found on this NFC tag. Please try scanning again.')),
              );
            }
          }
        } catch (e, st) {
          if (context.mounted) {
            Util.report("conditions nfc", e, st);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error reading NFC tag')),
            );
          }
        }
      });
    } catch (e, st) {
      if (context.mounted) {
        Util.report("conditions nfc", e, st);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing NFC')),
        );
      }
    } finally {
      NfcManager.instance.stopSession();
    }
  }

  Future<void> _handleLocationCondition(BuildContext context, Condition condition) async {
    if (condition.latitude == null || condition.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not set for this condition')),
      );
      return;
    }
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Cannot check location condition.')),
          );
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        condition.latitude!,
        condition.longitude!,
      );
      
      final proximity = condition.proximity ?? 100; // Default to 100 meters if not set
      
      if (distance <= proximity) {
        await routine.completeCondition(condition);
        if (onRoutineUpdated != null) {
          onRoutineUpdated!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location condition completed!')),
        );
      } else {
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
            onPressed: () async {
              await routine.completeCondition(condition, complete: false);
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
