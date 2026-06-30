import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/terminal_controller.dart';

class AgentManagementPage extends StatefulWidget {
  const AgentManagementPage({super.key});

  @override
  State<AgentManagementPage> createState() => _AgentManagementPageState();
}

class _AgentManagementPageState extends State<AgentManagementPage> {
  final HomeController homeController = Get.find<HomeController>();
  List<Map<String, String>> _agents = [];
  bool _loading = true;
  StreamSubscription<dynamic>? _outputSubscription;

  @override
  void initState() {
    super.initState();
    _refreshAgentList();
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    super.dispose();
  }

  Future<List<String>> _sendCommand(String cmd) async {
    if (homeController.pseudoTerminal == null) {
      return ['错误: PTY 未初始化'];
    }

    final completer = Completer<List<String>>();
    final responses = <String>[];
    final marker = '__HERMES_AGENT_DONE_${DateTime.now().millisecondsSinceEpoch}__';

    _outputSubscription?.cancel();

    // Send command with marker
    final fullCmd = '$cmd && echo "$marker"';
    homeController.pseudoTerminal!.write(utf8.encode('$fullCmd\n'));
    _outputSubscription = homeController.pseudoTerminal!.output
        .cast<List<int>>()
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen((event) {
      // Skip if it contains the marker
      if (event.contains(marker)) {
        if (!completer.isCompleted) {
          completer.complete(responses);
        }
        return;
      }
      responses.add(event);
    });

    // Timeout after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete(responses);
      }
    });

    return completer.future;
  }

  Future<void> _refreshAgentList() async {
    setState(() => _loading = true);
    final output = await _sendCommand('agent_status');
    final agents = <Map<String, String>>[];
    for (final line in output) {
      final match = RegExp(r'\[(.+?)\] (.+?) \(PID: (\d+)\)').firstMatch(line);
      if (match != null) {
        agents.add({
          'status': match.group(1)!,
          'name': match.group(2)!,
          'pid': match.group(3)!,
        });
      }
    }
    if (mounted) {
      setState(() {
        _agents = agents;
        _loading = false;
      });
    }
  }

  Future<void> _startAgent(String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('启动 Agent: $name'),
        content: Text('确定要在后台启动 $name 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('启动', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final output = await _sendCommand('start_agent $name "echo Agent $name started; sleep infinity"');
    final resultText = output.join('\n');
    Get.snackbar(
      resultText.contains('已启动') ? '启动成功' : '启动中',
      resultText,
      snackPosition: SnackPosition.BOTTOM,
    );
    await _refreshAgentList();
  }

  Future<void> _stopAgent(String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('停止 Agent: $name'),
        content: Text('确定要停止 $name 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('停止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final output = await _sendCommand('stop_agent $name');
    final resultText = output.join('\n');
    Get.snackbar(
      resultText.contains('已停止') ? '已停止' : '操作完成',
      resultText,
      snackPosition: SnackPosition.BOTTOM,
    );
    await _refreshAgentList();
  }

  Future<void> _viewLogs(String name) async {
    final output = await _sendCommand('agent_logs $name 50');
    final logText = output.join('\n');
    if (!mounted) return;
    Get.dialog(
      Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('$name 日志', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    logText.isEmpty ? '暂无日志' : logText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAgentDialog() async {
    final nameController = TextEditingController();
    final cmdController = TextEditingController();
    final result = await Get.dialog<Map<String, String>>(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('添加 Agent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Agent 名称', hintText: '例如: openclaw'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cmdController,
                decoration: const InputDecoration(labelText: '启动命令', hintText: '例如: cd /root/openclaw && python main.py'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty && cmdController.text.isNotEmpty) {
                          Get.back(result: {
                            'name': nameController.text,
                            'cmd': cmdController.text,
                          });
                        }
                      },
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final cmd = 'agent_autostart ${result['name']} "${result['cmd']}"';
      await _sendCommand(cmd);
      final startCmd = 'start_agent ${result['name']} "${result['cmd']}"';
      final output = await _sendCommand(startCmd);
      final resultText = output.join('\n');
      Get.snackbar(
        resultText.contains('已启动') ? '添加成功' : '已配置',
        'Agent ${result['name']} 已添加',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _refreshAgentList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent 管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAgentList,
            tooltip: '刷新状态',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAgentDialog,
            tooltip: '添加 Agent',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无运行中的 Agent', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddAgentDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('添加第一个 Agent'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final agent = _agents[index];
                    final isRunning = agent['status'] == '运行中';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRunning ? Colors.green : Colors.red,
                          child: Icon(isRunning ? Icons.play_arrow : Icons.stop, color: Colors.white),
                        ),
                        title: Text(agent['name'] ?? 'Unknown'),
                        subtitle: Text('PID: ${agent['pid'] ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRunning)
                              IconButton(
                                icon: const Icon(Icons.stop, color: Colors.red),
                                onPressed: () => _stopAgent(agent['name']!),
                                tooltip: '停止',
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () => _startAgent(agent['name']!),
                                tooltip: '启动',
                              ),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewLogs(agent['name']!),
                              tooltip: '日志',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
