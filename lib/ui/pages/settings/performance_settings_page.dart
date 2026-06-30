import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import '../../controllers/terminal_controller.dart';

class PerformanceSettingsPage extends StatefulWidget {
  const PerformanceSettingsPage({super.key});

  @override
  State<PerformanceSettingsPage> createState() => _PerformanceSettingsPageState();
}

class _PerformanceSettingsPageState extends State<PerformanceSettingsPage> {
  bool _bigCoreAffinity = false;
  bool _sustainedPerformance = false;

  @override
  void initState() {
    super.initState();
    final homeController = Get.find<HomeController>();
    _bigCoreAffinity = homeController.bigCoreAffinity.get() ?? false;
    _sustainedPerformance = homeController.sustainedPerformance.get() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1a1a2e),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '性能优化设置',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '默认关闭，可根据设备选择开启',
                      style: TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchRow(
                      Icons.speed,
                      '绑定处理器大核',
                      '将应用线程调度到 CPU 高性能核心，可能增加发热与功耗',
                      _bigCoreAffinity,
                      (v) => setState(() => _bigCoreAffinity = v),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchRow(
                      Icons.bolt,
                      '性能模式',
                      '请求系统持续高性能模式，可能增加发热与功耗',
                      _sustainedPerformance,
                      (v) => setState(() => _sustainedPerformance = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final homeController = Get.find<HomeController>();
                          homeController.bigCoreAffinity.set(_bigCoreAffinity);
                          homeController.sustainedPerformance.set(_sustainedPerformance);
                          homeController.applyPerformanceSettings();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(IconData icon, String title, String summary, bool value, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
              const SizedBox(height: 2),
              Text(summary, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.amber,
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: Colors.white24,
        ),
      ],
    );
  }
}
