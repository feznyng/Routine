import 'package:flutter/material.dart';

class TodoConditionWidget extends StatelessWidget {
  const TodoConditionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // For todo type, we only use the name field at the top of the form
    // that serves as both the name and the task description
    return const SizedBox.shrink();
  }
}
