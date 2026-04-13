import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

const MethodChannel _smsChannel = MethodChannel('com.lasthope.app/sms');

Future<void> sendSMS({
  required String message,
  required List<String> recipients,
  bool sendDirect = true,
}) async {
  if (recipients.isEmpty) {
    debugPrint('No recipients for SMS');
    return;
  }

  // Try direct sending first via Native MethodChannel
  if (sendDirect && Platform.isAndroid) {
    try {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        for (String number in recipients) {
          try {
            await _smsChannel.invokeMethod('sendSms', {
              'phone': number,
              'msg': message,
            });
            debugPrint('Direct Native SMS sent to $number via MethodChannel');
          } catch (e) {
            debugPrint('Failed to send SMS to $number via MethodChannel: $e');
          }
        }
        return; // Always return if permission is granted, avoiding double clicks
      } else {
        debugPrint('SMS Permissions denied, falling back to url_launcher');
      }
    } catch (e) {
      debugPrint('Error sending direct SMS: $e');
    }
  }

  // Fallback to url_launcher ONLY if direct sending fails permission check or is disabled
  final String recipientsStr = recipients.join(',');
  final Uri smsLaunchUri = Uri(
    scheme: 'sms',
    path: recipientsStr,
    queryParameters: <String, String>{'body': message},
  );

  try {
    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      if (Platform.isAndroid) {
         await launchUrl(smsLaunchUri, mode: LaunchMode.externalApplication);
      } else {
         debugPrint('Could not launch SMS');
         throw 'Could not launch SMS';
      }
    }
  } catch (e) {
    debugPrint('Error launching SMS: $e');
  }
}

Future<void> autoDial(String phoneNumber) async {
  if (phoneNumber.isEmpty) return;
  
  try {
    // Try to make a direct call without opening the dialer UI
    bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res != null && res) {
      debugPrint('Direct call initiated to $phoneNumber');
      return;
    }
  } catch (e) {
    debugPrint('Error with direct call: $e');
  }

  // Fallback to standard dialer if direct call fails
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  try {
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (Platform.isAndroid) {
         await launchUrl(launchUri);
      }
      debugPrint('Could not launch dialer');
    }
  } catch (e) {
    debugPrint('Error launching dialer: $e');
  }
}
