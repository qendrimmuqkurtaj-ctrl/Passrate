import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  NetworkUtils._();

  static Future<bool> isConnected() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if(connectivityResult.contains(ConnectivityResult.mobile)){
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.wifi)){
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.ethernet)){
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.vpn)){
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.bluetooth)){
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.other)){
      // Vpn connection active
      return true;
    }
    else if (connectivityResult.contains(ConnectivityResult.none)){
      // No available network
      return false;
    }
    else{
      return false;
    }
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup("example.com").timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  static Future<bool> isOnline() async {
    if (await isConnected()) {
      return await hasInternetConnection();
    }
    return false;
  }
}
