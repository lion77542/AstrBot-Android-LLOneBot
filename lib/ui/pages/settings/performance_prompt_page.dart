import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/terminal_controller.dart';

class PerformancePromptPage extends StatelessWidget {
  const PerformancePromptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (homeController) {
      bool bigCore = homeController.bigCoreAffinity.get() ?? false;
      bool sustained = homeController.sustainedPerformance.get() ?? false;
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.tune, size: 40, color: Colors.amber),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '性能优化',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '默认关闭，可根据设备选择开启',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchRow(
                    Icons.speed,
                    '绑定处理器大核',
                    '将应用线程调度到 CPU 高性能核心，可能增加发热与功耗',
                    bigCore,
                        (v) => homeController.bigCoreAffinity.set(v),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    Icons.bolt,
                    '性能模式',
                    '请求系统持续高性能模式，可能增加发热与功耗',
                    sustained,
                        (v) => homeController.sustainedPerformance.set(v),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        homeController.applyPerformanceSettings();
                        Get.back(result: {
                          'bigCoreAffinity': homeController.bigCoreAffinity.get() ?? false,
                          'sustainedPerformance': homeController.sustainedPerformance.get() ?? false,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('保存并继续', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
