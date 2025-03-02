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
                    routine.startTime = time.hour * 60 + time.minute;
                    onChanged();
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
                    routine.endTime = time.hour * 60 + time.minute;
                    onChanged();
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
