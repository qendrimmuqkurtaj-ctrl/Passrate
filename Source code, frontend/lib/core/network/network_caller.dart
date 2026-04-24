import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'network_response.dart';

class NetworkCaller {
  // Generic function to handle any HTTP request (GET, POST, PUT, DELETE)
  Future<NetworkResponse> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool isLogin = false,
  }) async {
    final Uri uri = Uri.parse(url);
    final Map<String, String> requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    try {
      // Make the request using a single method instead of multiple ones.
      Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await post(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'GET':
          response = await get(uri, headers: requestHeaders);
          break;
        case 'PUT':
          response = await put(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await delete(uri, headers: requestHeaders);
          break;
        case 'PATCH': // Add the PATCH case
          response = await patch(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body),
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle the response
      return _handleResponse(response, isLogin);
    } catch (e) {
      debugPrint('Error: $e');
      return NetworkResponse(isSuccess: false, errorMessage: e.toString());
    }
  }

  // Handles response from the HTTP request and returns a NetworkResponse
  NetworkResponse _handleResponse(Response response, bool isLogin) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Check if the response status is successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
          isSuccess: true,
          jsonResponse: jsonResponse,
          statusCode: response.statusCode,
        );
      }

      // If status code is 401, it might be related to login, handle accordingly
      if (response.statusCode == 401 && !isLogin) {
        return NetworkResponse(
          isSuccess: false,
          statusCode: response.statusCode,
          jsonResponse: jsonResponse,
        );
      }

      // Handle unsuccessful responses
      return NetworkResponse(
        isSuccess: false,
        statusCode: response.statusCode,
        jsonResponse: jsonResponse,
      );
    } catch (e) {
      return NetworkResponse(
        isSuccess: false,
        errorMessage: 'Error parsing response: ${e.toString()}',
      );
    }
  }

  // POST Request
  Future<NetworkResponse> postRequest(
    String url, {
    Map<String, dynamic>? body,
    bool isLogin = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      'POST',
      url,
      body: body,
      isLogin: isLogin,
      headers: headers,
    );
  }

  // GET Request
  Future<NetworkResponse> getRequest(
    String url, {
    Map<String, dynamic>? body,
    bool isLogin = false,
    Map<String, String>? headers,
  }) async {
    return _request('GET', url, body: body, isLogin: isLogin, headers: headers);
  }

  // PUT Request
  Future<NetworkResponse> putRequest(
    String url, {
    Map<String, dynamic>? body,
    bool isLogin = false,
    Map<String, String>? headers,
  }) async {
    return _request('PUT', url, body: body, isLogin: isLogin, headers: headers);
  }

  // DELETE Request
  Future<NetworkResponse> deleteRequest(
    String url, {
    Map<String, dynamic>? body,
    bool isLogin = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      'DELETE',
      url,
      body: body,
      isLogin: isLogin,
      headers: headers,
    );
  }

  // PATCH Request
  Future<NetworkResponse> patchRequest(
    String url, {
    Map<String, dynamic>? body,
    bool isLogin = false,
    Map<String, String>? headers,
  }) async {
    return _request(
      'PATCH',
      url,
      body: body,
      isLogin: isLogin,
      headers: headers,
    );
  }
}
