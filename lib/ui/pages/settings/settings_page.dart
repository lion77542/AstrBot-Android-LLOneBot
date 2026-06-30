import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:global_repository/global_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'performance_settings_page.dart';
import '../../controllers/terminal_controller.dart';
import '../../../core/constants/scripts.dart' as scripts;
import '../../../core/services/password_manager.dart';
import '../../../core/config/app_config.dart';

class SettingsPage extends StatefulWidget {
  final WebViewController astrBotController;
  final WebViewController llbotController;
  final Function(int) onNavigate;

  const SettingsPage({
    super.key,
    required this.astrBotController,
    required this.llbotController,
    required this.onNavigate,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';
  bool _isBatteryOptimizationIgnored = false;
  final HomeController homeController = Get.find<HomeController>();

  // 氓颅聵氓聜篓盲禄聨GitHub API猫聨路氓聫聳莽職聞氓聨聼氓搂聥盲赂聥猫陆陆URL
  String? _originalDownloadUrl;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkBatteryOptimizationStatus();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  // 忙拢聙忙聼楼莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧莽聤露忙聙?
  Future<void> _checkBatteryOptimizationStatus() async {
    if (!Platform.isAndroid) return;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      setState(() {
        _isBatteryOptimizationIgnored = status.isGranted;
      });
    } catch (e) {
      Log.e('忙拢聙忙聼楼莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧莽聤露忙聙聛氓陇卤猫麓? $e', tag: 'AstrBot');
    }
  }

  // 猫炉路忙卤聜莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧
  Future<void> _requestBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (status.isGranted) {
        Get.snackbar(
          '氓路虏忙聨聢忙聺?,
          '氓路虏猫聨路氓戮聴莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧忙聺聝茅聶?,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 猫炉路忙卤聜忙聺聝茅聶聬
      final result = await Permission.ignoreBatteryOptimizations.request();

      // 莽颅聣氓戮聟氓炉鹿猫炉聺忙隆聠氓聟鲁茅聴颅氓聬聨茅聡聧忙聳掳忙拢聙忙聼楼莽聤露忙聙?
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkBatteryOptimizationStatus();

      if (result.isGranted) {
        Get.snackbar(
          '忙聨聢忙聺聝忙聢聬氓聤聼',
          '氓路虏猫聨路氓戮聴莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧忙聺聝茅聶?,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          '忙聨聢忙聺聝氓陇卤猫麓楼',
          '忙聹陋猫聨路氓戮聴莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧忙聺聝茅聶?,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Log.e('猫炉路忙卤聜莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧氓陇卤猫麓楼: $e', tag: 'AstrBot');
      Get.snackbar(
        '猫炉路忙卤聜氓陇卤猫麓楼',
        '猫炉路忙卤聜莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧忙聴露氓聫聭莽聰聼茅聰聶猫炉? $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // 忙拢聙忙聼楼忙聸麓忙聳?
  Future<void> _checkForUpdates() async {
    try {
      // 忙炉聫忙卢隆忙拢聙忙聼楼忙聸麓忙聳掳忙聴露茅聡聧莽陆庐氓聨聼氓搂聥URL
      _originalDownloadUrl = null;

      // 忙聵戮莽陇潞氓聤聽猫陆陆忙聫聬莽陇潞
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 猫聨路氓聫聳氓陆聯氓聣聧莽聣聢忙聹卢
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 盲陆驴莽聰篓茅聲聹氓聝聫忙潞聬猫聨路氓聫聳忙聹聙忙聳掳莽聣聢忙聹卢盲驴隆忙聛?
      final mirrors = [
        ...Config.githubApiMirrors.map((mirror) =>
            '$mirror/${Config.githubApi}${Config.githubReleasesPath}'),
        '${Config.githubApi}${Config.githubReleasesPath}',
      ];

      Map<String, dynamic>? releaseData;

      for (final mirror in mirrors) {
        try {
          final response = await http.get(
            Uri.parse(mirror),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            releaseData = jsonDecode(response.body) as Map<String, dynamic>;
            break;
          }
        } catch (e) {
          Log.w('茅聲聹氓聝聫忙潞?$mirror 猫炉路忙卤聜氓陇卤猫麓楼: $e', tag: 'AstrBot');
          continue;
        }
      }

      Get.back(); // 氓聟鲁茅聴颅氓聤聽猫陆陆忙聫聬莽陇潞

      if (releaseData == null) {
        Get.snackbar(
          '忙拢聙忙聼楼氓陇卤猫麓?,
          '忙聴聽忙鲁聲猫驴聻忙聨楼氓聢掳忙聸麓忙聳掳忙聹聧氓聤隆氓聶篓',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // 猫搂拢忙聻聬忙聹聙忙聳掳莽聣聢忙聹卢氓聫路
      final latestVersion =
          (releaseData['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final releaseNotes = releaseData['body'] as String? ?? '忙職聜忙聴聽忙聸麓忙聳掳猫炉麓忙聵聨';

      // 忙炉聰猫戮聝莽聣聢忙聹卢氓聫?
      if (_compareVersions(latestVersion, currentVersion) > 0) {
        // 忙聹聣忙聳掳莽聣聢忙聹卢茂录聦忙聵戮莽陇潞忙聸麓忙聳掳氓炉鹿猫炉聺忙隆聠
        _showUpdateDialog(latestVersion, releaseNotes, releaseData);
      } else {
        Get.snackbar(
          '氓路虏忙聵炉忙聹聙忙聳掳莽聣聢忙聹?,
          '氓陆聯氓聣聧莽聣聢忙聹卢 $currentVersion 氓路虏忙聵炉忙聹聙忙聳掳莽聣聢忙聹?,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.back(); // 氓聟鲁茅聴颅氓聤聽猫陆陆忙聫聬莽陇潞
      Log.e('忙拢聙忙聼楼忙聸麓忙聳掳氓陇卤猫麓? $e', tag: 'AstrBot');
      Get.snackbar(
        '忙拢聙忙聼楼氓陇卤猫麓?,
        '忙拢聙忙聼楼忙聸麓忙聳掳忙聴露氓聫聭莽聰聼茅聰聶猫炉炉: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 莽聣聢忙聹卢氓聫路忙炉聰猫戮?
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  // 忙聵戮莽陇潞忙聸麓忙聳掳氓炉鹿猫炉聺忙隆?
  void _showUpdateDialog(
      String version, String releaseNotes, Map<String, dynamic> releaseData) {
    Get.dialog(
      Dialog(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '氓聫聭莽聨掳忙聳掳莽聣聢忙聹?$version',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: MarkdownBody(
                  data: releaseNotes,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(fontSize: 14),
                    listBullet: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('氓聟鲁茅聴颅'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showDownloadSourceDialog(releaseData);
                    },
                    child: const Text('氓聨禄盲赂聥猫陆?),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 忙聵戮莽陇潞盲赂聥猫陆陆忙潞聬茅聙聣忙聥漏氓炉鹿猫炉聺忙隆?
  void _showDownloadSourceDialog(Map<String, dynamic> releaseData) {
    // 氓娄聜忙聻聹猫驴聵忙虏隆忙聹聣盲驴聺氓颅聵氓聨聼氓搂聥URL茂录聦盲禄聨releaseData盲赂颅忙聻聞茅聙?
    if (_originalDownloadUrl == null) {
      final assets = releaseData['assets'] as List?;
      final tagName = releaseData['tag_name'] as String?;

      if (tagName == null || assets == null) {
        Get.snackbar(
          '盲赂聥猫陆陆氓陇卤猫麓楼',
          '忙聹陋忙聣戮氓聢掳莽聣聢忙聹卢盲驴隆忙聛?,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 忙聼楼忙聣戮APK忙聳聡盲禄露氓聬?
      String? apkFileName;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkFileName = name;
          break;
        }
      }

      if (apkFileName == null) {
        Get.snackbar(
          '盲赂聥猫陆陆氓陇卤猫麓楼',
          '忙聹陋忙聣戮氓聢掳氓聫炉盲赂聥猫陆陆莽職聞APK忙聳聡盲禄露',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 莽聸麓忙聨楼忙聻聞茅聙聽GitHub氓聨聼氓搂聥盲赂聥猫陆陆茅聯戮忙聨楼茂录聦茅聛驴氓聟聧盲陆驴莽聰篓氓聫炉猫聝陆猫垄芦茅聲聹氓聝聫莽芦聶忙卤隆忙聼聯莽職聞URL
      _originalDownloadUrl =
          '${Config.githubDownloadBase}/$tagName/$apkFileName';
    }

    // 盲陆驴莽聰篓氓聨聼氓搂聥URL忙聻聞氓禄潞氓聬聞盲赂陋茅聲聹氓聝聫忙潞聬莽職聞盲赂聥猫陆陆茅聯戮忙聨楼
    final sources = [
      ...Config.downloadMirrors.map((mirror) => {
            'name': mirror['name']!,
            'icon':
                mirror['icon'] == 'speed' ? Icons.speed : Icons.cloud_download,
            'url': '${mirror['url']}/$_originalDownloadUrl',
          }),
      {
        'name': 'GitHub氓聨聼氓搂聥茅聯戮忙聨楼',
        'icon': Icons.cloud_download,
        'url': _originalDownloadUrl!,
        'description': '莽聸麓忙聨楼盲禄聨GitHub氓庐聵忙聳鹿忙聹聧氓聤隆氓聶篓盲赂聥猫陆陆茂录聦茅聙聼氓潞娄氓聫炉猫聝陆猫戮聝忙聟垄',
      },
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('茅聙聣忙聥漏盲赂聥猫陆陆忙潞?),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '猫炉路茅聙聣忙聥漏茅聙聜氓聬聢忙聜篓莽陆聭莽禄聹莽聨炉氓垄聝莽職聞盲赂聥猫陆陆忙潞?,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...sources.map((source) {
              return ListTile(
                leading: Icon(source['icon'] as IconData),
                title: Text(source['name'] as String),
                subtitle: source['description'] != null
                    ? Text(
                        source['description'] as String,
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                onTap: () async {
                  final url = source['url'] as String;
                  final uri = Uri.parse(url);

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    Get.back();
                  } else {
                    Get.snackbar(
                      '忙聣聯氓录聙氓陇卤猫麓楼',
                      '忙聴聽忙鲁聲忙聣聯氓录聙忙碌聫猫搂聢氓聶?,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('氓聫聳忙露聢'),
          ),
        ],
      ),
    );
  }

  // 忙聵戮莽陇潞忙路禄氓聤聽猫聡陋氓庐職盲鹿?WebView 氓炉鹿猫炉聺忙隆?
  void _showAddWebViewDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('忙路禄氓聤聽猫聡陋氓庐職盲鹿?WebView'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '忙聽聡茅垄聵',
                hintText: '盲戮聥氓娄聜茂录職忙聢聭莽職聞盲禄陋猫隆篓莽聸聵',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: '盲戮聥氓娄聜茂录?080/webui?token=***',
                helperText: '猫聡陋氓聤篓忙路禄氓聤聽氓聣聧莽录聙 http://127.0.0.1: \n猫聥楼茅聹聙盲陆驴莽聰篓https茂录聦猫炉路忙聣聥氓聤篓猫戮聯氓聟楼氓庐聦忙聲麓URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('氓聫聳忙露聢')),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              var url = urlController.text.trim();

              if (title.isEmpty || url.isEmpty) {
                Get.snackbar(
                  '猫戮聯氓聟楼茅聰聶猫炉炉',
                  '忙聽聡茅垄聵氓聮?URL 盲赂聧猫聝陆盲赂潞莽漏潞',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              // 氓娄聜忙聻聹URL盲赂聧氓聦聟氓聬芦氓聧聫猫庐庐氓聣聧莽录聙,猫聡陋氓聤篓忙路禄氓聤聽 http://127.0.0.1:
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'http://127.0.0.1:$url';
              }

              homeController.addCustomWebView(title, url);
              Get.back();

              Get.snackbar(
                '忙路禄氓聤聽忙聢聬氓聤聼',
                '猫聡陋氓庐職盲鹿?WebView "$title" 氓路虏忙路禄氓聤?,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('忙路禄氓聤聽'),
          ),
        ],
      ),
    );
  }

  // 忙聵戮莽陇潞莽录聳猫戮聭猫聡陋氓庐職盲鹿?WebView 氓炉鹿猫炉聺忙隆?
  void _showEditWebViewDialog(int index, Map<String, String> webview) {
    final titleController = TextEditingController(text: webview['title']);

    // 氓掳聠氓庐聦忙聲麓URL猫陆卢忙聧垄盲赂潞莽庐聙氓聦聳忙聽录氓录聫莽聰篓盲潞聨莽录聳猫戮?
    String displayUrl = webview['url'] ?? '';
    if (displayUrl.startsWith('https://127.0.0.1:')) {
      displayUrl = displayUrl.substring('https://127.0.0.1:'.length);
    } else if (displayUrl.startsWith('http://127.0.0.1:')) {
      displayUrl = displayUrl.substring('http://127.0.0.1:'.length);
    }

    final urlController = TextEditingController(text: displayUrl);

    Get.dialog(
      AlertDialog(
        title: const Text('莽录聳猫戮聭猫聡陋氓庐職盲鹿?WebView'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '忙聽聡茅垄聵',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                helperText: '猫聡陋氓聤篓忙路禄氓聤聽氓聣聧莽录聙 http://127.0.0.1: \n猫聥楼茅聹聙盲陆驴莽聰篓https,猫炉路忙聣聥氓聤篓猫戮聯氓聟楼氓庐聦忙聲麓URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('氓聫聳忙露聢')),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              var url = urlController.text.trim();

              if (title.isEmpty || url.isEmpty) {
                Get.snackbar(
                  '猫戮聯氓聟楼茅聰聶猫炉炉',
                  '忙聽聡茅垄聵氓聮?URL 盲赂聧猫聝陆盲赂潞莽漏潞',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              // 氓娄聜忙聻聹URL盲赂聧氓聦聟氓聬芦氓聧聫猫庐庐氓聣聧莽录聙,猫聡陋氓聤篓忙路禄氓聤聽 http://127.0.0.1:
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'http://127.0.0.1:$url';
              }

              homeController.updateCustomWebView(index, title, url);
              Get.back();

              Get.snackbar(
                '忙聸麓忙聳掳忙聢聬氓聤聼',
                '猫聡陋氓庐職盲鹿?WebView 氓路虏忙聸麓忙聳?,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('盲驴聺氓颅聵'),
          ),
        ],
      ),
    );
  }

  // 莽隆庐猫庐陇氓聢聽茅聶陇猫聡陋氓庐職盲鹿?WebView
  void _confirmDeleteWebView(int index, String title) {
    Get.dialog(
      AlertDialog(
        title: const Text('莽隆庐猫庐陇氓聢聽茅聶陇'),
        content: Text('莽隆庐氓庐職猫娄聛氓聢聽茅聶陇猫聡陋氓庐職盲鹿聣 WebView "$title" 氓聬聴茂录聼'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('氓聫聳忙露聢')),
          TextButton(
            onPressed: () {
              homeController.removeCustomWebView(index);
              Get.back();

              Get.snackbar(
                '氓聢聽茅聶陇忙聢聬氓聤聼',
                '猫聡陋氓庐職盲鹿?WebView "$title" 氓路虏氓聢聽茅聶?,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('氓聢聽茅聶陇', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 忙聣搂猫隆聦氓陇聡盲禄陆忙聯聧盲陆聹
  Future<bool> _performBackup({bool showLoadingDialog = false}) async {
    try {
      // 忙拢聙忙聼楼氓鹿露猫炉路忙卤聜氓颅聵氓聜篓忙聺聝茅聶聬
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // 氓娄聜忙聻聹 MANAGE_EXTERNAL_STORAGE 忙聹陋忙聨聢盲潞聢茂录聦氓掳聺猫炉聲盲录聽莽禄聼莽職聞氓颅聵氓聜篓忙聺聝茅聶?
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              Get.snackbar(
                '忙聺聝茅聶聬盲赂聧猫露鲁',
                '茅聹聙猫娄聛氓颅聵氓聜篓忙聺聝茅聶聬忙聣聧猫聝陆氓陇聡盲禄陆忙聲掳忙聧?,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              return false;
            }
          }
        }
      }

      // 忙聺聝茅聶聬猫聨路氓聫聳忙聢聬氓聤聼氓聬聨茂录聦氓娄聜忙聻聹茅聹聙猫娄聛忙聵戮莽陇潞氓聤聽猫陆陆氓炉鹿猫炉聺忙隆聠
      if (showLoadingDialog) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }

      // 猫聨路氓聫聳氓陆聯氓聣聧忙聴露茅聴麓忙聢?
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      // 氓陇聡盲禄陆忙聳聡盲禄露猫路炉氓戮聞茂录聢盲驴聺氓颅聵氓聢掳盲赂聥猫陆陆忙聳聡盲禄露氓陇鹿茂录聣
      final backupDir = Directory('/storage/emulated/0/Download/AstrBot');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final backupFileName = 'AstrBot-backup-$timestamp.tar.gz';
      final backupPath = '${backupDir.path}/$backupFileName';

      // 盲陆驴莽聰篓 tar 氓聭陆盲禄陇氓聨聥莽录漏 data 莽聸庐氓陆聲
      final dataPath = '${scripts.ubuntuPath}/root/AstrBot/data';
      final dataDir = Directory(dataPath);

      if (!await dataDir.exists()) {
        Get.snackbar(
          '氓陇聡盲禄陆氓陇卤猫麓楼',
          'AstrBot 忙聲掳忙聧庐莽聸庐氓陆聲盲赂聧氓颅聵氓聹?,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // 忙聣搂猫隆聦氓陇聡盲禄陆氓聭陆盲禄陇
      final result = await Process.run('${RuntimeEnvir.binPath}/busybox', [
        'tar',
        '-czf',
        backupPath,
        '-C',
        '${scripts.ubuntuPath}/root/AstrBot',
        'data',
      ]);

      if (result.exitCode == 0) {
        final backupFile = File(backupPath);
        final fileSize = await backupFile.length();
        final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);

        if (showLoadingDialog) {
          Get.back(); // 氓聟鲁茅聴颅氓聤聽猫陆陆氓炉鹿猫炉聺忙隆?
        }

        Get.snackbar(
          '氓陇聡盲禄陆忙聢聬氓聤聼',
          '氓陇聡盲禄陆忙聳聡盲禄露: $backupFileName\n氓陇搂氓掳聫: ${fileSizeMB}MB',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        Log.i('氓陇聡盲禄陆忙聢聬氓聤聼: $backupPath (${fileSizeMB}MB)', tag: 'AstrBot');
        return true;
      } else {
        if (showLoadingDialog) {
          Get.back(); // 氓聟鲁茅聴颅氓聤聽猫陆陆氓炉鹿猫炉聺忙隆?
        }

        Get.snackbar(
          '氓陇聡盲禄陆氓陇卤猫麓楼',
          '茅聰聶猫炉炉: ${result.stderr}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Log.e('氓陇聡盲禄陆氓陇卤猫麓楼: ${result.stderr}', tag: 'AstrBot');
        return false;
      }
    } catch (e) {
      if (showLoadingDialog) {
        Get.back(); // 氓聟鲁茅聴颅氓聤聽猫陆陆氓炉鹿猫炉聺忙隆?
      }

      Get.snackbar(
        '氓陇聡盲禄陆氓陇卤猫麓楼',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Log.e('氓陇聡盲禄陆氓录聜氓赂赂: $e', tag: 'AstrBot');
      return false;
    }
  }

  // 忙聵戮莽陇潞氓驴芦茅聙聼莽聶禄氓陆聲QQ氓炉鹿猫炉聺忙隆?
  void _showQuickLoginDialog() async {
    // LLBot 猫聡陋氓聤篓莽聶禄氓陆聲茅聙職猫驴聡氓聬炉氓聤篓猫聞職忙聹卢莽職?AUTO_LOGIN_QQ 莽聨炉氓垄聝氓聫聵茅聡聫忙聨搂氓聢露
    // 猫驴聶茅聡聦猫炉禄氓聫聳/氓聠聶氓聟楼盲赂聙盲赂陋莽庐聙氓聧聲莽職聞茅聟聧莽陆庐忙聳聡盲禄露茂录聦莽聰卤氓聬炉氓聤篓猫聞職忙聹卢猫炉禄氓聫聳
    final autoLoginFile = File('${scripts.ubuntuPath}/root/llbot_auto_login.conf');
    String currentQQ = '';

    if (await autoLoginFile.exists()) {
      currentQQ = (await autoLoginFile.readAsString()).trim();
    }

    final qqController = TextEditingController(text: currentQQ);

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('氓驴芦茅聙聼莽聶禄氓陆?QQ (LLBot)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('猫庐戮莽陆庐猫聡陋氓聤篓莽聶禄氓陆聲莽職?QQ 氓聫路茂录聦茅聡聧氓聬炉 LLBot 氓聬聨莽聰聼忙聲?),
            const SizedBox(height: 12),
            TextField(
              controller: qqController,
              decoration: const InputDecoration(
                labelText: 'QQ氓聫?,
                hintText: '猫炉路猫戮聯氓聟楼QQ氓聫?,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('氓聫聳忙露聢'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('盲驴聺氓颅聵'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newQQ = qqController.text.trim();
      try {
        await autoLoginFile.writeAsString(newQQ);
        Get.snackbar(
          '盲驴聺氓颅聵忙聢聬氓聤聼',
          '猫聡陋氓聤篓莽聶禄氓陆聲QQ氓聫路氓路虏猫庐戮莽陆庐盲赂? $newQQ',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        Log.i('猫聡陋氓聤篓莽聶禄氓陆聲QQ氓聫路氓路虏忙聸麓忙聳掳: $newQQ', tag: 'AstrBot');
      } catch (e) {
        Get.snackbar(
          '盲驴聺氓颅聵氓陇卤猫麓楼',
          '氓聠聶氓聟楼茅聟聧莽陆庐忙聳聡盲禄露氓陇卤猫麓楼: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // 忙聵戮莽陇潞猫聡陋氓庐職盲鹿?Git Clone 氓炉鹿猫炉聺忙隆?
  void _showCustomGitCloneDialog() async {
    final scriptPath = '${scripts.ubuntuPath}/root/astrbot-startup.sh';
    final scriptFile = File(scriptPath);

    // 忙拢聙忙聼楼猫聞職忙聹卢忙聳聡盲禄露忙聵炉氓聬娄氓颅聵氓聹?
    if (!await scriptFile.exists()) {
      Get.snackbar(
        '忙聫聬莽陇潞',
        '氓聬炉氓聤篓猫聞職忙聹卢忙聳聡盲禄露盲赂聧氓颅聵氓聹篓茂录聦猫炉路氓聟聢氓聬炉氓聤篓盲赂聙忙卢隆氓潞聰莽聰?,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 猫炉禄氓聫聳氓陆聯氓聣聧莽職聞猫聡陋氓庐職盲鹿聣 Git Clone 氓聭陆盲禄陇
    String currentCommand = '';
    try {
      final content = await scriptFile.readAsString();
      final match = RegExp(r'^CUSTOM_GIT_CLONE="([^"]*)"$', multiLine: true)
          .firstMatch(content);
      if (match != null) {
        currentCommand = match.group(1) ?? '';
      }
    } catch (e) {
      Get.snackbar(
        '茅聰聶猫炉炉',
        '猫炉禄氓聫聳氓聬炉氓聤篓猫聞職忙聹卢氓陇卤猫麓楼: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 忙聵戮莽陇潞莽录聳猫戮聭氓炉鹿猫炉聺忙隆?
    final commandController = TextEditingController(text: currentCommand);

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('猫聡陋氓庐職盲鹿?Git Clone 氓聭陆盲禄陇'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '猫聡陋氓庐職盲鹿聣氓聟聥茅職聠氓聭陆盲禄陇茂录聦盲禄楼盲陆驴莽聰?fork 莽職?AstrBot 盲禄聯氓潞聯茂录聸莽聸庐忙聽聡莽聸庐氓陆聲氓聸潞氓庐職盲赂潞 AstrBot茂录聦盲赂聧氓聫炉猫聡陋氓庐職盲鹿聣茫聙聜\n莽聲聶莽漏潞氓聢聶盲陆驴莽聰篓茅禄聵猫庐陇茅聙禄猫戮聭茂录聢盲禄聨茅聲聹氓聝聫忙潞聬猫聨路氓聫聳氓庐聵忙聳鹿忙聹聙忙聳?tag茂录聣茫聙?,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '莽陇潞盲戮聥茂录職\ngit clone https://github.com/AstrBotDevs/AstrBot.git',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commandController,
                decoration: const InputDecoration(
                  labelText: 'Git Clone 氓聭陆盲禄陇',
                  hintText: '莽聲聶莽漏潞盲陆驴莽聰篓茅禄聵猫庐陇茅聙禄猫戮聭',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('氓聫聳忙露聢'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('盲驴聺氓颅聵'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newCommand = commandController.text.trim();

      try {
        String content = await scriptFile.readAsString();

        // 忙聸驴忙聧垄 CUSTOM_GIT_CLONE 氓聫聵茅聡聫莽職聞氓聙?
        content = content.replaceFirst(
          RegExp(r'^CUSTOM_GIT_CLONE="[^"]*"$', multiLine: true),
          'CUSTOM_GIT_CLONE="$newCommand"',
        );

        await scriptFile.writeAsString(content);
        Log.i('氓路虏忙聸麓忙聳掳猫聡陋氓庐職盲鹿聣 Git Clone 氓聭陆盲禄陇: $newCommand', tag: 'AstrBot');

        Get.snackbar(
          '盲驴聺氓颅聵忙聢聬氓聤聼',
          newCommand.isEmpty ? '氓路虏忙赂聟茅聶陇猫聡陋氓庐職盲鹿聣氓聭陆盲禄陇茂录聦氓掳聠盲陆驴莽聰篓茅禄聵猫庐陇茅聙禄猫戮聭' : '猫聡陋氓庐職盲鹿?Git Clone 氓聭陆盲禄陇氓路虏盲驴聺氓颅?,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar(
          '盲驴聺氓颅聵氓陇卤猫麓楼',
          '氓聠聶氓聟楼氓聬炉氓聤篓猫聞職忙聹卢氓陇卤猫麓楼: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Log.e('盲驴聺氓颅聵猫聡陋氓庐職盲鹿?Git Clone 氓聭陆盲禄陇氓陇卤猫麓楼: $e', tag: 'AstrBot');
      }
    }

    commandController.dispose();
  }

  // 忙聣聯氓录聙忙聳聡盲禄露莽庐隆莽聬聠氓聶篓氓鹿露氓炉录猫聢陋氓聢?AstrBot Ubuntu 忙聳聡盲禄露莽鲁禄莽禄聼盲陆聧莽陆庐
  Future<void> _openFileManager() async {
    try {
      // 盲陆驴莽聰篓 DocumentsProvider 莽職?content URI 忙聣聯氓录聙忙聳聡盲禄露莽庐隆莽聬聠氓聶?
      // authority: com.astrbot.astrbot_android.documents
      // rootId: ubuntu_root
      final contentUri = Uri.parse(
        'content://com.astrbot.astrbot_android.documents/root/ubuntu_root',
      );

      if (await canLaunchUrl(contentUri)) {
        await launchUrl(
          contentUri,
          mode: LaunchMode.externalApplication,
        );

        Get.snackbar(
          '氓路虏忙聣聯氓录聙',
          '氓路虏氓聹篓忙聳聡盲禄露莽庐隆莽聬聠氓聶篓盲赂颅忙聣聯氓录聙 AstrBot Ubuntu 忙聳聡盲禄露莽鲁禄莽禄聼',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        // 氓娄聜忙聻聹忙聴聽忙鲁聲忙聣聯氓录聙茂录聦忙聫聬盲戮聸氓陇聡茅聙聣忙聳鹿忙隆?
        Get.dialog(
          AlertDialog(
            title: const Text('忙聣聯氓录聙忙聳聡盲禄露莽鲁禄莽禄聼'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubuntu 忙聳聡盲禄露莽鲁禄莽禄聼氓路虏忙聦聜猫陆陆猫聡鲁莽鲁禄莽禄聼"忙聳聡盲禄露"氓潞聰莽聰篓莽職聞盲戮搂忙聽聫茂录聦氓聬聧莽搂掳盲赂?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AstrBot Ubuntu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '盲陆聽氓聫炉盲禄楼忙聣聥氓聤篓忙聣聯氓录聙莽鲁禄莽禄聼"忙聳聡盲禄露"氓潞聰莽聰篓茂录聦氓聹篓盲戮搂忙聽聫盲赂颅忙聣戮氓聢?AstrBot Ubuntu"忙聺楼猫庐驴茅聴庐茫聙?,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  '忙聢聳盲陆驴莽聰?MT 忙聳聡盲禄露莽庐隆莽聬聠氓聶篓莽颅聣氓潞聰莽聰篓茂录聦忙路禄氓聤聽盲禄楼盲赂聥猫路炉氓戮聞猫聡鲁盲戮搂忙聽聫:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  scripts.ubuntuPath,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: scripts.ubuntuPath));
                  Get.back();
                  Get.snackbar(
                    '氓路虏氓陇聧氓聢?,
                    '猫路炉氓戮聞氓路虏氓陇聧氓聢露氓聢掳氓聣陋猫麓麓忙聺?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('氓陇聧氓聢露猫路炉氓戮聞'),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('氓聟鲁茅聴颅'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Log.e('忙聣聯氓录聙忙聳聡盲禄露莽庐隆莽聬聠氓聶篓氓陇卤猫麓? $e', tag: 'AstrBot');
      Get.snackbar(
        '忙聣聯氓录聙氓陇卤猫麓楼',
        '忙聴聽忙鲁聲忙聣聯氓录聙忙聳聡盲禄露莽庐隆莽聬聠氓聶? $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '猫庐戮莽陆庐',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('猫陆炉盲禄露莽聣聢忙聹卢'),
          subtitle: Text(
            _appVersion.isEmpty ? '氓聤聽猫陆陆盲赂?..' : '$_appVersion茂录聢莽聜鹿氓聡禄忙拢聙忙聼楼忙聸麓忙聳掳茂录聣',
          ),
          onTap: () => _checkForUpdates(),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('氓聸聻氓聢掳 AstrBot 盲赂禄茅隆碌'),
          subtitle: const Text('茅聡聧莽陆庐氓鹿露氓聢路忙聳?AstrBot 茅隆碌茅聺垄'),
          onTap: () {
            // 茅聡聧莽陆庐 AstrBot WebView URL 氓鹿露氓聢路忙聳?
            widget.astrBotController.loadRequest(
              Uri.parse('Config.astrBotLocalBaseUrl'),
            );

            // 猫路鲁猫陆卢氓聢?AstrBot 忙聽聡莽颅戮茅隆碌茂录聢莽麓垄氓录聲 0茂录?
            widget.onNavigate(0);

            Get.snackbar(
              '氓路虏猫路鲁猫陆?,
              'AstrBot 茅隆碌茅聺垄氓路虏茅聡聧莽陆庐氓鹿露氓聢路忙聳掳',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('忙聸麓忙聳掳忙聢聳茅聡聧猫拢?AstrBot'),
          subtitle: const Text('忙赂聟茅聶陇 AstrBot 莽禄聞盲禄露氓鹿露茅聡聧忙聳掳氓庐聣猫拢聟忙聹聙忙聳掳莽聣聢忙聹?),
          onTap: () async {
            // 茅娄聳氓聟聢猫炉垄茅聴庐忙聵炉氓聬娄茅聹聙猫娄聛氓陇聡盲禄?
            final backupChoice = await Get.dialog<String>(
              AlertDialog(
                title: const Text('茅聡聧忙聳掳氓庐聣猫拢聟 AstrBot'),
                content: const Text('茅聡聧忙聳掳氓庐聣猫拢聟氓掳聠氓聢聽茅聶陇忙聣聙忙聹?AstrBot 忙聲掳忙聧庐茂录聦\n忙聵炉氓聬娄茅聹聙猫娄聛氓聟聢氓陇聡盲禄陆氓陆聯氓聣聧忙聲掳忙聧庐茂录?),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: 'cancel'),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: 'no_backup'),
                    child: const Text(
                      '莽聸麓忙聨楼茅聡聧猫拢聟',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: 'backup'),
                    child: const Text(
                      '氓陇聡盲禄陆氓聬聨茅聡聧猫拢?,
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            );

            if (backupChoice == 'cancel' || backupChoice == null) {
              return;
            }

            // 氓娄聜忙聻聹茅聙聣忙聥漏氓陇聡盲禄陆茂录聦氓聟聢忙聣搂猫隆聦氓陇聡盲禄陆
            if (backupChoice == 'backup') {
              bool backupSuccess =
                  await _performBackup(showLoadingDialog: true);

              if (!backupSuccess) {
                // 氓陇聡盲禄陆氓陇卤猫麓楼茂录聦猫炉垄茅聴庐忙聵炉氓聬娄莽禄搂莽禄?
                final continueAnyway = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('氓陇聡盲禄陆氓陇卤猫麓楼'),
                    content: const Text('忙聲掳忙聧庐氓陇聡盲禄陆氓陇卤猫麓楼茂录聦忙聵炉氓聬娄盲禄聧猫娄聛莽禄搂莽禄颅茅聡聧忙聳掳氓庐聣猫拢聟茂录聼'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('氓聫聳忙露聢'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text(
                          '莽禄搂莽禄颅茅聡聧猫拢聟',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (continueAnyway != true) {
                  return;
                }
              }
            }

            // 忙聹聙莽禄聢莽隆庐猫庐陇茅聡聧忙聳掳氓庐聣猫拢?
            final finalConfirm = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('莽隆庐猫庐陇茅聡聧忙聳掳氓庐聣猫拢聟'),
                content: const Text('莽隆庐氓庐職猫娄聛氓聢聽茅聶陇忙聣聙忙聹?AstrBot 忙聲掳忙聧庐氓鹿露茅聡聧忙聳掳氓庐聣猫拢聟氓聬聴茂录聼\n忙颅陇忙聯聧盲陆聹盲赂聧氓聫炉忙聛垄氓陇聧茂录聛'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      '莽隆庐氓庐職茅聡聧猫拢聟',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (finalConfirm == true) {
              try {
                // 氓聢聽茅聶陇 AstrBot 莽聸庐氓陆聲茂录聢~/AstrBot茂录?
                final astrBotPath = '${scripts.ubuntuPath}/root/AstrBot';
                final astrBotDir = Directory(astrBotPath);
                if (await astrBotDir.exists()) {
                  await astrBotDir.delete(recursive: true);
                  Log.i('氓路虏氓聢聽茅聶?AstrBot 莽聸庐氓陆聲: $astrBotPath', tag: 'AstrBot');
                }

                if (context.mounted) {
                  Get.snackbar(
                    '茅聡聧猫拢聟忙聢聬氓聤聼',
                    '氓潞聰莽聰篓氓掳聠猫聡陋氓聤篓茅聙聙氓聡潞茂录聦猫炉路茅聡聧忙聳掳氓聬炉氓聤?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );

                  // 2莽搂聮氓聬聨猫聡陋氓聤篓茅聙聙氓聡潞氓潞聰莽聰?
                  Future.delayed(const Duration(seconds: 2), () {
                    exit(0);
                  });
                }
              } catch (e) {
                Log.e('茅聡聧忙聳掳氓庐聣猫拢聟 AstrBot 氓陇卤猫麓楼: $e', tag: 'AstrBot');
                if (context.mounted) {
                  Get.snackbar(
                    '茅聡聧忙聳掳氓庐聣猫拢聟氓陇卤猫麓楼',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('忙聸麓忙聳掳忙聢聳茅聡聧猫拢?LLBot'),
          subtitle: const Text('忙赂聟茅聶陇 LLBot 莽禄聞盲禄露氓鹿露茅聡聧忙聳掳氓庐聣猫拢聟忙聹聙忙聳掳莽聣聢忙聹?),
          onTap: () async {
            // 忙聵戮莽陇潞莽隆庐猫庐陇氓炉鹿猫炉聺忙隆?
            final confirm = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('莽隆庐猫庐陇茅聡聧忙聳掳氓庐聣猫拢聟'),
                content: const Text('忙颅陇忙聯聧盲陆聹氓掳聠氓聢聽茅聶陇 LLBot 盲潞聦猫驴聸氓聢露忙聳聡盲禄露茂录聢盲驴聺莽聲聶茅聟聧莽陆庐忙聳聡盲禄露茂录聣氓鹿露茅聡聧忙聳掳氓庐聣猫拢聟茂录聦莽隆庐氓庐職莽禄搂莽禄颅氓聬聴茂录?),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      '莽隆庐氓庐職',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                // 氓聢聽茅聶陇 launcher.sh 氓聮?llbot 盲潞聦猫驴聸氓聢露茂录聦猫搂娄氓聫聭茅聡聧忙聳掳氓庐聣猫拢聟
                final launcherPath = '${scripts.ubuntuPath}/root/launcher.sh';
                final launcherFile = File(launcherPath);
                if (await launcherFile.exists()) {
                  await launcherFile.delete();
                }
                // 氓聢聽茅聶陇 llbot 盲潞聦猫驴聸氓聢露盲禄楼猫搂娄氓聫聭茅聡聧忙聳掳盲赂聥猫陆陆
                final llbotDir = '${scripts.ubuntuPath}/root/llbot';
                final llbotFile = File('$llbotDir/llbot');
                if (await llbotFile.exists()) {
                  await llbotFile.delete();
                }

                if (context.mounted) {
                  Get.snackbar(
                    '茅聡聧猫拢聟猫搂娄氓聫聭',
                    'LLBot 氓掳聠氓聹篓盲赂聥忙卢隆氓聬炉氓聤篓忙聴露茅聡聧忙聳掳氓庐聣猫拢?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                Log.e('茅聡聧忙聳掳氓庐聣猫拢聟 LLBot 氓陇卤猫麓楼: $e', tag: 'AstrBot');
                if (context.mounted) {
                  Get.snackbar(
                    '茅聡聧忙聳掳氓庐聣猫拢聟氓陇卤猫麓楼',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.build),
          title: const Text('猫娄聠莽聸聳氓庐聣猫拢聟忙聫聮盲禄露盲戮聺猫碌聳'),
          subtitle: const Text('盲赂聥忙卢隆氓聬炉氓聤篓忙聴露茅聡聧忙聳掳忙聣芦忙聫聫氓鹿露氓庐聣猫拢聟忙聣聙忙聹聣忙聫聮盲禄露盲戮聺猫碌?),
          onTap: () async {
            try {
              final scriptPath =
                  '${scripts.ubuntuPath}/root/astrbot-startup.sh';
              final scriptFile = File(scriptPath);

              if (await scriptFile.exists()) {
                String content = await scriptFile.readAsString();

                // 氓掳?REINSTALL_PLUGINS_FLAG=0 盲驴庐忙聰鹿盲赂?REINSTALL_PLUGINS_FLAG=1
                content = content.replaceFirst(
                  RegExp(r'^REINSTALL_PLUGINS_FLAG=0$', multiLine: true),
                  'REINSTALL_PLUGINS_FLAG=1',
                );

                await scriptFile.writeAsString(content);
                Log.i('氓路虏猫庐戮莽陆庐忙聫聮盲禄露盲戮聺猫碌聳茅聡聧猫拢聟忙聽聡猫庐?, tag: 'AstrBot');

                Get.snackbar(
                  '猫庐戮莽陆庐忙聢聬氓聤聼',
                  '盲赂聥忙卢隆氓聬炉氓聤篓忙聴露氓掳聠茅聡聧忙聳掳氓庐聣猫拢聟忙聣聙忙聹聣忙聫聮盲禄露盲戮聺猫碌?,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  '忙聫聬莽陇潞',
                  '氓聬炉氓聤篓猫聞職忙聹卢忙聳聡盲禄露盲赂聧氓颅聵氓聹篓茂录聦猫炉路氓聟聢氓聬炉氓聤篓盲赂聙忙卢隆氓潞聰莽聰?,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
            } catch (e) {
              Log.e('猫庐戮莽陆庐茅聡聧猫拢聟忙聽聡猫庐掳氓陇卤猫麓楼: $e', tag: 'AstrBot');
              Get.snackbar(
                '忙聯聧盲陆聹氓陇卤猫麓楼',
                '猫庐戮莽陆庐茅聡聧猫拢聟忙聽聡猫庐掳氓陇卤猫麓楼: $e',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('氓陇聡盲禄陆 AstrBot 忙聲掳忙聧庐'),
          subtitle: const Text('氓陇聡盲禄陆 AstrBot 茅聟聧莽陆庐氓聮聦忙聲掳忙聧庐氓聢掳忙聣聥忙聹潞氓颅聵氓聜篓'),
          onTap: () async {
            await _performBackup(showLoadingDialog: true);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('忙赂聟茅聶陇 AstrBot 忙聲掳忙聧庐'),
          subtitle: const Text('忙赂聟茅聶陇 AstrBot 茅聟聧莽陆庐氓聮聦忙聲掳忙聧庐茂录聦\n茅聡聧氓聬炉忙聴露猫聡陋氓聤篓盲禄聨氓陇聡盲禄陆忙聛垄氓陇聧忙聢聳茅聡聧忙聳掳氓聢聺氓搂聥氓聦聳'),
          onTap: () async {
            // 忙聵戮莽陇潞莽隆庐猫庐陇氓炉鹿猫炉聺忙隆?
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('莽隆庐猫庐陇忙赂聟茅聶陇忙聲掳忙聧庐'),
                content: const Text(
                  '忙颅陇忙聯聧盲陆聹氓掳聠氓聢聽茅聶陇忙聣聙忙聹?AstrBot 忙聲掳忙聧庐氓聮聦茅聟聧莽陆庐茂录聦\n'
                  '茅聡聧氓聬炉氓聬聨氓掳聠猫聡陋氓聤篓盲禄聨氓陇聡盲禄陆忙聛垄氓陇聧忙聢聳茅聡聧忙聳掳氓聢聺氓搂聥氓聦聳茫聙聜\n\n'
                  '忙聵炉氓聬娄莽禄搂莽禄颅茂录?,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      '莽隆庐氓庐職',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                final dataPath = '${scripts.ubuntuPath}/root/AstrBot/data';
                final dataDir = Directory(dataPath);

                if (await dataDir.exists()) {
                  await dataDir.delete(recursive: true);
                  Log.i('氓路虏忙赂聟茅聶?AstrBot 忙聲掳忙聧庐莽聸庐氓陆聲: $dataPath', tag: 'AstrBot');

                  Get.snackbar(
                    '忙赂聟茅聶陇忙聢聬氓聤聼',
                    'AstrBot 忙聲掳忙聧庐氓路虏忙赂聟茅聶陇茂录聦氓潞聰莽聰篓氓聧鲁氓掳聠茅聙聙氓聡?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );

                  // 莽颅聣氓戮聟忙聫聬莽陇潞忙聵戮莽陇潞氓聬聨茅聙聙氓聡潞氓潞聰莽聰?
                  await Future.delayed(const Duration(seconds: 2));
                  exit(0);
                } else {
                  Get.snackbar(
                    '忙聫聬莽陇潞',
                    '忙聲掳忙聧庐莽聸庐氓陆聲盲赂聧氓颅聵氓聹篓茂录聦忙聴聽茅聹聙忙赂聟茅聶陇',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                Log.e('忙赂聟茅聶陇 AstrBot 忙聲掳忙聧庐氓陇卤猫麓楼: $e', tag: 'AstrBot');
                Get.snackbar(
                  '忙聯聧盲陆聹氓陇卤猫麓楼',
                  '忙赂聟茅聶陇忙聲掳忙聧庐氓陇卤猫麓楼: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('茅聡聧莽陆庐 Python 莽聨炉氓垄聝'),
          subtitle: const Text('氓聢聽茅聶陇猫聶職忙聥聼莽聨炉氓垄聝氓鹿露茅聡聧氓聬炉氓潞聰莽聰篓茂录聦氓聬炉氓聤篓忙聴露氓掳聠猫聡陋氓聤篓茅聡聧氓禄潞'),
          onTap: () async {
            // 忙聵戮莽陇潞莽隆庐猫庐陇氓炉鹿猫炉聺忙隆?
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('莽隆庐猫庐陇茅聡聧莽陆庐'),
                content: const Text(
                  '忙颅陇忙聯聧盲陆聹氓掳聠氓聢聽茅聶陇 Python 猫聶職忙聥聼莽聨炉氓垄聝茂录?venv 莽聸庐氓陆聲茂录聣氓鹿露茅聙聙氓聡潞氓潞聰莽聰篓茫聙聜\n'
                  '盲赂聥忙卢隆氓聬炉氓聤篓忙聴露盲录職猫聡陋氓聤篓茅聡聧氓禄潞莽聨炉氓垄聝氓鹿露氓庐聣猫拢聟忙聣聙忙聹聣忙聫聮盲禄露盲戮聺猫碌聳茫聙聜\n\n'
                  '忙聵炉氓聬娄莽禄搂莽禄颅茂录?,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      '莽隆庐氓庐職',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              try {
                final venvPath = '${scripts.ubuntuPath}/root/AstrBot/.venv';
                final venvDir = Directory(venvPath);

                if (await venvDir.exists()) {
                  await venvDir.delete(recursive: true);
                  Log.i('氓路虏氓聢聽茅聶?Python 猫聶職忙聥聼莽聨炉氓垄聝: $venvPath', tag: 'AstrBot');

                  Get.snackbar(
                    '茅聡聧莽陆庐忙聢聬氓聤聼',
                    'Python 莽聨炉氓垄聝氓路虏氓聢聽茅聶陇茂录聦氓潞聰莽聰篓氓聧鲁氓掳聠茅聙聙氓聡?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );

                  // 莽颅聣氓戮聟忙聫聬莽陇潞忙聵戮莽陇潞氓聬聨茅聙聙氓聡潞氓潞聰莽聰?
                  await Future.delayed(const Duration(seconds: 2));
                  exit(0);
                } else {
                  Get.snackbar(
                    '忙聫聬莽陇潞',
                    '猫聶職忙聥聼莽聨炉氓垄聝莽聸庐氓陆聲盲赂聧氓颅聵氓聹?,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                Log.e('氓聢聽茅聶陇 Python 猫聶職忙聥聼莽聨炉氓垄聝氓陇卤猫麓楼: $e', tag: 'AstrBot');
                Get.snackbar(
                  '忙聯聧盲陆聹氓陇卤猫麓楼',
                  '氓聢聽茅聶陇猫聶職忙聥聼莽聨炉氓垄聝氓陇卤猫麓楼: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 3),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.login),
          title: const Text('氓驴芦茅聙聼莽聶禄氓陆?QQ'),
          subtitle: const Text('茅聟聧莽陆庐猫聡陋氓聤篓莽聶禄氓陆聲莽職聞QQ猫麓娄氓聫路'),
          onTap: () => _showQuickLoginDialog(),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                '猫聡陋氓庐職盲鹿?WebView',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: _showAddWebViewDialog,
                tooltip: '忙路禄氓聤聽猫聡陋氓庐職盲鹿?WebView',
              ),
            ],
          ),
        ),
        Obx(() {
          final customWebViews = homeController.customWebViews;
          if (customWebViews.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '猫庐驴茅聴庐忙聫聮盲禄露莽職?WebUI 茅聺垄忙聺驴\n莽聜鹿氓聡禄氓聫鲁盲赂聤猫搂?+"忙路禄氓聤聽',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: List.generate(customWebViews.length, (index) {
              final webview = customWebViews[index];
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(webview['title'] ?? 'WebUI'),
                subtitle: Text(webview['url'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditWebViewDialog(index, webview),
                      tooltip: '莽录聳猫戮聭',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDeleteWebView(
                        index,
                        webview['title'] ?? 'WebUI',
                      ),
                      tooltip: '氓聢聽茅聶陇',
                    ),
                  ],
                ),
              );
            }),
          );
        }),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '茅芦聵莽潞搂猫庐戮莽陆庐',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.battery_saver),
          title: const Text('莽聰碌忙卤聽盲录聵氓聦聳猫卤聛氓聟聧'),
          subtitle: Text(_isBatteryOptimizationIgnored ? '氓路虏忙聨聢忙聺? : '忙聹陋忙聨聢忙聺聝茂录聢莽聜鹿氓聡禄忙聨聢忙聺聝茂录?),
          trailing: _isBatteryOptimizationIgnored
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.orange),
          onTap: () => _requestBatteryOptimization(),
        ),
        ListTile(
          leading: const Icon(Icons.web),
          title: const Text('LLBot WebUI'),
          subtitle: const Text('忙聵戮莽陇潞忙聢聳茅職聬猫聴?LLBot 莽陆聭茅隆碌忙聨搂氓聢露茅聺垄忙聺驴茂录聢茅禄聵猫庐陇茅職聬猫聴聫茂录聣'),
          trailing: Switch(
            value: homeController.llbotWebUiEnabled.get() ?? false,
            onChanged: (bool value) {
              // 盲陆驴莽聰篓忙聳掳莽職聞忙聳鹿忙鲁聲忙聺楼氓聬聦忙颅楼忙聸麓忙聳掳氓聯聧氓潞聰氓录聫氓聫聵茅聡聫
              homeController.setLLBotWebUiEnabled(value);

              Get.snackbar(
                value ? 'WebUI 氓路虏氓聬炉莽聰? : 'WebUI 氓路虏莽娄聛莽聰?,
                value ? 'LLBot 忙聽聡莽颅戮茅隆碌氓路虏忙聵戮莽陇潞茂录聦氓聫炉盲禄楼莽芦聥氓聧鲁猫庐驴茅聴庐忙聨搂氓聢露茅聺垄忙聺? : 'LLBot 忙聽聡莽颅戮茅隆碌氓路虏茅職聬猫聴聫',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ),
        Obx(() {
          final token = homeController.llbotWebUiToken.value;
          return ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('LLBot WebUI 氓聹掳氓聺聙'),
            subtitle: Text(token.isEmpty ? 'Config.llBotLocalBaseUrl' : 'Config.llBotLocalBaseUrl/webui?token=$token'),
            onTap: token.isEmpty
                ? null
                : () async {
                    final fullUrl = 'Config.llBotLocalBaseUrl/webui?token=$token';
                    await Clipboard.setData(ClipboardData(text: fullUrl));
                    Get.snackbar(
                      '氓路虏氓陇聧氓聢?,
                      '氓庐聦忙聲麓莽聶禄氓陆聲茅聯戮忙聨楼氓路虏氓陇聧氓聢露氓聢掳氓聣陋猫麓麓忙聺?,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
          );
        }),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('猫聡陋氓庐職盲鹿?Git Clone 氓聭陆盲禄陇'),
          subtitle: const Text('猫聡陋氓庐職盲鹿?AstrBot 莽職聞猫聨路氓聫聳忙聳鹿氓录?),
          onTap: () => _showCustomGitCloneDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: const Text('忙聵戮莽陇潞莽禄聢莽芦炉莽聶陆猫聣虏忙聳聡忙聹卢忙聴楼氓驴聴'),
          subtitle: const Text('忙聵炉氓聬娄氓聹篓莽禄聢莽芦炉忙聵戮莽陇?AstrBot 莽聶陆猫聣虏忙聳聡忙聹卢忙聴楼氓驴聴茂录聢茅禄聵猫庐陇茅職聬猫聴聫茂录聣'),
          trailing: Obx(() => Switch(
                value: homeController.showTerminalWhiteTextRx.value,
                onChanged: (bool value) {
                  // 盲陆驴莽聰篓忙聳掳莽職聞忙聳鹿忙鲁聲忙聺楼氓聬聦忙颅楼忙聸麓忙聳掳氓聯聧氓潞聰氓录聫氓聫聵茅聡聫
                  homeController.setShowTerminalWhiteText(value);

                  Get.snackbar(
                    value ? '氓路虏氓聬炉莽聰篓莽聶陆猫聣虏忙聳聡忙聹卢忙聵戮莽陇? : '氓路虏莽娄聛莽聰篓莽聶陆猫聣虏忙聳聡忙聹卢忙聵戮莽陇?,
                    value ? '莽禄聢莽芦炉氓掳聠忙聵戮莽陇潞忙聣聙忙聹聣忙聴楼氓驴聴猫戮聯氓聡? : '莽禄聢莽芦炉氓掳聠盲禄聟忙聵戮莽陇潞氓陆漏猫聣虏忙聴楼氓驴聴猫戮聯氓聡潞',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
              )),
        ),
                ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('性能优化设置'),
          subtitle: const Text('绑定处理器大核 / 性能模式（默认关闭）'),
          onTap: () => Get.to(() => const PerformanceSettingsPage()),
        ),
        ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('性能优化设置'),
          subtitle: const Text('绑定处理器大核 / 性能模式（默认关闭）'),
          onTap: () => Get.to(() => const PerformanceSettingsPage()),
        ),
ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('忙聳聡盲禄露莽鲁禄莽禄聼'),
          subtitle: const Text(
            '氓聠聟莽陆庐 Ubuntu 忙聳聡盲禄露莽鲁禄莽禄聼氓路虏忙聦聜猫陆陆猫聡鲁 \'忙聳聡盲禄露\'\n氓聫炉忙路禄氓聤聽猫聡鲁 MT 忙聳聡盲禄露莽庐隆莽聬聠氓聶篓盲戮搂忙聽聫盲禄楼氓驴芦忙聧路猫庐驴茅聴庐',
          ),
          onTap: () => _openFileManager(),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('忙赂聟莽漏潞 WebView 莽录聯氓颅聵'),
          subtitle: const Text('忙赂聟莽聬聠忙聣聙忙聹?WebView 莽录聯氓颅聵氓聮聦氓炉聠莽聽?),
          onTap: () async {
            try {
              await widget.astrBotController.clearCache();
              await widget.llbotController.clearCache();
              await PasswordManager.clearAllPasswords();
              if (context.mounted) {
                Get.snackbar(
                  '忙聢聬氓聤聼',
                  'WebView 莽录聯氓颅聵氓聮聦氓炉聠莽聽聛氓路虏忙赂聟莽聬聠',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            } catch (e) {
              if (context.mounted) {
                Get.snackbar(
                  '忙赂聟莽聬聠氓陇卤猫麓楼',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('茅職聬莽搂聛忙聰驴莽颅聳'),
          subtitle: const Text('忙聼楼莽聹聥氓潞聰莽聰篓茅職聬莽搂聛忙聰驴莽颅聳'),
          onTap: () async {
            try {
              final privacyContent =
                  await rootBundle.loadString('assets/privacy_policy.md');
              if (context.mounted) {
                Get.dialog(
                  Dialog(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Text(
                                '茅職聬莽搂聛忙聰驴莽颅聳',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Get.back(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: MarkdownBody(
                              data: privacyContent,
                              styleSheet: MarkdownStyleSheet(
                                h1: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                p: const TextStyle(fontSize: 14),
                                listBullet: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Get.snackbar(
                  '氓聤聽猫陆陆氓陇卤猫麓楼',
                  '忙聴聽忙鲁聲氓聤聽猫陆陆茅職聬莽搂聛忙聰驴莽颅聳: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text(
            '茅聙聙氓聡潞氓潞聰莽聰?,
            style: TextStyle(color: Colors.red),
          ),
          subtitle: const Text('茅聙聙氓聡?AstrBot 氓潞聰莽聰篓'),
          onTap: () async {
            // 忙聵戮莽陇潞莽隆庐猫庐陇氓炉鹿猫炉聺忙隆?
            final confirm = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('莽隆庐猫庐陇茅聙聙氓聡?),
                content: const Text('莽隆庐氓庐職猫娄聛茅聙聙氓聡潞氓潞聰莽聰篓氓聬聴茂录?),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('氓聫聳忙露聢'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      '茅聙聙氓聡?,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              Get.snackbar(
                '茅聙聙氓聡潞氓潞聰莽聰?,
                '氓潞聰莽聰篓氓聧鲁氓掳聠茅聙聙氓聡?,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );

              // 2莽搂聮氓聬聨猫聡陋氓聤篓茅聙聙氓聡潞氓潞聰莽聰?
              Future.delayed(const Duration(seconds: 2), () {
                exit(0);
              });
            }
          },
        ),
      ],
    );
  }
}
