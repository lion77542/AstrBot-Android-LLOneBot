import 'dart:ffi';
import 'dart:io';

typedef CSchedSetAffinityC = Int32 Function(Pointer<Void> pid, Uint32 cpusetSize, Pointer<Void> mask);
typedef CSchedSetAffinityDart = int Function(Pointer<Void> pid, int cpusetSize, Pointer<Void> mask);

class BigCoreAffinity {
  static bool apply(int cpuId) {
    try {
      if (Platform.isAndroid) {
        final libc = DynamicLibrary.open('libc.so');
        final schedSetAffinity = libc.lookupFunction<CSchedSetAffinityC, CSchedSetAffinityDart>('sched_setaffinity');

        // CPU_SETSIZE 通常为 1024，因此 cpuset_size 至少为 128 字节
        const int cpuSetSize = 128;
        final mask = calloc<Uint8>(cpuSetSize);
        try {
          // 只设置目标 CPU
          final byteIndex = cpuId ~/ 8;
          final bitIndex = cpuId % 8;
          mask.elementAt(byteIndex).value |= (1 << bitIndex);

          // pid = 0 表示当前线程
          final result = schedSetAffinity(Pointer.fromAddress(0), cpuSetSize, mask.cast<Void>());
          return result == 0;
        } finally {
          calloc.free(mask);
        }
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}
