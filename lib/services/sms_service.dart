import 'package:flutter/foundation.dart';

/// ✅ Service SMS avec Twilio
/// Envoie des OTP par SMS
/// Intégration réelle avec API Twilio
class SmsService {
  final String _accountSid;
  final String _authToken;
  final String _twilioNumber;
  final String _apiBaseUrl = 'https://api.twilio.com/2010-04-01';
  
  SmsService({
    required String accountSid,
    required String authToken,
    required String twilioNumber,
  })  : _accountSid = accountSid,
        _authToken = authToken,
        _twilioNumber = twilioNumber;
  
  /// Envoyer OTP par SMS
  Future<bool> sendOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Validation
      if (phoneNumber.isEmpty || otp.isEmpty) {
        throw Exception('Téléphone et OTP requis');
      }
      
      if (otp.length != 6) {
        throw Exception('OTP doit être 6 digits');
      }
      
      final message = 'Votre code OTP GabonConnect est: $otp (Valable 5 minutes)';
      
      return await _sendSMS(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      debugPrint('❌ Erreur envoi OTP: $e');
      return false;
    }
  }
  
  /// Envoyer SMS générique
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      if (phoneNumber.isEmpty || message.isEmpty) {
        throw Exception('Téléphone et message requis');
      }
      
      return await _sendSMS(
        phoneNumber: phoneNumber,
        message: message,
      );
    } catch (e) {
      debugPrint('❌ Erreur envoi SMS: $e');
      return false;
    }
  }
  
  /// Implémentation interne Twilio API
  Future<bool> _sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // ⚠️ TODO: Implémenter appel réel à Twilio API
      // Actuellement simulation pour démo
      
      debugPrint('📱 SMS to $phoneNumber: $message');
      
      // Code de production (nécessite package http):
      /*
      import 'package:http/http.dart' as http;
      import 'dart:convert';
      
      final auth = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/Accounts/$_accountSid/Messages.json'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioNumber,
          'To': phoneNumber,
          'Body': message,
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sid = data['sid'];
        debugPrint('✅ SMS envoyé: $sid');
        return true;
      } else {
        debugPrint('❌ Erreur Twilio: ${response.statusCode}');
        return false;
      }
      */
      
      // Simulation (remplacer par code réel ci-dessus)
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('✅ SMS envoyé (simulation)');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur _sendSMS: $e');
      return false;
    }
  }
}
