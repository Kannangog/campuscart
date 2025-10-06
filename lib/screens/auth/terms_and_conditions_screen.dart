// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
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
              _SectionHeader(title: 'Terms and Conditions'),
              SizedBox(height: 8),
              _ParagraphText(
                'Welcome to our application ("App"). By accessing or using this App, you agree to the following Terms and Conditions. If you do not agree, please refrain from using the App.', text: '',
              ),
              SizedBox(height: 24),
              
              _SectionTitle(title: '1. Service Overview'),
              _BulletPoint(
                text: 'The App connects users with local restaurants, hotels, and food stalls located within campuses, work environments, and local ecosystems.',
              ),
              _BulletPoint(
                text: 'The App does not prepare or deliver food. Food preparation and delivery are the sole responsibility of the respective restaurant owners.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '2. Payments'),
              _BulletPoint(
                text: 'Users pay directly to the restaurant owners for food orders.',
              ),
              _BulletPoint(
                text: 'The App only charges a minimal convenience fee for platform usage.',
              ),
              _BulletPoint(
                text: 'The App does not collect or store full payment details except as required for processing the convenience fee.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '3. Delivery'),
              _BulletPoint(
                text: 'Delivery is handled entirely by the restaurant owners.',
              ),
              _BulletPoint(
                text: 'The App has no delivery partners and bears no responsibility for delivery timelines or service quality.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '4. Food Quality and Responsibility'),
              _BulletPoint(
                text: 'The restaurant owner is solely responsible for the hygiene, safety, and quality of the food provided.',
              ),
              _BulletPoint(
                text: 'Any complaint regarding unhygienic or unsafe food will be investigated, and the App reserves the right to ban the restaurant or the specific food item without prior consent of the restaurant owner.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '5. Copyright and Restrictions'),
              _BulletPoint(
                text: 'The App, including its name, design, and features, is copyrighted. Unauthorized copying, reproduction, or distribution is strictly prohibited.',
              ),
              _BulletPoint(
                text: 'Any violation may result in legal action.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '6. Limitation of Liability'),
              _BulletPoint(
                text: 'The App acts only as a connecting platform and holds no liability for disputes, delivery issues, food quality, or payment discrepancies between users and restaurant owners.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '7. Termination of Use'),
              _BulletPoint(
                text: 'The App reserves the right to suspend or terminate accounts of users or restaurants who violate these terms.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '8. Changes to Terms'),
              _BulletPoint(
                text: 'The App may update these Terms and Conditions at any time. Continued use of the App after such updates will be deemed acceptance of the revised terms.',
              ),
              SizedBox(height: 20),
              
              _SectionTitle(title: '9. Developer Contact Information'),
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