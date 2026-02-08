import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage>
    with AutomaticKeepAliveClientMixin {
  late final InAppWebViewController _controller;

  bool _serverReady = false;
  bool _isLoading = true;

  final String serverUrl = "http://localhost:8080";

  // FAB position
  double fabX = 20;
  double fabY = 20;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _checkServerAndLoad();
  }

  Future<void> _checkServerAndLoad() async {
    while (!_serverReady) {
      try {
        final request = await HttpClient()
            .getUrl(Uri.parse(serverUrl))
            .then((req) => req.close());

        if (request.statusCode == 200) {
          _serverReady = true;
          if (mounted) {
            setState(() => _isLoading = false);
            _controller.loadUrl(urlRequest: URLRequest(url: WebUri(serverUrl)));
          }
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (_) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void reloadWebView() {
    if (_serverReady && mounted) {
      _controller.reload();
    } else if (!_serverReady && mounted) {
      _checkServerAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        InAppWebView(
          onWebViewCreated: (controller) {
            _controller = controller;
            if (_serverReady) {
              _controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(serverUrl)),
              );
            }
          },
          initialUrlRequest: URLRequest(url: WebUri("about:blank")),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            cacheEnabled: true,
          ),
        ),

        if (_isLoading) const Center(child: CircularProgressIndicator()),

        Positioned(
          left: fabX,
          bottom: fabY,
          child: GestureDetector(
            onPanStart: (_) => _isDragging = true,
            onPanUpdate: (details) {
              setState(() {
                fabX += details.delta.dx;
                fabY -= details.delta.dy;
              });
            },
            onPanEnd: (_) {
              _isDragging = false;
            },
            onTap: () {
              if (!_isDragging) {
                reloadWebView();
              }
            },
            child: FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
