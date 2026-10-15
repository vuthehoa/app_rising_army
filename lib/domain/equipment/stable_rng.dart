/// Bộ sinh số giả ngẫu nhiên xác định (xorshift32). Không dùng `dart:math Random` vì thuật toán của nó
/// không được cam kết giữ nguyên giữa các phiên bản SDK: biến thể trang bị đã lưu không được đổi.
class StableRng {
  StableRng(int seed) : _s = _mix(seed);

  int _s;

  static int _mix(int seed) {
    var x = (seed ^ 0x9E3779B9) & 0xFFFFFFFF;
    x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF;
    x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF;
    x = (x ^ (x >> 16)) & 0xFFFFFFFF;
    return x == 0 ? 0x1234567 : x;
  }

  int _next() {
    var x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _s = x & 0xFFFFFFFF;
  }

  /// Số nguyên trong [0, n).
  int nextInt(int n) => _next() % n;

  /// Số thực trong [0, 1).
  double nextDouble() => _next() / 4294967296.0;
}
