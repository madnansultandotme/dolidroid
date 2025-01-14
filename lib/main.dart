import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(DoliDroidApp());

class DoliDroidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoliDroid',
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = 'https://example.com';
  bool _showInput = true;
  late final WebViewController _webViewController;

  // List to store the history of visited links
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadHistory();
  }

  void _initializeWebView() {
    // Initialize the WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_currentUrl));
  }

  Future<void> _loadHistory() async {
    // Load history from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('urlHistory') ?? [];
    });
  }

  Future<void> _saveHistory() async {
    // Save history to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('urlHistory', _history);
  }

  void _loadUrl() {
    setState(() {
      _currentUrl = _urlController.text.trim();
      if (_currentUrl.isNotEmpty) {
        _currentUrl = _currentUrl.startsWith('http')
            ? _currentUrl
            : 'https://$_currentUrl';
        _webViewController.loadRequest(Uri.parse(_currentUrl));

        // Add the current URL to history
        if (!_history.contains(_currentUrl)) {
          _history.insert(0, _currentUrl); // Add at the top of the history
          if (_history.length > 5) {
            _history.removeLast(); // Keep only the top 5 links
          }
          _saveHistory(); // Persist the updated history
        }

        _showInput = false; // Hide input, button, and AppBar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showInput
          ? AppBar(
              title: Text('DoliDroid'),
              backgroundColor: Colors.teal,
            )
          : null,
      body: _showInput
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Enter URL (e.g., https://example.com)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Dropdown showing history of links
                    if (_history.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Select from history'),
                          items: _history
                              .map((link) => DropdownMenuItem<String>(
                                    value: link,
                                    child: Text(
                                      link,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _urlController.text = value!;
                            });
                          },
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _loadUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('Go'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _webViewController),
    );
  }
}
