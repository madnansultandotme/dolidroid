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
  late final WebViewController _webViewController;

  // List to store the history of visited links
  List<String> _history = [];

  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadHistory();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true);
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
    String url = _urlController.text.trim();
    if (url.isNotEmpty) {
      url = url.startsWith('http') ? url : 'https://$url';
      _webViewController.loadRequest(Uri.parse(url));

      // Add the URL to history
      if (!_history.contains(url)) {
        setState(() {
          _history.insert(0, url);
          if (_history.length > 5) {
            _history.removeLast();
          }
        });
        _saveHistory(); // Persist updated history
      }
    }
  }

  void _updateNavigationState() async {
    _canGoBack = await _webViewController.canGoBack();
    _canGoForward = await _webViewController.canGoForward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DoliDroid'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _canGoBack
                ? () async {
                    await _webViewController.goBack();
                    _updateNavigationState();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _canGoForward
                ? () async {
                    await _webViewController.goForward();
                    _updateNavigationState();
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Enter URL (e.g., https://example.com)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
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
                SizedBox(height: 8),
                if (_history.isNotEmpty)
                  DropdownButton<String>(
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
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(
              controller: _webViewController
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageFinished: (url) => _updateNavigationState(),
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}
