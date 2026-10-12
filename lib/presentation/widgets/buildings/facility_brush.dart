import 'dart:math' as math;

import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

/// Bộ cọ và nền đất trung cổ dùng chung cho các công trình trong trại.
///
/// Phong cách:
/// - Đất nâu vàng theo phong cách game chiến thuật 2D.
/// - Mép đất không đều, có viền tối và bóng đổ.
/// - Vệt bánh xe, đá cuội, cỏ nhỏ và các mảng đất khác màu.
/// - Tất cả họa tiết được vẽ bằng Canvas, không cần asset bên ngoài.
class FacilityBrush {
  FacilityBrush(this.canvas, this.size)
    : ink = Paint()
        ..color = Pal.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..isAntiAlias = true,
      dirt = Paint()
        ..color = _earth
        ..isAntiAlias = true;

  final Canvas canvas;
  final Size size;
  final Paint ink;
  final Paint dirt;

  static const Color _earth = Color(0xFFD9BF86);
  static const Color _earthLight = Color(0xFFE8D39F);
  static const Color _earthMid = Color(0xFFC9A66B);
  static const Color _earthShadow = Color(0x553C2B1B);
  static const Color _stone = Color(0xFF93866D);
  static const Color _stoneLight = Color(0xFFB9AA8A);
  static const Color _grass = Color(0xFF687B43);
  static const Color _grassLight = Color(0xFF89975A);

  /// Vẽ nền đất trung cổ phía sau công trình.
  ///
  /// Giữ nguyên API để những công trình đang dùng `ground()` không cần sửa.
  void ground() {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Bóng đổ dưới nền đất.
    final shadowPath = _groundPath(
      Rect.fromLTWH(w * 0.045, h * 0.32, w * 0.91, h * 0.61),
    );

    canvas.drawPath(
      shadowPath.shift(Offset(0, h * 0.025)),
      Paint()
        ..color = _earthShadow
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Viền đất tối, tạo cảm giác nền đất có độ dày.
    final groundRect = Rect.fromLTWH(w * 0.035, h * 0.28, w * 0.93, h * 0.65);

    final outlinePath = _groundPath(groundRect);

    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = const Color(0xFF6F5337)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Lớp đất chính.
    final innerRect = Rect.fromLTWH(w * 0.045, h * 0.285, w * 0.91, h * 0.62);

    canvas.drawPath(
      _groundPath(innerRect),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE4CE99), Color(0xFFD9BF86), Color(0xFFC7A66F)],
        ).createShader(innerRect)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Các chi tiết nằm trong nền đất.
    canvas.save();
    canvas.clipPath(_groundPath(innerRect));

    _drawEarthPatches(w, h);
    _drawWheelTracks(w, h);
    _drawPebbles(w, h);
    _drawGrassTufts(w, h);
    _drawSmallCracks(w, h);

    canvas.restore();

    // Viền trong mảnh, tạo nét minh họa thủ công.
    canvas.drawPath(
      _groundPath(Rect.fromLTWH(w * 0.055, h * 0.30, w * 0.89, h * 0.59)),
      Paint()
        ..color = const Color(0x55745236)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, w * 0.004)
        ..isAntiAlias = true,
    );
  }

  /// Tạo đường bao đất hơi gồ ghề, thay cho hình oval hoàn hảo.
  Path _groundPath(Rect r) {
    final x = r.left;
    final y = r.top;
    final w = r.width;
    final h = r.height;

    return Path()
      ..moveTo(x + w * 0.10, y + h * 0.19)
      ..quadraticBezierTo(
        x + w * 0.02,
        y + h * 0.11,
        x + w * 0.12,
        y + h * 0.07,
      )
      ..quadraticBezierTo(
        x + w * 0.27,
        y - h * 0.015,
        x + w * 0.39,
        y + h * 0.045,
      )
      ..quadraticBezierTo(
        x + w * 0.53,
        y - h * 0.015,
        x + w * 0.64,
        y + h * 0.055,
      )
      ..quadraticBezierTo(
        x + w * 0.81,
        y + h * 0.015,
        x + w * 0.91,
        y + h * 0.12,
      )
      ..quadraticBezierTo(
        x + w * 1.02,
        y + h * 0.18,
        x + w * 0.96,
        y + h * 0.34,
      )
      ..quadraticBezierTo(
        x + w * 1.015,
        y + h * 0.53,
        x + w * 0.93,
        y + h * 0.66,
      )
      ..quadraticBezierTo(
        x + w * 0.88,
        y + h * 0.88,
        x + w * 0.72,
        y + h * 0.90,
      )
      ..quadraticBezierTo(
        x + w * 0.56,
        y + h * 1.015,
        x + w * 0.42,
        y + h * 0.94,
      )
      ..quadraticBezierTo(
        x + w * 0.24,
        y + h * 1.01,
        x + w * 0.13,
        y + h * 0.88,
      )
      ..quadraticBezierTo(
        x - w * 0.015,
        y + h * 0.79,
        x + w * 0.055,
        y + h * 0.61,
      )
      ..quadraticBezierTo(
        x - w * 0.005,
        y + h * 0.42,
        x + w * 0.10,
        y + h * 0.19,
      )
      ..close();
  }

  /// Mảng đất sáng và tối tạo cảm giác bề mặt không bằng phẳng.
  void _drawEarthPatches(double w, double h) {
    final patches = <_EarthPatch>[
      _EarthPatch(0.20, 0.48, 0.15, 0.045, _earthLight),
      _EarthPatch(0.68, 0.40, 0.12, 0.035, _earthLight),
      _EarthPatch(0.42, 0.73, 0.20, 0.045, _earthMid),
      _EarthPatch(0.77, 0.66, 0.10, 0.035, _earthMid),
      _EarthPatch(0.27, 0.79, 0.12, 0.025, _earthLight),
      _EarthPatch(0.52, 0.37, 0.09, 0.025, _earthMid),
    ];

    for (final patch in patches) {
      final rect = Rect.fromCenter(
        center: Offset(w * patch.x, h * patch.y),
        width: w * patch.width,
        height: h * patch.height,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..color = patch.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  /// Vệt bánh xe mờ, gợi liên tưởng đến đường đi trong doanh trại.
  void _drawWheelTracks(double w, double h) {
    final trackPaint = Paint()
      ..color = const Color(0x447D5A37)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, w * 0.012)
      ..isAntiAlias = true;

    final highlightPaint = Paint()
      ..color = const Color(0x55F0D9A5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.6, w * 0.004)
      ..isAntiAlias = true;

    final firstTrack = Path()
      ..moveTo(w * 0.17, h * 0.39)
      ..quadraticBezierTo(w * 0.23, h * 0.50, w * 0.18, h * 0.62);

    final secondTrack = Path()
      ..moveTo(w * 0.22, h * 0.38)
      ..quadraticBezierTo(w * 0.28, h * 0.50, w * 0.23, h * 0.63);

    canvas.drawPath(firstTrack, trackPaint);
    canvas.drawPath(secondTrack, trackPaint);

    canvas.drawPath(firstTrack.shift(Offset(w * 0.008, 0)), highlightPaint);
    canvas.drawPath(secondTrack.shift(Offset(w * 0.008, 0)), highlightPaint);
  }

  /// Đá cuội nhỏ rải rác trên nền đất.
  void _drawPebbles(double w, double h) {
    final stones = <_Pebble>[
      _Pebble(0.13, 0.45, 0.018, 0.012),
      _Pebble(0.31, 0.36, 0.014, 0.010),
      _Pebble(0.82, 0.43, 0.020, 0.013),
      _Pebble(0.88, 0.58, 0.015, 0.011),
      _Pebble(0.72, 0.79, 0.019, 0.012),
      _Pebble(0.35, 0.83, 0.016, 0.010),
      _Pebble(0.12, 0.70, 0.018, 0.012),
      _Pebble(0.61, 0.34, 0.012, 0.009),
      _Pebble(0.48, 0.86, 0.012, 0.008),
    ];

    for (var i = 0; i < stones.length; i++) {
      final stone = stones[i];
      final rect = Rect.fromCenter(
        center: Offset(w * stone.x, h * stone.y),
        width: w * stone.width,
        height: h * stone.height,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..color = i.isEven ? _stone : _stoneLight
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      canvas.drawArc(
        rect,
        math.pi * 1.05,
        math.pi * 0.8,
        false,
        Paint()
          ..color = const Color(0x55715F46)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5, w * 0.0025)
          ..isAntiAlias = true,
      );
    }
  }

  /// Cỏ mọc thưa ở rìa sân, tránh làm rối phần đặt công trình.
  void _drawGrassTufts(double w, double h) {
    final tufts = <_GrassTuft>[
      _GrassTuft(0.12, 0.36, -1),
      _GrassTuft(0.28, 0.33, 1),
      _GrassTuft(0.76, 0.34, -1),
      _GrassTuft(0.88, 0.48, 1),
      _GrassTuft(0.90, 0.70, -1),
      _GrassTuft(0.76, 0.84, 1),
      _GrassTuft(0.22, 0.85, -1),
      _GrassTuft(0.10, 0.62, 1),
    ];

    final grassPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.8, w * 0.005)
      ..isAntiAlias = true;

    for (var i = 0; i < tufts.length; i++) {
      final tuft = tufts[i];
      final x = w * tuft.x;
      final y = h * tuft.y;
      final direction = tuft.direction.toDouble();

      grassPaint.color = i.isEven ? _grass : _grassLight;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + w * 0.008 * direction, y - h * 0.025),
        grassPaint,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x + w * 0.019 * direction, y - h * 0.018),
        grassPaint,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - w * 0.006 * direction, y - h * 0.016),
        grassPaint,
      );
    }
  }

  /// Những đường nứt nhỏ, giúp đất trông cũ và có kết cấu.
  void _drawSmallCracks(double w, double h) {
    final crackPaint = Paint()
      ..color = const Color(0x667E603F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.6, w * 0.003)
      ..isAntiAlias = true;

    final cracks = <Path>[
      Path()
        ..moveTo(w * 0.39, h * 0.45)
        ..lineTo(w * 0.405, h * 0.465)
        ..lineTo(w * 0.398, h * 0.48),
      Path()
        ..moveTo(w * 0.67, h * 0.70)
        ..lineTo(w * 0.655, h * 0.715)
        ..lineTo(w * 0.663, h * 0.73),
      Path()
        ..moveTo(w * 0.46, h * 0.82)
        ..lineTo(w * 0.475, h * 0.81),
    ];

    for (final crack in cracks) {
      canvas.drawPath(crack, crackPaint);
    }
  }
}

class _EarthPatch {
  const _EarthPatch(this.x, this.y, this.width, this.height, this.color);

  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
}

class _Pebble {
  const _Pebble(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}

class _GrassTuft {
  const _GrassTuft(this.x, this.y, this.direction);

  final double x;
  final double y;
  final int direction;
}

/// Bọc painter trong CustomPaint.
///
/// Có [size] thì ép khung vuông; không có thì lấp đầy vùng cha
/// theo hành vi vốn có của CustomPaint.
Widget facilityCanvas(double? size, CustomPainter painter) {
  final paint = CustomPaint(painter: painter);
  return size == null ? paint : SizedBox.square(dimension: size, child: paint);
}
