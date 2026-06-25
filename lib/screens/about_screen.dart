import 'package:flutter/material.dart';
import '../utils/about_info.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo placeholder — replace with Image.asset when you send the logo
            ClipOval(
              child: Image.asset(
                'assets/logo.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to ${AboutInfo.appName}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 180, 70, 11),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Description card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AboutInfo.description,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Us',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 180, 70, 11),
                        )),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('${AboutInfo.contactName} — ${AboutInfo.contactRole}'),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(AboutInfo.contactEmail),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.phone_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(AboutInfo.contactPhone),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Developed by ${AboutInfo.developerCompany}',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text('Version ${AboutInfo.version}',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}