import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../models/group.dart';
import '../../models/routine.dart';
import '../../database/database.dart';
import '../../setup.dart';
import '../block_group_page.dart';

class BlockGroupSection extends StatefulWidget {
  final Routine routine;
  final Map<String, DeviceEntry> devices;
  final bool inLockdown;
  final Function() onChanged;

  const BlockGroupSection({
    super.key,
    required this.routine,
    required this.devices,
    required this.onChanged,
    required this.inLockdown
  });

  @override
  State<BlockGroupSection> createState() => _BlockGroupSectionState();
}

class _BlockGroupSectionState extends State<BlockGroupSection> {
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

  void _toggleBlockGroup(BuildContext context, String deviceId) async {
    final group = widget.routine.getGroup(deviceId);
    final currentDevice = getIt<Device>();
    
    // Check iOS block group limit only when adding a new group on iOS
    if (group == null && currentDevice.type == DeviceType.ios) {
      final allRoutines = await Routine.getAll();
      final iosBlockGroups = allRoutines.where((r) => r.getGroup(currentDevice.id) != null).length;
      
      if (iosBlockGroups >= 10) {
        if (!mounted) return;
        
        final dialogContext = context;
        if (!dialogContext.mounted) return;
        
        await showDialog(
          context: dialogContext,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Maximum Routines Reached'),
              content: const Text('iOS devices are limited to a maximum of 10 routines with block groups. Please remove a block group from another routine before adding a new one.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    }
    
    if (!mounted) return;
    
    final navContext = context;
    if (!navContext.mounted) return;
    
    Navigator.of(navContext).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockGroupPage(
          selectedGroup: group ?? Group(),
          deviceId: deviceId,
          inLockdown: widget.inLockdown,
          onSave: (group) {
            widget.routine.setGroup(group, deviceId);
            widget.onChanged();
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDeviceId = getIt<Device>().id;
    final hasCurrentDeviceGroup = widget.routine.getGroup() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.routine.groups.entries.map((entry) {
          final deviceId = entry.key;
          final group = entry.value;
          final currDevice = deviceId == currentDeviceId;
          return Card(
            child: ListTile(
              leading: Icon(
                _getDeviceIcon(widget.devices[deviceId]?.type != null ? DeviceType.values.byName(widget.devices[deviceId]!.type) : DeviceType.macos),
                color: Theme.of(context).iconTheme.color
              ),
              title: Text(
                '${widget.devices[deviceId]?.name}${currDevice ? ' (Current Device)' : ''}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color
                ),
              ),
              subtitle: Text(
                _buildGroupSummary(group, currDevice),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color
                ),
              ),
              trailing: currDevice
                  ? Icon(Icons.chevron_right)
                  : null,
              onTap: () {
                if (deviceId == currentDeviceId) {
                  _toggleBlockGroup(context, deviceId);
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Modify ${widget.devices[deviceId]?.name ?? 'Device'} Group'),
                        content: Text('Please use Routine on ${widget.devices[deviceId]?.name ?? 'the device'} to configure this block group.'),
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
              },
            ),
          );
        }),
        if (!hasCurrentDeviceGroup)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _toggleBlockGroup(context, currentDeviceId),
              icon: Icon(Icons.add),
              label: Text('Add Device Group'),
            ),
          ),
      ],
    );
  }
}
