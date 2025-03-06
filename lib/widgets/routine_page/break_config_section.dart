import 'package:Routine/database/database.dart';
import 'package:flutter/material.dart';
import '../../models/routine.dart';

class BreakConfigSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;
  final bool enabled;

  const BreakConfigSection({
    super.key,
    required this.routine,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'none',
                            label: Text('None'),
                          ),
                          ButtonSegment(
                            value: 'unlimited',
                            label: Text('Unlimited'),
                          ),
                          ButtonSegment(
                            value: 'limited',
                            label: Text('Limited'),
                          ),
                        ],
                        selected: {
                          if (routine.maxBreaks == 0) 'none'
                          else if (routine.maxBreaks == null) 'unlimited'
                          else 'limited'
                        },
                        onSelectionChanged: enabled ? (Set<String> selection) {
                          final selected = selection.first;
                          if (selected == 'none') {
                            routine.maxBreaks = 0;
                          } else if (selected == 'unlimited') {
                            routine.maxBreaks = null;
                          } else { // limited
                            routine.maxBreaks = 3;
                          }
                          onChanged();
                        } : null,
                      ),
                    ),
                    if (routine.maxBreaks != null && routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'minus',
                              icon: const Icon(Icons.remove),
                              enabled: enabled && routine.maxBreaks! > 1,
                            ),
                            ButtonSegment(
                              value: 'text',
                              label: Text('${routine.maxBreaks} breaks'),
                            ),
                            ButtonSegment(
                              value: 'plus',
                              icon: const Icon(Icons.add),
                              enabled: enabled && routine.maxBreaks! < 10,
                            ),
                          ],
                          emptySelectionAllowed: true,
                          selected: const {},
                          onSelectionChanged: enabled ? (Set<String> selected) {
                            if (selected.first == 'minus' && routine.maxBreaks! > 1) {
                              routine.maxBreaks = routine.maxBreaks! - 1;
                            } else if (selected.first == 'plus' && routine.maxBreaks! < 10) {
                              routine.maxBreaks = routine.maxBreaks! + 1;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                    ],
                    if (routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      const Text('Break Duration'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'minus',
                              icon: const Icon(Icons.remove),
                              enabled: enabled && routine.maxBreakDuration > 5,
                            ),
                            ButtonSegment(
                              value: 'text',
                              label: Text('${routine.maxBreakDuration} min'),
                            ),
                            ButtonSegment(
                              value: 'plus',
                              icon: const Icon(Icons.add),
                              enabled: enabled && routine.maxBreakDuration < 60,
                            ),
                          ],
                          emptySelectionAllowed: true,
                          selected: const {},
                          onSelectionChanged: enabled ? (Set<String> selected) {
                            if (selected.first == 'minus' && routine.maxBreakDuration > 5) {
                              routine.maxBreakDuration = routine.maxBreakDuration - 5;
                            } else if (selected.first == 'plus' && routine.maxBreakDuration < 60) {
                              routine.maxBreakDuration = routine.maxBreakDuration + 5;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                    ],
                    if (routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      const Text('Friction'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<FrictionType>(
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
                          onSelectionChanged: enabled ? (Set<FrictionType> selection) {
                            routine.friction = selection.first;
                            if (routine.friction == FrictionType.none || 
                                routine.friction == FrictionType.intention) {
                              routine.frictionLen = null;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                    ],
                    if (routine.maxBreaks != 0 && (routine.friction == FrictionType.delay || routine.friction == FrictionType.code)) ...[                
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(routine.friction == FrictionType.delay ? 'Delay Length' : 'Code Length'),
                          const SizedBox(width: 8)
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<bool>(
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
                          onSelectionChanged: enabled ? (Set<bool> selection) {
                            routine.frictionLen = selection.first 
                              ? (routine.friction == FrictionType.delay ? 30 : 6)
                              : null;
                            onChanged();
                          } : null,
                        ),
                      ),
                      if (routine.frictionLen != null) ...[                
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'minus',
                                icon: const Icon(Icons.remove),
                                enabled: enabled && routine.frictionLen! > (routine.friction == FrictionType.delay ? 5 : 4),
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
                                enabled: enabled && routine.frictionLen! < (routine.friction == FrictionType.delay ? 60 : 12),
                              ),
                            ],
                            emptySelectionAllowed: true,
                            selected: const {},
                            onSelectionChanged: enabled ? (Set<String> selected) {
                              if (selected.first == 'minus' && 
                                  routine.frictionLen! > (routine.friction == FrictionType.delay ? 5 : 4)) {
                                routine.frictionLen = routine.frictionLen! - (routine.friction == FrictionType.delay ? 5 : 1);
                              } else if (selected.first == 'plus' && 
                                  routine.frictionLen! < (routine.friction == FrictionType.delay ? 60 : 12)) {
                                routine.frictionLen = routine.frictionLen! + (routine.friction == FrictionType.delay ? 5 : 1);
                              }
                              onChanged();
                            } : null,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
