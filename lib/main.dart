import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  bool _isUrlLoaded = false; // Flag to track if URL is loaded
  bool _isLoading = false; // Flag for loading spinner
  bool _isConnected = true; // Track internet connection
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadHistory();
    _checkInternetConnection();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('urlHistory') ?? [];
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('urlHistory', _history);
  }

  void _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _loadUrl() {
    String url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      url = url.startsWith('http') ? url : 'https://$url';
      _webViewController.loadRequest(Uri.parse(url));

      if (!_history.contains(url)) {
        setState(() {
          _history.insert(0, url);
          if (_history.length > 5) {
            _history.removeLast();
          }
        });
        _saveHistory();
      }

      setState(() {
        _isUrlLoaded = true;
      });
    }
  }

  void _updateNavigationState() async {
    bool canGoBack = await _webViewController.canGoBack();
    bool canGoForward = await _webViewController.canGoForward();
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
            onPressed: () async {
              bool canGoBack = await _webViewController.canGoBack();
              if (canGoBack) {
                await _webViewController.goBack();
                _updateNavigationState();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () async {
              bool canGoForward = await _webViewController.canGoForward();
              if (canGoForward) {
                await _webViewController.goForward();
                _updateNavigationState();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _isUrlLoaded
            ? Stack(
                children: [
                  WebViewWidget(
                    controller: _webViewController
                      ..setNavigationDelegate(
                        NavigationDelegate(
                          onPageFinished: (url) {
                            setState(() {
                              _isLoading = false;
                            });
                            _updateNavigationState();
                          },
                        ),
                      ),
                  ),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              )
            : _isConnected
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.teal.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: 'Enter URL (e.g., https://example.com)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 40,
                            ),
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text('Go'),
                        ),
                        SizedBox(height: 16),
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
                  )
                : Center(
                    child: Text(
                      'No Internet Connection! Please check your connection.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
      ),
    );
  }
}
