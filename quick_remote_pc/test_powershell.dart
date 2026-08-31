// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'lib/services/input_simulator.dart';

void main() async {
  debugPrint = (String? message, {int? wrapWidth}) {
    print(message);
  };
  
  print('1. Starting PowerShell by sending a command...');
  var res = await InputSimulator.getSlideState();
  print('Initial result: $res');

  print('2. Killing powershell.exe manually...');
  var killResult = Process.runSync('taskkill', ['/F', '/IM', 'powershell.exe']);
  print('Taskkill output: ${killResult.stdout}');
  
  print('3. Sending another command to see if it recovers...');
  var res2 = await InputSimulator.getSlideState();
  print('Recovered result: $res2');
  
  print('SUCCESS');
  exit(0);
}
