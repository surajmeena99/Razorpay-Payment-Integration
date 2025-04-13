import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> checkConnectivity() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  print('connectivityResult $connectivityResult}');
  if (connectivityResult == ConnectivityResult.none) {
    print('No internet connection false');

    return false;
  } else {
    print('No internet connection true');
    return true;
  }
}

void showSnackBarView(BuildContext context, String message, Color backGroundColor) {
  SnackBar snackBarContent = SnackBar(
    content: Text(message,
      style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold
      ),
    ),
    backgroundColor: backGroundColor,
    elevation: 10,
    behavior: SnackBarBehavior.floating,
    margin: Platform.isIOS
        ? const EdgeInsets.all(20)
        : EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100,
        right: 20,
        left: 20),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBarContent);
}