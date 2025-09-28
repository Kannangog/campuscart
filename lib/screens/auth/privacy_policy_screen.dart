import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This Privacy Policy explains how we collect, use, and protect your personal information when you use our App.\n\n'
              '1. **Information We Collect**\n'
              '- Basic account details such as name, email address, and contact information.\n'
              '- Location data to connect users with nearby restaurants.\n'
              '- Transaction details related to the convenience fee.\n\n'
              '2. **How We Use Information**\n'
              '- To provide seamless connectivity between users and local restaurants.\n'
              '- To process and manage convenience fee payments.\n'
              '- To improve user experience and enhance platform services.\n\n'
              '3. **Data Sharing**\n'
              '- User details are shared only with the respective restaurant to fulfill the order.\n'
              '- We do not sell or rent user data to third parties.\n\n'
              '4. **Payments**\n'
              '- Payments for food orders are made directly to restaurant owners.\n'
              '- The App only processes minimal data necessary for convenience fee transactions.\n\n'
              '5. **Data Security**\n'
              '- We implement reasonable security measures to protect user data.\n'
              '- However, no method of data transmission or storage is fully secure, and we cannot guarantee absolute protection.\n\n'
              '6. **User Rights**\n'
              '- Users can request to update or delete their data at any time by contacting our support team.\n\n'
              '7. **Children\'s Privacy**\n'
              '- The App is not intended for children under the age of 13. We do not knowingly collect personal information from children.\n\n'
              '8. **Policy Updates**\n'
              '- This Privacy Policy may be updated periodically. Users will be notified of significant changes within the App.\n\n'
              'By using the App, you consent to the collection and use of your information as described in this Privacy Policy.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}