import 'package:flutter/material.dart';
import '../../models/device.dart';

class DeviceManagementSection extends StatelessWidget {
  final Function(Device) onDeviceOptionsTap;
  
  const DeviceManagementSection({
    super.key, 
    required this.onDeviceOptionsTap,
  });

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.windows:
      case DeviceType.linux:
      case DeviceType.macos:
        return Icons.computer;
      case DeviceType.ios:
      case DeviceType.android:
        return Icons.smartphone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<List<Device>>(
            stream: Device.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              
              final devices = snapshot.data ?? [];
              if (devices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No devices found')),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Stack(
                    children: [
                      ListTile(
                        title: Text(device.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.curr ? 'Current Device' : device.formattedType),
                            Text(
                              device.lastSyncStatus,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        leading: Icon(_getDeviceIcon(device.type)),
                        trailing: SizedBox(width: 24), // Reserve space for the icon
                        onTap: () => onDeviceOptionsTap(device),
                      ),
                      if (device.curr)
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
