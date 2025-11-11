import 'package:flutter/material.dart';
import '../../../models/condition.dart';
import '../../../util.dart';

class LocationConditionWidget extends StatelessWidget {
  final Condition condition;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController proximityController;
  final Function(String) onStatusMessage;

  const LocationConditionWidget({
    super.key,
    required this.condition,
    required this.latitudeController,
    required this.longitudeController,
    required this.proximityController,
    required this.onStatusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
                onPressed: () async {
                  try {
                    onStatusMessage('Getting your current location...');
                    
                    final position = await Util.determinePosition();
                    
                    latitudeController.text = position.latitude.toString();
                    longitudeController.text = position.longitude.toString();
                    condition.latitude = position.latitude;
                    condition.longitude = position.longitude;
                    
                    onStatusMessage('Location updated successfully!');
                  } catch (e) {
                    onStatusMessage('Error getting location: $e');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: latitudeController,
          decoration: const InputDecoration(
            labelText: 'Latitude',
            hintText: 'Enter latitude',
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (value) {
            if (value.isNotEmpty) {
              try {
                condition.latitude = double.parse(value);
              } catch (e) {
              }
            } else {
              condition.latitude = null;
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: longitudeController,
          decoration: const InputDecoration(
            labelText: 'Longitude',
            hintText: 'Enter longitude',
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (value) {
            if (value.isNotEmpty) {
              try {
                condition.longitude = double.parse(value);
              } catch (e) {
              }
            } else {
              condition.longitude = null;
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: proximityController,
          decoration: const InputDecoration(
            labelText: 'Proximity (meters)',
            hintText: 'Enter proximity radius in meters',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            if (value.isNotEmpty) {
              try {
                condition.proximity = double.parse(value);
              } catch (e) {
              }
            } else {
              condition.proximity = 100; // Default to 100 meters
            }
          },
        ),
      ],
    );
  }
}
