// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.lightGreen.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightGreen.shade50,
              Colors.white,
            ],
          ),
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Privacy Policy'),
              SizedBox(height: 8),
              _ParagraphText(
                'This Privacy Policy explains how we collect, use, and protect your personal information when you use our App. By using the App, you consent to the collection and use of your information as described in this Privacy Policy.', text: '',
              ),
              SizedBox(height: 24),
              
              _SectionTitle(title: '1. Information We Collect'),
              _BulletPoint(
                text: 'Basic account details such as name, email address, and contact information.',
              ),
              _BulletPoint(
                text: 'Location data to connect users with nearby restaurants.',
              ),
              _BulletPoint(
                text: 'Transaction details related to the convenience fee.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '2. How We Use Information'),
              _BulletPoint(
                text: 'To provide seamless connectivity between users and local restaurants.',
              ),
              _BulletPoint(
                text: 'To process and manage convenience fee payments.',
              ),
              _BulletPoint(
                text: 'To improve user experience and enhance platform services.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '3. App Permissions'),
              _BulletPoint(
                text: 'Location: To identify nearby restaurants.',
              ),
              _BulletPoint(
                text: 'Storage: To save temporary preferences and cache.',
              ),
              _BulletPoint(
                text: 'Notifications: To send updates regarding order status and offers.',
              ),
              _BulletPoint(
                text: 'Phone API: For authentication and user verification purposes.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '4. Third-Party Services'),
              _BulletPoint(
                text: 'Google Maps API (for location services)',
              ),
              _BulletPoint(
                text: 'Firebase Analytics (for performance monitoring)',
              ),
              _ParagraphText(
                'These third-party providers may collect data in accordance with their respective privacy policies.', text: '',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '5. Data Sharing'),
              _BulletPoint(
                text: 'User details are shared only with the respective restaurant to fulfill the order.',
              ),
              _BulletPoint(
                text: 'We do not sell or rent user data to third parties.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '6. Payments'),
              _BulletPoint(
                text: 'Payments for food orders are made directly to restaurant owners.',
              ),
              _BulletPoint(
                text: 'The App only processes minimal data necessary for convenience fee transactions.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '7. Data Security'),
              _BulletPoint(
                text: 'We implement reasonable security measures to protect user data.',
              ),
              _BulletPoint(
                text: 'However, no method of data transmission or storage is completely secure, and we cannot guarantee absolute protection.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '8. User Rights'),
              _BulletPoint(
                text: 'Users can request to update or delete their data at any time by contacting our support team.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '9. Children\'s Privacy'),
              _BulletPoint(
                text: 'The App is not intended for children under the age of 13.',
              ),
              _BulletPoint(
                text: 'If you are under 18, you must use the app under the supervision of a parent or guardian.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '10. Policy Updates'),
              _BulletPoint(
                text: 'This Privacy Policy may be updated periodically. Users will be notified of significant changes within the App.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '11. Developer Contact Information'),
              _ContactInfo(
                name: 'Primary Developer: Kannan T',
                email: 'kannan7k.rlm@gmail.com',
                phone: '8438315897',
                address: 'Central University of Karnataka',
              ),
              SizedBox(height: 16),
              _ContactInfo(
                name: 'Co-Developer: Gopinathan S',
                email: 'gopinathansv7@gmail.com',
                phone: '9940743620',
                address: 'Central University of Karnataka',
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Reuse the same helper widgets from TermsAndConditionsScreen
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.lightGreen,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.lightGreen,
        height: 1.4,
      ),
    );
  }
}

class _ParagraphText extends StatelessWidget {
  final String text;
  const _ParagraphText(String s, {required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.lightGreen,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String address;
  
  const _ContactInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightGreen.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.lightGreen,
            ),
          ),
          const SizedBox(height: 8),
          _ContactItem(icon: Icons.email, text: email),
          _ContactItem(icon: Icons.phone, text: phone),
          _ContactItem(icon: Icons.location_on, text: address),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _ContactItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}