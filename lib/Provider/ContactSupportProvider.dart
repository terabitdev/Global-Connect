import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  static const String adminEmail = 'Contact@global-connect.ai';
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }
  
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your message';
    }
    if (value.length < 10) {
      return 'Message should be at least 10 characters';
    }
    return null;
  }
  
  Future<void> sendEmail(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      setLoading(true);
      
      final String subject = 'Support Request from ${nameController.text}';
      final String body = '''
Name: ${nameController.text}
Email: ${emailController.text}

Message:
${messageController.text}
''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: adminEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      try {
        bool launched = false;
        
        // Try to launch with external application mode
        launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        
        // If that fails, try with default mode
        if (!launched) {
          launched = await launchUrl(emailUri);
        }
        
        if (launched) {
          // Success - clear the form
          clearForm();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening email client...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Show alternative contact method
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No email app found. Please email directly to: $adminEmail',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Copy Email',
                  textColor: Colors.white,
                  onPressed: () {
                    copyEmailToClipboard(context);
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setLoading(false);
      }
    }
  }
  
  void copyEmailToClipboard(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: adminEmail));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email address copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void clearForm() {
    nameController.clear();
    emailController.clear();
    messageController.clear();
  }
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.dispose();
  }
}