import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_colors.dart';

/// 通用 WebView 页面
class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({super.key, required this.title, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;
  bool _loading = true;

  bool get _supportsWebView =>
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    if (_supportsWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // 桌面平台自动用浏览器打开
      _openInBrowser();
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _controller != null
          ? Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_browser,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  SelectableText(widget.url,
                      style: const TextStyle(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.launch),
                    label: Text(
                        MaterialLocalizations.of(context).openAppDrawerTooltip),
                  ),
                ],
              ),
            ),
    );
  }
}
