import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:global_repository/global_repository.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';

/// AstrBot Android LLOneBot 版 — 改版开屏品牌页面
/// 展示改版信息后再进入隐私协议
class LLBotIntroPage extends StatefulWidget {
  final VoidCallback onContinue;
  const LLBotIntroPage({super.key, required this.onContinue});

  @override
  State<LLBotIntroPage> createState() => _LLBotIntroPageState();
}

class _LLBotIntroPageState extends State<LLBotIntroPage> {
  String _appVersion = '';
  bool _showPrivacy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_showPrivacy) {
      return _buildPrivacyPage();
    }
    return _buildIntroPage();
  }

  Widget _buildIntroPage() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                // 图标
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // 标题
                const Text(
                  'AstrBot Android',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'LLOneBot 改版',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 特性列表
                _buildFeatureRow(Icons.swap_horiz, 'NapCat → LLBot（幸运莉莉娅）'),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.download, '多镜像源下载加速'),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.web, 'LLBot WebUI 扫码登录（端口 3080）'),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.timer, '5 分钟防卡死自动跳转'),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.bug_report, '全面修复白屏、卡顿、掉线问题'),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.shield, '开源免费 · 隐私安全'),
                const SizedBox(height: 32),
                // 版本号
                Text(
                  'v$_appVersion',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '基于 AstrBot-Android-App 深度改造',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showPrivacy = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '继续',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPage() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1a1a2e),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _showPrivacy = false),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '隐私政策',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString('assets/privacy_policy.md'),
                builder: (context, snapshot) {
                  return Markdown(
                    controller: ScrollController(),
                    selectable: true,
                    data: snapshot.data ?? '加载协议中...',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14),
                      h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureWithScale(
                    onTap: () => SystemNavigator.pop(),
                    child: Container(
                      height: 48,
                      color: Colors.grey.withOpacity(0.15),
                      child: const Center(
                        child: Text(
                          '不同意并退出',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureWithScale(
                    onTap: widget.onContinue,
                    child: Container(
                      color: Colors.amber,
                      height: 48,
                      child: const Center(
                        child: Text(
                          '同意继续',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
