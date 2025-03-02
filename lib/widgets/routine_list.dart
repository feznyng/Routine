import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../routine.dart';
import '../condition.dart';
import 'routine_page.dart';
import 'break_dialog.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  late List<Routine> _routines;
  late StreamSubscription<List<Routine>> _routineSubscription;

  @override
  void initState() {
    super.initState();
    _routines = [];
   
    _routineSubscription = Routine.watchAll().listen((routines) {
      if (mounted) {
        setState(() {
          _routines = routines;
        });
      }
    });
  }

  @override
  void dispose() {
    _routineSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(routine.name),
              subtitle: _buildRoutineSubtitle(context, routine),
              isThreeLine: true,
              trailing: routine.isActive ? _buildBreakButton(context, routine) : null,
              onTap: () {
                _showRoutinePage(context, routine);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutinePage(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoutineSubtitle(BuildContext context, Routine routine) {
    String timeText;
    
    // Add time information
    if (routine.startTime == -1 && routine.endTime == -1) {
      timeText = 'All day';
    } else {
      final startTimeOfDay = TimeOfDay(hour: routine.startHour, minute: routine.startMinute);
      final endTimeOfDay = TimeOfDay(hour: routine.endHour, minute: routine.endMinute);
      timeText = '${startTimeOfDay.format(context)} - ${endTimeOfDay.format(context)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(timeText),
        const SizedBox(height: 4),
        _buildBlockedChips(routine),
        if (routine.isActive && routine.conditions.isNotEmpty) ...[  
          const SizedBox(height: 8),
          _buildConditionsList(context, routine),
        ],
      ],
    );
  }

  Widget _buildBlockedChips(Routine routine) {
    final group = routine.getGroup();
    if (group == null) return const SizedBox.shrink();

    final apps = group.apps;
    final sites = group.sites;
    final categories = group.categories;
    final isAllowlist = group.allow;
    
    List<Widget> chips = [
      Chip(
        label: Text(
          isAllowlist ? 'Allow' : 'Block',
          style: const TextStyle(fontSize: 12),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    ];
    
    // Only add app chip if there are apps or if it's an allowlist with no apps
    if (apps.isNotEmpty || (isAllowlist && apps.isEmpty)) {
      chips.add(
        Chip(
          label: Text(
            apps.isEmpty && isAllowlist
                ? 'No apps'
                : '${apps.length} ${apps.length == 1 ? 'app' : 'apps'}',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
    }
    
    // Only add site chip if there are sites or if it's an allowlist with no sites
    if (sites.isNotEmpty || (isAllowlist && sites.isEmpty)) {
      chips.add(
        Chip(
          label: Text(
            sites.isEmpty && isAllowlist
                ? 'No sites'
                : '${sites.length} ${sites.length == 1 ? 'site' : 'sites'}',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
    }
    
    // Only add category chip if there are categories
    if (categories.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            '${categories.length} ${categories.length == 1 ? 'category' : 'categories'}',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildBreakButton(BuildContext context, Routine routine) {
    if (routine.isPaused) {
      return TextButton.icon(
        onPressed: () => _showEndBreakDialog(context, routine),
        icon: const Icon(Icons.timer),
        label: const Text('End Break'),
      );
    }

    final canBreak = routine.canBreak;
    return TextButton.icon(
      onPressed: canBreak ? () => _showBreakDialog(context, routine) : null,
      icon: const Icon(Icons.coffee),
      label: const Text('Break'),
    );
  }

  void _showEndBreakDialog(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Break'),
        content: const Text('Are you sure you want to end your break?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              routine.endBreak();
              Navigator.of(context).pop();
            },
            child: const Text('End Break'),
          ),
        ],
      ),
    );
  }

  void _showBreakDialog(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => BreakDialog(routine: routine),
      barrierDismissible: false,
    );
  }

  void _showRoutinePage(BuildContext context, Routine? routine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RoutinePage(
          routine: routine ?? Routine(),
          onSave: (updatedRoutine) {
            Navigator.of(context).pop();
          },
          onDelete: routine != null ? () {
            Navigator.of(context).pop();
          } : null,
        ),
      ),
    );
  }
  
  Widget _buildConditionsList(BuildContext context, Routine routine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ...routine.conditions.map((condition) => _buildConditionItem(context, routine, condition)),
      ],
    );
  }
  
  Widget _buildConditionItem(BuildContext context, Routine routine, Condition condition) {
    final isMet = routine.isConditionMet(condition);
    
    // Get the appropriate icon based on condition type
    IconData getConditionIcon() {
      switch (condition.type) {
        case ConditionType.location:
          return Icons.location_on;
        case ConditionType.nfc:
          return Icons.nfc;
        case ConditionType.qr:
          return Icons.qr_code;
        case ConditionType.health:
          return Icons.favorite;
        case ConditionType.todo:
          return Icons.assignment_turned_in;
      }
    }
    
    // Get the condition description
    String getConditionDescription() {
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
          return condition.todoText ?? 'To-do item';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _handleConditionTap(routine, condition),
        child: Row(
          children: [
            Checkbox(
              value: isMet,
              onChanged: (_) => _handleConditionTap(routine, condition),
            ),
            Icon(getConditionIcon(), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                getConditionDescription(),
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
  
  void _handleConditionTap(Routine routine, Condition condition) {
    final isMet = routine.isConditionMet(condition);
    
    // If the condition is already completed, show a confirmation dialog
    if (isMet) {
      _showUncompleteConfirmationDialog(routine, condition);
      return;
    }
    
    // Handle different condition types
    switch (condition.type) {
      case ConditionType.todo:
        // Todo conditions can be completed directly
        routine.completeCondition(condition);
        break;
        
      case ConditionType.location:
        // Check current location against condition location
        _handleLocationCondition(routine, condition);
        break;
        
      default:
        // Show a placeholder dialog for other condition types
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Complete ${condition.type.toString().split('.').last} Condition'),
            content: Text('This condition type is not yet implemented.'),
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
  
  void _handleLocationCondition(Routine routine, Condition condition) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location condition completed!')),
        );
      } else {
        // User is not within the proximity radius
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are ${distance.toInt()} meters away from the target location. Need to be within ${proximity.toInt()} meters.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking location: $e')),
      );
    }
  }
  
  void _showUncompleteConfirmationDialog(Routine routine, Condition condition) {
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
              Navigator.of(context).pop();
            },
            child: const Text('Uncomplete'),
          ),
        ],
      ),
    );
  }
}
