import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  // Controller for the URL text field
  final TextEditingController _urlController = TextEditingController();

  // Completer to handle the creation of the web view controller
  final Completer<WebViewController> _webController =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          // Initial URL for the WebView
          initialUrl: 'https://nadeer12.github.io/flutter_api_communication/',
          // Allowing unrestricted JavaScript execution
          javascriptMode: JavascriptMode.unrestricted,
          // Callback when the WebView is created
          onWebViewCreated: (WebViewController webViewController) {
            _webController.complete(webViewController);
          },
          // JavaScript channels for communication between Flutter and WebView
          javascriptChannels: <JavascriptChannel>{
            JavascriptChannel(
              name: 'flutter',
              onMessageReceived: (JavascriptMessage message) {
                // Handling the message received from JavaScript
                fetchData(message.message).then((apiData) {
                  // Executing JavaScript function to display API data
                  _webController.future.then((controller) =>
                      controller.evaluateJavascript(
                          'displayApiData("${_urlController.text}", ${jsonEncode(apiData)})'));

                  // Showing a SnackBar to indicate successful data fetch
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data fetch successful'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                });

                // Extracting data from the JSON message
                Map<String, dynamic> data = jsonDecode(message.message);
                String apiUrl = data['apiUrl'];
                String method = data['method'];
                Map<String, dynamic> formData = data['data'];

                // Checking the HTTP method and making a POST request if required
                if (method == 'POST') {
                  postData(apiUrl, formData);
                } else {
                  // Do nothing for other HTTP methods
                  null;
                }
              },
            ),
          },
        ),
      ),
    );
  }

  // Helper function to display an error Snackbar
  void ErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to fetch data from an API
  Future<dynamic> fetchData(String apiUrl) async {
    try {
      // Sending a GET request to the specified API
      final response = await http.get(Uri.parse(apiUrl));
      
      // Checking the HTTP status code of the response
      if (response.statusCode == 200) {
        // Parsing the JSON response if successful
        final dynamic data = jsonDecode(response.body);
        return data;
      } else {
        // Throwing an error if the response status code is not 200
        throw 'Failed to fetch data (HTTP ${response.statusCode})';
      }
    } catch (error) {
      // Handling and displaying errors with a Snackbar
      ErrorSnackbar('Error Fetching data: $error');
      return null;
    }
  }

  // Function to post data to an API
  Future<void> postData(String apiUrl, Map<String, dynamic> data) async {
    try {
      // Sending a POST request to the specified API with JSON data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      // Checking the HTTP status code of the response
      if (response.statusCode == 200) {
        // Showing a Snackbar to indicate successful data posting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data posted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Throwing an error if the response status code is not 200
        throw 'Failed to post data (HTTP ${response.statusCode})';
      }
    } catch (error) {
      // Handling and displaying errors with a Snackbar
      ErrorSnackbar('Error Posting Data: $error');
      return null;
    }
  }
}
