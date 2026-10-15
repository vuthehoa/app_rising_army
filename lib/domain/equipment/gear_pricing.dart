import 'dart:math' as math;

/// Giá trang bị: NGUỒN DUY NHẤT cho giá mua (Lò rèn), giá bán lại, giá trị trang bị khi định giá lính
/// và chiến lợi phẩm. `ItemDef.price` luôn là kết quả của [GearPricing.priceOf].
///
/// Mỗi phẩm cấp có một MỐC GIÁ ([anchor]). Giá từng món = mốc × "độ mạnh tương đối" của món đó trong phẩm cấp.
/// Độ mạnh tương đối lấy từ giá gốc mà người thiết kế đã gán cho từng món (đã phản ánh chỉ số, hiệu ứng cố định,
/// hiệu ứng có điều kiện, độ hiếm của thiết kế) chia cho giá gốc trung bình của phẩm cấp ([referenceMean]),
/// rồi kẹp trong khoảng cho phép để không có món nào lệch quá xa mốc. Phép biến đổi này đơn điệu nên món mạnh hơn
/// trong cùng phẩm cấp không bao giờ rẻ hơn món yếu hơn.
abstract final class GearPricing {
  /// Mốc giá theo phẩm cấp 1..6: Thường vài vàng; Tốt (xanh lá); Hiếm (xanh lam) ~125; Sử thi (tím) ~190;
  /// Huyền thoại; phẩm cấp 6 chỉ nhận từ nhiệm vụ nên không bán ở Lò rèn (giá chỉ dùng để quy đổi giá trị).
  static const anchor = <int, int>{1: 6, 2: 40, 3: 125, 4: 190, 5: 330, 6: 520};

  /// Trung bình giá gốc (do người thiết kế gán) của từng phẩm cấp, đo trên toàn danh mục trang bị.
  static const referenceMean = <int, int>{
    1: 21,
    2: 74,
    3: 153,
    4: 275,
    5: 585,
    6: 650,
  };

  /// Tỉ lệ giá tối thiểu / tối đa so với mốc.
  static const minRatio = 0.75;
  static const maxRatio = 1.3;

  /// Phẩm cấp 1 rộng hơn: món cơ bản rất rẻ (2–3 vàng) tới phụ kiện đầu tiên (~9 vàng).
  static const commonMinRatio = 0.5;
  static const commonMaxRatio = 1.6;

  /// Giá bán ra (vàng) của một thiết kế phẩm cấp [grade] có giá gốc [rawPrice].
  static int priceOf(int grade, int rawPrice) {
    final g = grade.clamp(1, 6);
    final ref = referenceMean[g]!;
    final lo = g == 1 ? commonMinRatio : minRatio;
    final hi = g == 1 ? commonMaxRatio : maxRatio;
    final ratio = (rawPrice / ref).clamp(lo, hi);
    return math.max(1, (anchor[g]! * ratio).round());
  }
}
