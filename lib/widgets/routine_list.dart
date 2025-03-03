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
  bool _activeRoutinesExpanded = true;
  bool _inactiveRoutinesExpanded = true;

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
    // Split routines into active and inactive
    final activeRoutines = _routines.where((routine) => routine.isActive).toList();
    final inactiveRoutines = _routines.where((routine) => !routine.isActive).toList();
    
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
          // Active routines section
          if (activeRoutines.isNotEmpty) ...[  
            _buildSectionHeader(
              context, 
              'Active', 
              _activeRoutinesExpanded, 
              () => setState(() => _activeRoutinesExpanded = !_activeRoutinesExpanded)
            ),
            if (_activeRoutinesExpanded)
              ...activeRoutines.map((routine) => _buildRoutineCard(context, routine)),
          ],
          
          // Add padding between sections
          const SizedBox(height: 24),
          
          // Inactive routines section
          if (inactiveRoutines.isNotEmpty) ...[  
            _buildSectionHeader(
              context, 
              'Inactive', 
              _inactiveRoutinesExpanded, 
              () => setState(() => _inactiveRoutinesExpanded = !_inactiveRoutinesExpanded)
            ),
            if (_inactiveRoutinesExpanded)
              ...inactiveRoutines.map((routine) => _buildRoutineCard(context, routine)),
          ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutinePage(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isExpanded, VoidCallback onToggle) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$title',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // Helper method to create consistently styled chips
  Widget _buildStyledChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildBlockedChips(Routine routine) {
    final group = routine.getGroup();
    List<String> chipTexts = [];
    
    // Collect all chip texts first
    if (group == null) {
      // If there's no block group configured for the current device, show a 'None' chip
      chipTexts.add('None');
    } else if (group.name != null) {
      // If the group has a name, just show that
      chipTexts.add(group.name!);
    } else {
      // Otherwise show details about what's being blocked/allowed
      final apps = group.apps;
      final sites = group.sites;
      final categories = group.categories;
      final isAllowlist = group.allow;
      
      // Add block/allow chip
      chipTexts.add(isAllowlist ? 'Allow' : 'Block');
      
      // Add app chip if there are apps or if it's an allowlist with no apps
      if (apps.isNotEmpty || (isAllowlist && apps.isEmpty)) {
        chipTexts.add(apps.isEmpty && isAllowlist
            ? 'No apps'
            : '${apps.length} ${apps.length == 1 ? 'app' : 'apps'}');
      }
      
      // Add site chip if there are sites or if it's an allowlist with no sites
      if (sites.isNotEmpty || (isAllowlist && sites.isEmpty)) {
        chipTexts.add(sites.isEmpty && isAllowlist
            ? 'No sites'
            : '${sites.length} ${sites.length == 1 ? 'site' : 'sites'}');
      }
      
      // Add category chip if there are categories
      if (categories.isNotEmpty) {
        chipTexts.add('${categories.length} ${categories.length == 1 ? 'category' : 'categories'}');
      }
    }
    
    // Add strict mode chip if enabled
    if (routine.strictMode) {
      chipTexts.add('Strict');
    }
    
    // Always add breaks chip
    chipTexts.add('${routine.breaksLeftText} ${routine.breaksLeftText == "Unlimited" ? "breaks" : routine.isActive ? "break${routine.numBreaksLeft == 1 ? '' : 's'} left" : "break${routine.numBreaksLeft == 1 ? '' : 's'}"}');

    // Transform all texts to styled chips
    final chips = chipTexts.map((text) {
      // Special styling for strict mode chip
      if (text == 'Strict') {
        return Chip(
          label: const Text(
            'Strict',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }
      return _buildStyledChip(text);
    }).toList();
    
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
    
    String getConditionDescription() {
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _handleConditionTap(routine, condition),
        child: Row(
          children: [
            Icon(getConditionIcon(), size: 16),
            const SizedBox(width: 8),
            Checkbox(
              value: isMet,
              onChanged: (_) => _handleConditionTap(routine, condition),
            ),
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
          SnackBar(content: Text('${distance.toInt()} meters away from the target location. Please move within ${proximity.toInt()} meter${proximity == 1.0 ? '' : 's'}.')),
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
