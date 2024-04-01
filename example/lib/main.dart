import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _smsReceiverStatus = "Undefined";
  String _message = "";

  final phoneNumberCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    phoneNumberCtrl.dispose();
    bodyCtrl.dispose();
  }

  Future<bool> requestSmsPermission() async {
    return await Permission.sms.request().then(
      (PermissionStatus pStatus) {
        if (pStatus.isPermanentlyDenied) {
          openAppSettings();
        }
        return pStatus.isGranted;
      },
    );
  }

  Future<void> sendSmsReceiver(String phoneNumber, String body) async {
    if (await requestSmsPermission()) {
      BackgroundSms.sendMessage(phoneNumber: phoneNumber, body: body);
    }
  }

  Future<void> startSmsReceiver() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    if (await requestSmsPermission()) {
      BackgroundSms.listenIncomingSms(
        onNewMessage: (message) {
          debugPrint("You have new message:");
          debugPrint("::::::Message Address: ${message.phoneNumber}");
          debugPrint("::::::Message body: ${message.body}");

          if (!mounted) return;

          setState(() {
            _message = message.body ?? "Error reading message body.";
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _smsReceiverStatus = "Running";
      });
    }
  }

  void stopSmsReceiver() {
    BackgroundSms.stopListenIncomingSms();
    if (!mounted) return;

    setState(() {
      _smsReceiverStatus = "Stopped";
    });
  }

  Future<void> getContacts() async {
    final pStatus = await Permission.contacts.request();
    if (pStatus.isGranted) {
      List<Contact> contacts = await ContactsService.getContacts();
      debugPrint('Contacts count = ${contacts.length}');
    }
  }

  Widget get spacer => const SizedBox(height: 10);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: phoneNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                ),
                spacer,
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: "Body",
                    border: OutlineInputBorder(),
                  )
                ),
                spacer,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      child: const Text("Send SMS"),
                      onPressed: () => sendSmsReceiver(phoneNumberCtrl.text, bodyCtrl.text),
                    ),
                    ElevatedButton(
                      onPressed: getContacts,
                      child: const Text("Get Contacts"),
                    ),
                  ],
                ),
                spacer,
                const Divider(),
                spacer,
                Text("Latest Received SMS: $_message"),
                Text('EasySmsReceiver Status: $_smsReceiverStatus\n'),
                ElevatedButton(onPressed: startSmsReceiver, child: const Text("Start Receiver")),
                ElevatedButton(onPressed: stopSmsReceiver, child: const Text("Stop Receiver")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
