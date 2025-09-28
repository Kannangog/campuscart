import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to our application ("App"). By accessing or using this App, you agree to the following Terms and Conditions. If you do not agree, please refrain from using the App.\n\n'
              '1. **Service Overview**\n'
              '- The App connects users with local restaurants, hotels, and food stalls located within campuses, work environments, and local ecosystems.\n'
              '- The App does not prepare or deliver food. Food preparation and delivery are the sole responsibility of the respective restaurant owners.\n\n'
              '2. **Payments**\n'
              '- Users pay directly to the restaurant owners for food orders.\n'
              '- The App only charges a minimal convenience fee for platform usage.\n'
              '- The App does not collect or store full payment details except as required for processing the convenience fee.\n\n'
              '3. **Delivery**\n'
              '- Delivery is handled entirely by the restaurant owners.\n'
              '- The App has no delivery partners and bears no responsibility for delivery timelines or service quality.\n\n'
              '4. **Food Quality and Responsibility**\n'
              '- The restaurant owner is solely responsible for the hygiene, safety, and quality of the food provided.\n'
              '- Any complaint regarding unhygienic or unsafe food will be investigated, and the App reserves the right to ban the restaurant or the specific food item without prior consent of the restaurant owner.\n\n'
              '5. **Copyright and Restrictions**\n'
              '- The App, including its name, design, and features, is copyrighted. Unauthorized copying, reproduction, or distribution is strictly prohibited.\n'
              '- Any violation may result in legal action.\n\n'
              '6. **Limitation of Liability**\n'
              '- The App acts only as a connecting platform and holds no liability for disputes, delivery issues, food quality, or payment discrepancies between users and restaurant owners.\n\n'
              '7. **Termination of Use**\n'
              '- The App reserves the right to suspend or terminate accounts of users or restaurants who violate these terms.\n\n'
              '8. **Changes to Terms**\n'
              '- The App may update these Terms and Conditions at any time. Continued use of the App after such updates will be deemed acceptance of the revised terms.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}