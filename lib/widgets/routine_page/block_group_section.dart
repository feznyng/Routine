import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../models/group.dart';
import '../../models/routine.dart';
import '../../database/database.dart';
import '../../setup.dart';
import '../block_group_page.dart';

class BlockGroupSection extends StatelessWidget {
  final Routine routine;
  final Map<String, DeviceEntry> devices;
  final Function() onChanged;
  final bool enabled;

  const BlockGroupSection({
    super.key,
    required this.routine,
    required this.devices,
    required this.onChanged,
    this.enabled = true,
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

  String _buildGroupSummary(Group? group, bool currDevice) {
    if (!currDevice) {
      return group?.name ?? 'Custom';
    }

    if (group == null) {
      return 'No block group configured';
    } else if (group.name != null) {
      return group.name!;
    } else if (group.apps.isEmpty && group.sites.isEmpty && group.categories.isEmpty) {
      return group.allow ? 'Everything blocked' : 'Nothing blocked';
    } else if (group.apps.isNotEmpty || group.sites.isNotEmpty || group.categories.isNotEmpty) {
      List<String> parts = [];
      if (group.apps.isNotEmpty) {
        parts.add('${group.apps.length} app${group.apps.length > 1 ? "s" : ""}');
      }
      if (group.sites.isNotEmpty) {
        parts.add('${group.sites.length} site${group.sites.length > 1 ? "s" : ""}');
      }
      if (group.categories.isNotEmpty) {
        parts.add('${group.categories.length} categor${group.categories.length > 1 ? "ies" : "y"}');
      }
      return group.allow 
          ? 'Custom (Allowing ${parts.join(", ")})'
          : 'Custom (Blocking ${parts.join(", ")})';
    } else {
      return group.name ?? 'Custom';
    }
  }

  void _toggleBlockGroup(BuildContext context, String deviceId) {
    final group = routine.getGroup(deviceId);
    
    // If creating a new group, set a default name for this device
    if (group == null) {
      final newGroup = Group();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => BlockGroupPage(
            selectedGroup: newGroup,
            deviceId: deviceId,
            onSave: (group) {
              routine.setGroup(group, deviceId);
              onChanged();
            },
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => BlockGroupPage(
            selectedGroup: group,
            deviceId: deviceId,
            onSave: (group) {
              routine.setGroup(group, deviceId);
              onChanged();
            },
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDeviceId = getIt<Device>().id;
    final hasCurrentDeviceGroup = routine.getGroup() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...routine.groups.entries.map((entry) {
          final deviceId = entry.key;
          final group = entry.value;
          final currDevice = deviceId == currentDeviceId;
          return Card(
            child: ListTile(
              leading: Icon(
                _getDeviceIcon(devices[deviceId]?.type != null ? DeviceType.values.byName(devices[deviceId]!.type) : DeviceType.macos),
                color: enabled
                    ? Theme.of(context).iconTheme.color
                    : Theme.of(context).iconTheme.color?.withValues(alpha: 128),
              ),
              title: Text(
                '${devices[deviceId]?.name}${currDevice ? ' (Current Device)' : ''}',
                style: TextStyle(
                  color: enabled
                      ? Theme.of(context).textTheme.titleMedium?.color
                      : Theme.of(context).textTheme.titleMedium?.color?.withValues(alpha: 128),
                ),
              ),
              subtitle: Text(
                _buildGroupSummary(group, currDevice),
                style: TextStyle(
                  color: enabled
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 128),
                ),
              ),
              trailing: currDevice
                  ? Icon(Icons.chevron_right,
                      color: enabled ? null : Theme.of(context).iconTheme.color?.withValues(alpha: 128))
                  : null,
              onTap: enabled ? () {
                if (deviceId == currentDeviceId) {
                  _toggleBlockGroup(context, deviceId);
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Modify ${devices[deviceId]?.name ?? 'Device'} Group'),
                        content: Text('Please use Routine on ${devices[deviceId]?.name ?? 'the device'} to configure this block group.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              } : null,
            ),
          );
        }),
        if (!hasCurrentDeviceGroup)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              onPressed: enabled ? () => _toggleBlockGroup(context, currentDeviceId) : null,
              icon: Icon(Icons.add, color: enabled ? null : Theme.of(context).iconTheme.color?.withValues(alpha: 128)),
              label: Text('Add Device Group', style: TextStyle(color: enabled ? null : Theme.of(context).textTheme.labelLarge?.color?.withValues(alpha: 128))),
            ),
          ),
      ],
    );
  }
}
