import 'dart:math' as math;

import 'package:app_rising_army/core/theme.dart';
import 'package:flutter/material.dart';

import 'facility_brush.dart';

/// Lều quân y thời trung cổ.
///
/// Minh họa gồm:
/// - Lều vải nhiều lớp, cửa mở rộng.
/// - Ba giường rơm có chăn và gối.
/// - Hai đuốc đặt hai bên cửa.
/// - Dấu thập đỏ trên mái lều.
/// - Dây neo, cọc gỗ và bóng đổ.
///
/// Giữ nguyên API InfirmaryArt để không ảnh hưởng nơi đang sử dụng.
class InfirmaryArt extends StatelessWidget {
  const InfirmaryArt({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return facilityCanvas(size, const InfirmaryPainter());
  }
}

class InfirmaryPainter extends CustomPainter {
  const InfirmaryPainter();

  static const Color _canvasColor = Color(0xFFE9D6AC);
  static const Color _canvasLight = Color(0xFFF5E9CD);
  static const Color _canvasDark = Color(0xFFBBA77D);
  static const Color _canvasShadow = Color(0xFF8D7958);

  static const Color _wood = Color(0xFF68452D);
  static const Color _woodLight = Color(0xFF9A7047);
  static const Color _woodDark = Color(0xFF412C22);

  static const Color _straw = Color(0xFFC9A45F);
  static const Color _strawLight = Color(0xFFE6CA86);
  static const Color _strawDark = Color(0xFF987342);

  static const Color _blanket = Color(0xFF8E3D35);
  static const Color _blanketLight = Color(0xFFB95B48);
  static const Color _linen = Color(0xFFE9DEC5);

  static const Color _torchWood = Color(0xFF60402B);
  static const Color _flameOuter = Color(0xFFE56D24);
  static const Color _flameInner = Color(0xFFFFD66B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = math.min(w, h);

    final brush = FacilityBrush(canvas, size);
    final ink = brush.ink;

    Paint fill(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    Path polygon(List<Offset> points) {
      return Path()
        ..moveTo(points.first.dx, points.first.dy)
        ..addPolygon(points.skip(1).toList(), true);
    }

    void line(Offset a, Offset b, Color color, double width) {
      canvas.drawLine(a, b, stroke(color, width));
    }

    void oval(Rect rect, Color color, {Color? border, double borderWidth = 1}) {
      canvas.drawOval(rect, fill(color));
      if (border != null) {
        canvas.drawOval(rect, stroke(border, borderWidth));
      }
    }

    // ---------------------------------------------------------------
    // 1. Bóng đổ và mặt đất.
    // ---------------------------------------------------------------
    oval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.88),
        width: w * 0.8,
        height: h * 0.12,
      ),
      const Color(0x332B2118),
    );

    final ground = Path()
      ..moveTo(w * 0.08, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.94, w * 0.92, h * 0.88);

    canvas.drawPath(ground, stroke(const Color(0xFF90764D), u * 0.012));

    // ---------------------------------------------------------------
    // 2. Cọc và dây neo phía sau lều.
    // ---------------------------------------------------------------
    line(
      Offset(w * 0.23, h * 0.69),
      Offset(w * 0.09, h * 0.84),
      _woodDark,
      u * 0.012,
    );
    line(
      Offset(w * 0.77, h * 0.69),
      Offset(w * 0.91, h * 0.84),
      _woodDark,
      u * 0.012,
    );

    oval(
      Rect.fromCenter(
        center: Offset(w * 0.09, h * 0.84),
        width: u * 0.035,
        height: u * 0.025,
      ),
      _wood,
    );
    oval(
      Rect.fromCenter(
        center: Offset(w * 0.91, h * 0.84),
        width: u * 0.035,
        height: u * 0.025,
      ),
      _wood,
    );

    // ---------------------------------------------------------------
    // 3. Thân lều phía sau.
    // ---------------------------------------------------------------
    final tentBody = polygon([
      Offset(w * 0.12, h * 0.83),
      Offset(w * 0.5, h * 0.13),
      Offset(w * 0.88, h * 0.83),
    ]);

    canvas.drawPath(tentBody, fill(_canvasColor));
    canvas.drawPath(tentBody, stroke(_woodDark, u * 0.016));

    // Mảng sáng bên trái mái.
    canvas.drawPath(
      polygon([
        Offset(w * 0.12, h * 0.83),
        Offset(w * 0.5, h * 0.13),
        Offset(w * 0.43, h * 0.83),
      ]),
      fill(_canvasLight),
    );

    // Mảng tối bên phải mái.
    canvas.drawPath(
      polygon([
        Offset(w * 0.5, h * 0.13),
        Offset(w * 0.88, h * 0.83),
        Offset(w * 0.72, h * 0.83),
      ]),
      fill(_canvasDark),
    );

    // Đường may trên mái.
    line(
      Offset(w * 0.5, h * 0.16),
      Offset(w * 0.5, h * 0.34),
      _canvasShadow,
      u * 0.009,
    );
    line(
      Offset(w * 0.18, h * 0.76),
      Offset(w * 0.43, h * 0.35),
      _canvasShadow,
      u * 0.008,
    );
    line(
      Offset(w * 0.82, h * 0.76),
      Offset(w * 0.57, h * 0.35),
      _canvasShadow,
      u * 0.008,
    );

    // Viền vải ngang gần chân mái.
    final lowerHem = Path()
      ..moveTo(w * 0.14, h * 0.79)
      ..quadraticBezierTo(w * 0.5, h * 0.84, w * 0.86, h * 0.79);

    canvas.drawPath(lowerHem, stroke(_wood, u * 0.014));

    // ---------------------------------------------------------------
    // 4. Dấu thập đỏ trên phần mái cao.
    // ---------------------------------------------------------------
    final crossCenter = Offset(w * 0.5, h * 0.315);
    final crossWidth = w * 0.105;
    final crossHeight = h * 0.145;
    final crossBarHeight = h * 0.04;
    final crossStemWidth = w * 0.035;

    final crossPath = Path()
      ..moveTo(
        crossCenter.dx - crossStemWidth / 2,
        crossCenter.dy - crossHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossStemWidth / 2,
        crossCenter.dy - crossHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossStemWidth / 2,
        crossCenter.dy - crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossWidth / 2,
        crossCenter.dy - crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossWidth / 2,
        crossCenter.dy + crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossStemWidth / 2,
        crossCenter.dy + crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx + crossStemWidth / 2,
        crossCenter.dy + crossHeight / 2,
      )
      ..lineTo(
        crossCenter.dx - crossStemWidth / 2,
        crossCenter.dy + crossHeight / 2,
      )
      ..lineTo(
        crossCenter.dx - crossStemWidth / 2,
        crossCenter.dy + crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx - crossWidth / 2,
        crossCenter.dy + crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx - crossWidth / 2,
        crossCenter.dy - crossBarHeight / 2,
      )
      ..lineTo(
        crossCenter.dx - crossStemWidth / 2,
        crossCenter.dy - crossBarHeight / 2,
      )
      ..close();

    canvas.drawPath(crossPath, fill(Colors.white.withValues(alpha: 0.9)));
    canvas.drawPath(crossPath, stroke(_woodDark, u * 0.006));

    // Thập đỏ nhỏ ở chính giữa huy hiệu.
    final redCross = Path()
      ..moveTo(w * 0.49, h * 0.25)
      ..lineTo(w * 0.51, h * 0.25)
      ..lineTo(w * 0.51, h * 0.295)
      ..lineTo(w * 0.535, h * 0.295)
      ..lineTo(w * 0.535, h * 0.315)
      ..lineTo(w * 0.51, h * 0.315)
      ..lineTo(w * 0.51, h * 0.36)
      ..lineTo(w * 0.49, h * 0.36)
      ..lineTo(w * 0.49, h * 0.315)
      ..lineTo(w * 0.465, h * 0.315)
      ..lineTo(w * 0.465, h * 0.295)
      ..lineTo(w * 0.49, h * 0.295)
      ..close();

    canvas.drawPath(redCross, fill(Pal.blood));

    // ---------------------------------------------------------------
    // 5. Bóng tối bên trong cửa lều.
    // Vẽ nền cửa trước giường để không che mất các chi tiết nội thất.
    // ---------------------------------------------------------------
    final opening = Path()
      ..moveTo(w * 0.285, h * 0.81)
      ..lineTo(w * 0.5, h * 0.425)
      ..lineTo(w * 0.715, h * 0.81)
      ..close();

    canvas.drawPath(opening, fill(const Color(0xFF382D25)));
    canvas.drawPath(opening, stroke(_woodDark, u * 0.015));

    // Ánh sáng ấm bên trong lều.
    final innerGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF9A7045).withValues(alpha: 0.42),
              const Color(0xFF49372A).withValues(alpha: 0.05),
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.67),
              width: w * 0.38,
              height: h * 0.43,
            ),
          );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.67),
        width: w * 0.38,
        height: h * 0.43,
      ),
      innerGlow,
    );

    // ---------------------------------------------------------------
    // 6. Ba giường rơm bên trong.
    // ---------------------------------------------------------------
    void drawBed({
      required double cx,
      required double cy,
      required double bedW,
      required double bedH,
      required Color blanketColor,
      required bool front,
    }) {
      final bedRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: bedW,
        height: bedH,
      );

      // Bóng dưới giường.
      oval(
        Rect.fromCenter(
          center: Offset(cx, cy + bedH * 0.5),
          width: bedW * 1.08,
          height: bedH * 0.45,
        ),
        const Color(0x550E0B08),
      );

      // Chân giường.
      final legW = bedW * 0.09;
      final legH = bedH * 0.48;

      for (final x in [cx - bedW * 0.38, cx + bedW * 0.38]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - legW / 2, cy + bedH * 0.04, legW, legH),
            Radius.circular(u * 0.006),
          ),
          fill(_woodDark),
        );
      }

      // Khung giường.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bedW / 2, cy - bedH * 0.1, bedW, bedH * 0.56),
          Radius.circular(u * 0.012),
        ),
        fill(_wood),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - bedW / 2, cy - bedH * 0.1, bedW, bedH * 0.56),
          Radius.circular(u * 0.012),
        ),
        stroke(_woodDark, u * 0.007),
      );

      // Lớp rơm.
      final strawRect = Rect.fromLTWH(
        cx - bedW * 0.47,
        cy - bedH * 0.28,
        bedW * 0.94,
        bedH * 0.55,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(strawRect, Radius.circular(u * 0.015)),
        fill(_straw),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(strawRect, Radius.circular(u * 0.015)),
        stroke(_strawDark, u * 0.006),
      );

      // Các sợi rơm.
      for (int i = 0; i < 7; i++) {
        final x = strawRect.left + strawRect.width * (i + 0.5) / 7;
        line(
          Offset(x, strawRect.top + bedH * 0.035),
          Offset(x - bedW * 0.07, strawRect.bottom - bedH * 0.025),
          _strawLight.withValues(alpha: 0.8),
          u * 0.004,
        );
      }

      // Chăn.
      final blanketRect = Rect.fromLTWH(
        cx - bedW * 0.4,
        cy - bedH * 0.12,
        bedW * 0.8,
        bedH * 0.34,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(blanketRect, Radius.circular(u * 0.01)),
        fill(blanketColor),
      );

      // Nếp gấp chăn.
      line(
        Offset(blanketRect.left + bedW * 0.13, blanketRect.top + bedH * 0.06),
        Offset(blanketRect.left + bedW * 0.2, blanketRect.bottom - bedH * 0.04),
        blanketColor.withValues(alpha: 0.8),
        u * 0.006,
      );

      line(
        Offset(blanketRect.center.dx, blanketRect.top + bedH * 0.04),
        Offset(
          blanketRect.center.dx + bedW * 0.04,
          blanketRect.bottom - bedH * 0.035,
        ),
        const Color(0xFFFFD8A0).withValues(alpha: 0.45),
        u * 0.004,
      );

      // Gối.
      final pillowRect = Rect.fromLTWH(
        cx - bedW * 0.27,
        cy - bedH * 0.245,
        bedW * 0.54,
        bedH * 0.12,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(pillowRect, Radius.circular(u * 0.008)),
        fill(_linen),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(pillowRect, Radius.circular(u * 0.008)),
        stroke(_canvasShadow, u * 0.004),
      );

      // Đường viền gỗ đầu giường.
      line(
        Offset(cx - bedW * 0.49, cy - bedH * 0.28),
        Offset(cx + bedW * 0.49, cy - bedH * 0.28),
        _woodLight,
        u * 0.009,
      );

      if (front) {
        // Một ít rơm rơi gần giường phía trước.
        for (int i = 0; i < 4; i++) {
          final sx = cx - bedW * 0.4 + bedW * i * 0.22;
          line(
            Offset(sx, cy + bedH * 0.49),
            Offset(sx + bedW * 0.08, cy + bedH * 0.44),
            _strawLight,
            u * 0.005,
          );
        }
      }

      // Giữ biến được dùng rõ ràng khi thay đổi kích thước về sau.
      assert(bedRect.width > 0);
    }

    // Giường sau nhỏ hơn để tạo chiều sâu phối cảnh.
    drawBed(
      cx: w * 0.5,
      cy: h * 0.575,
      bedW: w * 0.22,
      bedH: h * 0.11,
      blanketColor: const Color(0xFF6F4635),
      front: false,
    );

    // Hai giường hai bên.
    drawBed(
      cx: w * 0.405,
      cy: h * 0.665,
      bedW: w * 0.245,
      bedH: h * 0.12,
      blanketColor: _blanket,
      front: false,
    );

    drawBed(
      cx: w * 0.595,
      cy: h * 0.665,
      bedW: w * 0.245,
      bedH: h * 0.12,
      blanketColor: _blanketLight,
      front: true,
    );

    // ---------------------------------------------------------------
    // 7. Khung gỗ và mép cửa mở.
    // ---------------------------------------------------------------
    line(
      Offset(w * 0.285, h * 0.81),
      Offset(w * 0.5, h * 0.425),
      _woodDark,
      u * 0.024,
    );
    line(
      Offset(w * 0.715, h * 0.81),
      Offset(w * 0.5, h * 0.425),
      _woodDark,
      u * 0.024,
    );

    line(
      Offset(w * 0.305, h * 0.79),
      Offset(w * 0.5, h * 0.46),
      _woodLight,
      u * 0.008,
    );
    line(
      Offset(w * 0.695, h * 0.79),
      Offset(w * 0.5, h * 0.46),
      _woodLight,
      u * 0.008,
    );

    // ---------------------------------------------------------------
    // 8. Hai vạt cửa lều cuộn sang hai bên.
    // ---------------------------------------------------------------
    final leftFlap = Path()
      ..moveTo(w * 0.12, h * 0.83)
      ..lineTo(w * 0.285, h * 0.81)
      ..lineTo(w * 0.5, h * 0.425)
      ..lineTo(w * 0.38, h * 0.69)
      ..lineTo(w * 0.31, h * 0.8)
      ..close();

    canvas.drawPath(leftFlap, fill(_canvasLight));
    canvas.drawPath(leftFlap, stroke(_woodDark, u * 0.012));

    final rightFlap = Path()
      ..moveTo(w * 0.88, h * 0.83)
      ..lineTo(w * 0.715, h * 0.81)
      ..lineTo(w * 0.5, h * 0.425)
      ..lineTo(w * 0.62, h * 0.69)
      ..lineTo(w * 0.69, h * 0.8)
      ..close();

    canvas.drawPath(rightFlap, fill(_canvasDark));
    canvas.drawPath(rightFlap, stroke(_woodDark, u * 0.012));

    // Nếp vải.
    line(
      Offset(w * 0.17, h * 0.81),
      Offset(w * 0.37, h * 0.73),
      _canvasShadow,
      u * 0.006,
    );
    line(
      Offset(w * 0.83, h * 0.81),
      Offset(w * 0.63, h * 0.73),
      _canvasShadow,
      u * 0.006,
    );

    // ---------------------------------------------------------------
    // 9. Hai cột gỗ trước cửa.
    // ---------------------------------------------------------------
    for (final x in [w * 0.285, w * 0.715]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, h * 0.695),
            width: u * 0.025,
            height: h * 0.28,
          ),
          Radius.circular(u * 0.008),
        ),
        fill(_wood),
      );

      line(
        Offset(x - u * 0.004, h * 0.565),
        Offset(x - u * 0.004, h * 0.81),
        _woodLight,
        u * 0.005,
      );

      oval(
        Rect.fromCenter(
          center: Offset(x, h * 0.555),
          width: u * 0.035,
          height: u * 0.022,
        ),
        _woodLight,
      );
    }

    // ---------------------------------------------------------------
    // 10. Hai đuốc ở hai bên cửa.
    // ---------------------------------------------------------------
    void drawTorch(double x, double y, bool rightSide) {
      final torchTop = Offset(x, y);
      final torchBottom = Offset(x, y + h * 0.14);

      // Bóng sáng hắt lên vải.
      final glowRect = Rect.fromCenter(
        center: Offset(x, y - h * 0.015),
        width: u * 0.13,
        height: u * 0.16,
      );

      canvas.drawOval(
        glowRect,
        Paint()
          ..color = const Color(0xFFFFB642).withValues(alpha: 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.025),
      );

      // Giá đỡ đuốc.
      line(
        Offset(x, y + h * 0.035),
        Offset(x + (rightSide ? -u * 0.035 : u * 0.035), y + h * 0.075),
        _woodDark,
        u * 0.012,
      );

      // Thân đuốc.
      line(torchTop, torchBottom, _torchWood, u * 0.022);
      line(
        Offset(x - u * 0.004, y + h * 0.02),
        Offset(x - u * 0.004, y + h * 0.105),
        _woodLight,
        u * 0.006,
      );

      // Vòng sắt giữ bó đuốc.
      line(
        Offset(x - u * 0.014, y + h * 0.045),
        Offset(x + u * 0.014, y + h * 0.045),
        const Color(0xFF49423A),
        u * 0.008,
      );

      // Lửa ngoài.
      final flameOuter = Path()
        ..moveTo(x, y - h * 0.075)
        ..quadraticBezierTo(
          x + u * 0.04,
          y - h * 0.035,
          x + u * 0.022,
          y + h * 0.005,
        )
        ..quadraticBezierTo(x, y + h * 0.025, x - u * 0.022, y + h * 0.005)
        ..quadraticBezierTo(x - u * 0.04, y - h * 0.035, x, y - h * 0.075)
        ..close();

      canvas.drawPath(flameOuter, fill(_flameOuter));

      // Lửa trong.
      final flameInner = Path()
        ..moveTo(x, y - h * 0.052)
        ..quadraticBezierTo(
          x + u * 0.02,
          y - h * 0.02,
          x + u * 0.009,
          y + h * 0.002,
        )
        ..quadraticBezierTo(x, y + h * 0.01, x - u * 0.009, y + h * 0.002)
        ..quadraticBezierTo(x - u * 0.02, y - h * 0.02, x, y - h * 0.052)
        ..close();

      canvas.drawPath(flameInner, fill(_flameInner));
    }

    drawTorch(w * 0.205, h * 0.61, false);
    drawTorch(w * 0.795, h * 0.61, true);

    // ---------------------------------------------------------------
    // 11. Bó rơm và vật dụng y tế nhỏ cạnh cửa.
    // ---------------------------------------------------------------
    void drawSupply(double x, double y, bool rightSide) {
      final sackRect = Rect.fromLTWH(x, y, w * 0.075, h * 0.065);

      canvas.drawRRect(
        RRect.fromRectAndRadius(sackRect, Radius.circular(u * 0.012)),
        fill(const Color(0xFFB59A6A)),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(sackRect, Radius.circular(u * 0.012)),
        stroke(_wood, u * 0.006),
      );

      line(
        Offset(sackRect.left + sackRect.width * 0.2, sackRect.top),
        Offset(sackRect.left + sackRect.width * 0.8, sackRect.top),
        _wood,
        u * 0.008,
      );

      // Cuộn băng vải trắng.
      oval(
        Rect.fromCenter(
          center: Offset(x + sackRect.width * 0.5, y + sackRect.height * 0.48),
          width: sackRect.width * 0.34,
          height: sackRect.height * 0.24,
        ),
        _canvasLight,
        border: _canvasShadow,
        borderWidth: u * 0.004,
      );

      if (rightSide) {
        line(
          Offset(x + sackRect.width * 0.5, y + sackRect.height * 0.36),
          Offset(x + sackRect.width * 0.5, y + sackRect.height * 0.6),
          Pal.blood,
          u * 0.004,
        );
      }
    }

    drawSupply(w * 0.16, h * 0.79, false);
    drawSupply(w * 0.765, h * 0.79, true);

    // ---------------------------------------------------------------
    // 12. Mép chân lều, hoàn thiện viền và đường may.
    // ---------------------------------------------------------------
    final bottomHem = Path()
      ..moveTo(w * 0.12, h * 0.83)
      ..quadraticBezierTo(w * 0.5, h * 0.87, w * 0.88, h * 0.83);

    canvas.drawPath(bottomHem, stroke(_woodDark, u * 0.014));

    // Đường chỉ sáng trên vạt vải.
    line(
      Offset(w * 0.145, h * 0.824),
      Offset(w * 0.275, h * 0.812),
      _canvasLight,
      u * 0.006,
    );
    line(
      Offset(w * 0.855, h * 0.824),
      Offset(w * 0.725, h * 0.812),
      _canvasShadow,
      u * 0.006,
    );

    // Đinh tán trên chân cột.
    for (final x in [w * 0.285, w * 0.715]) {
      oval(
        Rect.fromCenter(
          center: Offset(x, h * 0.805),
          width: u * 0.012,
          height: u * 0.012,
        ),
        const Color(0xFFC4A16B),
        border: _woodDark,
        borderWidth: u * 0.003,
      );
    }

    // Giữ ink từ FacilityBrush để nét minh họa đồng bộ với hệ thống.
    // Viền ngoài cùng giúp lều rõ ràng trên nền sáng.
    canvas.drawPath(tentBody, ink);
  }

  @override
  bool shouldRepaint(covariant InfirmaryPainter oldDelegate) => false;
}
