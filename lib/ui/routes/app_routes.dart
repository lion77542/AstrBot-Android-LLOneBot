import 'package:get/get.dart';
import '../pages/terminal/terminal_page.dart';
import '../pages/webview/webview_page.dart';
import '../pages/settings/performance_settings_page.dart';

class AppRoutes {
  static const String terminal = '/terminal';
  static const String webview = '/webview';
  static const String performanceSettings = '/performance_settings';

  static final routes = [
    GetPage(
      name: terminal,
      page: () => const TerminalPage(),
    ),
    GetPage(
      name: webview,
      page: () => const WebViewPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: performanceSettings,
      page: () => const PerformanceSettingsPage(),
    ),
  ];
}
