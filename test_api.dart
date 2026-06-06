import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyDB5mmFfntgSc8idrPXu0RNvLfgxY9CUKc';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
  
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [{'role': 'user', 'parts': [{'text': 'Hello'}]}]
    })
  );
  
  print('Status Code: ${response.statusCode}');
  print('Body: ${response.body}');
}
