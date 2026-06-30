import 'dart:io';

class BigCoreAffinity {
  static bool apply(int cpuId) {
    // CPU affinity via FFI is unreliable in proot/CI environments
    // and causes build failures. Feature is kept as a no-op placeholder.
    return false;
  }
}
