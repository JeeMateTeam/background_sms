// ignore_for_file: constant_identifier_names
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sms status enum
enum SmsStatus { sendSuccess, sendFailed }

typedef MessageHandler = Function(ReceivedSMS message);

/// SMS Receiver which can be used in background/foreground task
class BackgroundSms {
  /// Platform channel
  static const _channel = MethodChannel('background_sms');

  late MessageHandler _onNewMessage;

  static final _instance = BackgroundSms._newInstance();

  /// Singleton instance
  static BackgroundSms get instance => _instance;

  BackgroundSms._newInstance() {
    _channel.setMethodCallHandler(_handler);
  }

  /// Log tag
  static const TAG = "BackgroundSMS:";

  static const METHOD_SEND = 'sendSms';
  static const METHOD_RECEIVER_START = 'startReceiver';
  static const METHOD_RECEIVER_STOP = 'stopReceiver';
  static const METHOD_ON_MESSAGE = 'onMessageReceiver';

  /// Allows to send SMS
  static Future<SmsStatus> sendMessage({
    required String phoneNumber,
    required String body,
    int? simSlot,
  }) async {
    try {
      String? result = await _channel.invokeMethod(METHOD_SEND, <String, dynamic>{
        "phone": phoneNumber,
        "msg": body,
        "simSlot": simSlot,
      });
      return result == "Sent" ? SmsStatus.sendSuccess : SmsStatus.sendFailed;
    } on PlatformException catch (e) {
      debugPrint('$TAG${e.toString()}');
      return SmsStatus.sendFailed;
    }
  }

  /// Allows to check if multi-sim is supported
  static Future<bool?> get isSupportCustomSim async {
    try {
      return await _channel.invokeMethod('isSupportMultiSim');
    } on PlatformException catch (e) {
      debugPrint('$TAG${e.toString()}');
      return true;
    }
  }

  /// Start listening incoming SMS
  void listenIncomingSms({required MessageHandler onNewMessage}) {
    _startMsgService();
    _onNewMessage = onNewMessage;
  }

  /// Stop listening incoming SMS
  void stopListenIncomingSms() {
    _stopMsgService();
  }

  void _startMsgService() {
    _channel.invokeMethod<String?>(METHOD_RECEIVER_START);
  }

  void _stopMsgService() async {
    _channel.invokeMethod<String?>(METHOD_RECEIVER_STOP);
  }

  // @visibleForTesting
  Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case METHOD_ON_MESSAGE:
        final message = (call.arguments as Map).cast<String, dynamic>();
        debugPrint('${TAG}onNewMessage:$message');
        return _onNewMessage(ReceivedSMS.fromMap(message));
    }
  }
}

/// Received SMS Data
class ReceivedSMS {
  String? address;
  String? body;

  ReceivedSMS.fromMap(Map<String, dynamic> message) {
    address = message['address'];
    body = message['body'];
  }

  Map<String, dynamic> toMap() {
    return {
      "address": address,
      "body": body,
    };
  }
}