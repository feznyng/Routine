import 'package:flutter/material.dart';
import '../../models/routine.dart';

class TimeSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;
  final bool enabled;

  const TimeSection({
    super.key,
    required this.routine,
    required this.onChanged,
    this.enabled = true,
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
            onChanged: enabled ? (value) {
              routine.allDay = value;
              onChanged();
            } : null,
          ),
          if (!routine.allDay) ...[
            ListTile(
              title: Row(
                children: [
                  const Text('Start Time'),
                  if (routine.endTime < routine.startTime) ...[  
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'This routine spans into the next day',
                      child: const Icon(Icons.nightlight, size: 16, color: Colors.indigo),
                    ),
                  ],
                ],
              ),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(startTime.format(context)),
                onPressed: enabled ? () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    final newStartTime = time.hour * 60 + time.minute;
                    final currentEndTime = routine.endTime;
                    if (newStartTime >= currentEndTime) {
                      routine.startTime = newStartTime;
                      onChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routine will span from today into tomorrow'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (currentEndTime - newStartTime < 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routines must be at least 15 minutes long'),
                        ),
                      );
                    } else {
                      routine.startTime = newStartTime;
                      onChanged();
                    }
                  }
                } : null,
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  const Text('End Time'),
                  if (routine.endTime < routine.startTime) ...[  
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'This routine spans into the next day',
                      child: const Icon(Icons.nightlight, size: 16, color: Colors.indigo),
                    ),
                  ],
                ],
              ),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(endTime.format(context)),
                onPressed: enabled ? () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    final newEndTime = time.hour * 60 + time.minute;
                    final currentStartTime = routine.startTime;
                    if (newEndTime <= currentStartTime) {
                      routine.endTime = newEndTime;
                      onChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routine will span from today into tomorrow'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (newEndTime - currentStartTime < 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routines must be at least 15 minutes long'),
                        ),
                      );
                    } else {
                      routine.endTime = newEndTime;
                      onChanged();
                    }
                  }
                } : null,
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
                        onSelected: enabled ? (bool selected) {
                          routine.updateDay(i, selected);
                          onChanged();
                        } : null,
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
