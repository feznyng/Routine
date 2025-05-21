import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FeedbackSection extends StatelessWidget {
  const FeedbackSection({super.key});

  Future<void> _openFeedbackForm() async {
    final String? formUrl = dotenv.env['FEEDBACK_FORM'];
    if (formUrl == null || formUrl.isEmpty) {
      throw Exception('Feedback form URL not configured');
    }
    
    final Uri url = Uri.parse(formUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Feedback'),
        leading: const Icon(Icons.feedback_outlined),
        subtitle: const Text('Help us improve Routine by sharing your thoughts and suggestions.'),
        trailing: TextButton(
          onPressed: _openFeedbackForm,
          child: const Text('Open'),
        ),
      ),
    );
  }
}
