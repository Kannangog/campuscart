// support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/utilities/app_theme.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I update my restaurant information?',
      'answer': 'Go to your profile, tap on "Update Profile", make your changes, and save them.',
    },
    {
      'question': 'How long does approval take?',
      'answer': 'Restaurant approval typically takes 24-48 hours after submission.',
    },
    {
      'question': 'How do I manage orders?',
      'answer': 'You can view and manage orders from the orders section in your dashboard.',
    },
    {
      'question': 'How do I change my restaurant hours?',
      'answer': 'Go to your restaurant settings to update your operating hours.',
    },
  ];


  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._faqs.map((faq) => _buildFAQItem(theme, faq)).toList(),
            
            const SizedBox(height: 24),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your message has been sent to support')),
                    );
                    _messageController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send Message'),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),

            _buildContactInfo(theme, Icons.call, 'Support Hotline', '+1 (555) 123-4567'),
            _buildContactInfo(theme, Icons.email, 'Email', 'support@campuscart.com'),
            _buildContactInfo(theme, Icons.access_time, 'Response Time', 'Within 24 hours'),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(ThemeData theme, Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              faq['answer'],
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(ThemeData theme, IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onBackground,
        ),
      ),
      subtitle: Text(value),
      contentPadding: EdgeInsets.zero,
    );
  }
}