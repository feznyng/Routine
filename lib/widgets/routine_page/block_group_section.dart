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

  String _buildGroupSummary(Group? group) {
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
      final newGroup = Group(name: 'Custom');
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
          return Card(
            child: ListTile(
              title: Text('${devices[deviceId]?.name}${deviceId == currentDeviceId ? ' (This Device)' : ''}'),
              subtitle: Text(_buildGroupSummary(group)),
              trailing: enabled ? const Icon(Icons.chevron_right) : null,
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
              icon: const Icon(Icons.add),
              label: const Text('Add Device Group'),
            ),
          ),
      ],
    );
  }
}
