import 'package:flutter/material.dart';
import '../../routine.dart';

class TimeSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;

  const TimeSection({
    super.key,
    required this.routine,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = TimeOfDay(hour: routine.startHour, minute: routine.startMinute);
    final endTime = TimeOfDay(hour: routine.endHour, minute: routine.endMinute);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: const Text('All Day'),
            value: routine.allDay,
            onChanged: (value) {
              routine.allDay = value;
              onChanged();
            },
          ),
          if (!routine.allDay) ...[
            ListTile(
              title: const Text('Start Time'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(startTime.format(context)),
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    final newStartTime = time.hour * 60 + time.minute;
                    final currentEndTime = routine.endTime;
                    
                    // Check if new start time is after end time
                    if (newStartTime >= currentEndTime) {
                      // Calculate new end time (start time + 60 minutes)
                      final newEndTime = newStartTime + 60;
                      
                      // Check if new end time is valid (not exceeding 24 hours)
                      if (newEndTime <= 1440) {
                        routine.startTime = newStartTime;
                        routine.endTime = newEndTime;
                        onChanged();
                      } else {
                        // Show warning if new end time would exceed 24 hours
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot set start time: would cause end time to exceed midnight'),
                          ),
                        );
                      }
                    } else if (currentEndTime - newStartTime < 15) {
                      // Check if duration would be less than 15 minutes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routines must be at least 15 minutes long'),
                        ),
                      );
                    } else {
                      // Normal case: start time is before end time with at least 15 minutes gap
                      routine.startTime = newStartTime;
                      onChanged();
                    }
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('End Time'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(endTime.format(context)),
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    final newEndTime = time.hour * 60 + time.minute;
                    final currentStartTime = routine.startTime;
                    
                    // Check if new end time is before start time
                    if (newEndTime <= currentStartTime) {
                      // Calculate new start time (end time - 60 minutes)
                      final newStartTime = newEndTime - 60;
                      
                      // Check if new start time is valid (not negative)
                      if (newStartTime >= 0) {
                        routine.startTime = newStartTime;
                        routine.endTime = newEndTime;
                        onChanged();
                      } else {
                        // Show warning if new start time would be negative
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot set end time: would cause start time to be before midnight'),
                          ),
                        );
                      }
                    } else if (newEndTime - currentStartTime < 15) {
                      // Check if duration would be less than 15 minutes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routines must be at least 15 minutes long'),
                        ),
                      );
                    } else {
                      // Normal case: end time is after start time with at least 15 minutes gap
                      routine.endTime = newEndTime;
                      onChanged();
                    }
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repeat on',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0; i < 7; i++)
                      FilterChip(
                        label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
                        selected: routine.days[i],
                        onSelected: (bool selected) {
                          routine.updateDay(i, selected);
                          onChanged();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
