import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  EmailService._();
  static final instance = EmailService._();

  static const _serviceId = 'YOUR_EMAILJS_SERVICE_ID';
  static const _templateId = 'YOUR_EMAILJS_TEMPLATE_ID';
  static const _publicKey = 'YOUR_EMAILJS_PUBLIC_KEY';

  Future<bool> sendVerificationCode(String toEmail, String code) async {
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail,
          'code': code,
        },
      }),
    );
    return response.statusCode == 200;
  }
}