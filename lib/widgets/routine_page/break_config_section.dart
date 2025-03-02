import 'package:Routine/database.dart';
import 'package:flutter/material.dart';
import '../../routine.dart';

class BreakConfigSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;

  const BreakConfigSection({
    super.key,
    required this.routine,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 300),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Breaks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Breaks'),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Unlimited'),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Limited'),
                        ),
                      ],
                      selected: {routine.maxBreaks != null},
                      onSelectionChanged: (Set<bool> selection) {
                        routine.maxBreaks = selection.first ? 3 : null;
                        onChanged();
                      },
                    ),
                    if (routine.maxBreaks != null) ...[                
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'minus',
                            icon: const Icon(Icons.remove),
                            enabled: routine.maxBreaks! > 1,
                          ),
                          ButtonSegment(
                            value: 'text',
                            label: Text('${routine.maxBreaks} breaks'),
                          ),
                          ButtonSegment(
                            value: 'plus',
                            icon: const Icon(Icons.add),
                            enabled: routine.maxBreaks! < 10,
                          ),
                        ],
                        emptySelectionAllowed: true,
                        selected: const {},
                        onSelectionChanged: (Set<String> selected) {
                          if (selected.first == 'minus' && routine.maxBreaks! > 1) {
                            routine.maxBreaks = routine.maxBreaks! - 1;
                          } else if (selected.first == 'plus' && routine.maxBreaks! < 10) {
                            routine.maxBreaks = routine.maxBreaks! + 1;
                          }
                          onChanged();
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Break Duration'),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'minus',
                          icon: const Icon(Icons.remove),
                          enabled: routine.maxBreakDuration > 5,
                        ),
                        ButtonSegment(
                          value: 'text',
                          label: Text('${routine.maxBreakDuration} min'),
                        ),
                        ButtonSegment(
                          value: 'plus',
                          icon: const Icon(Icons.add),
                          enabled: routine.maxBreakDuration < 60,
                        ),
                      ],
                      emptySelectionAllowed: true,
                      selected: const {},
                      onSelectionChanged: (Set<String> selected) {
                        if (selected.first == 'minus' && routine.maxBreakDuration > 5) {
                          routine.maxBreakDuration = routine.maxBreakDuration - 5;
                        } else if (selected.first == 'plus' && routine.maxBreakDuration < 60) {
                          routine.maxBreakDuration = routine.maxBreakDuration + 5;
                        }
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Friction'),
                    const SizedBox(height: 8),
                    SegmentedButton<FrictionType>(
                      segments: const [
                        ButtonSegment(
                          value: FrictionType.none,
                          label: Text('None'),
                        ),
                        ButtonSegment(
                          value: FrictionType.delay,
                          label: Text('Delay'),
                        ),
                        ButtonSegment(
                          value: FrictionType.intention,
                          label: Text('Intention'),
                        ),
                        ButtonSegment(
                          value: FrictionType.code,
                          label: Text('Code'),
                        ),
                      ],
                      selected: {routine.friction},
                      onSelectionChanged: (Set<FrictionType> selection) {
                        routine.friction = selection.first;
                        if (routine.friction == FrictionType.none || 
                            routine.friction == FrictionType.intention) {
                          routine.frictionLen = null;
                        }
                        onChanged();
                      },
                    ),
                    if (routine.friction == FrictionType.delay || routine.friction == FrictionType.code) ...[                
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(routine.friction == FrictionType.delay ? 'Delay Length' : 'Code Length'),
                          const SizedBox(width: 8)
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Automatic'),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Fixed'),
                          ),
                        ],
                        selected: {routine.frictionLen != null},
                        onSelectionChanged: (Set<bool> selection) {
                          routine.frictionLen = selection.first 
                            ? (routine.friction == FrictionType.delay ? 30 : 6)
                            : null;
                          onChanged();
                        },
                      ),
                      if (routine.frictionLen != null) ...[                
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'minus',
                              icon: const Icon(Icons.remove),
                              enabled: routine.frictionLen! > (routine.friction == FrictionType.delay ? 5 : 4),
                            ),
                            ButtonSegment(
                              value: 'text',
                              label: Text(routine.friction == FrictionType.delay 
                                ? '${routine.frictionLen} sec'
                                : '${routine.frictionLen} chars'),
                            ),
                            ButtonSegment(
                              value: 'plus',
                              icon: const Icon(Icons.add),
                              enabled: routine.frictionLen! < (routine.friction == FrictionType.delay ? 60 : 12),
                            ),
                          ],
                          emptySelectionAllowed: true,
                          selected: const {},
                          onSelectionChanged: (Set<String> selected) {
                            if (selected.first == 'minus' && 
                                routine.frictionLen! > (routine.friction == FrictionType.delay ? 5 : 4)) {
                              routine.frictionLen = routine.frictionLen! - (routine.friction == FrictionType.delay ? 5 : 1);
                            } else if (selected.first == 'plus' && 
                                routine.frictionLen! < (routine.friction == FrictionType.delay ? 60 : 12)) {
                              routine.frictionLen = routine.frictionLen! + (routine.friction == FrictionType.delay ? 5 : 1);
                            }
                            onChanged();
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
