import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../domain/identity.dart';
import '../../../domain/models.dart';
import '../../../domain/terrain_type.dart';
import '../art/soldiers/soldier_painter.dart';
import '../flag/flag_view.dart';

/// Thanh thể lực gắn trên đầu nhân vật. Chỉ hiển thị giá trị của [HeroState] (không có bản sao riêng).
class StaminaBar extends StatelessWidget {
  const StaminaBar({super.key, required this.stamina, this.width = 58});

  final double stamina;
  final double width;

  @override
  Widget build(BuildContext context) {
    final f = (stamina / TerrainRules.maxStamina).clamp(0.0, 1.0).toDouble();
    final color = f > 0.5
        ? const Color(0xFF8DBB5A)
        : f > 0.25
        ? const Color(0xFFE0B04A)
        : const Color(0xFFC4473B);
    return Semantics(
      label:
          'Thể lực ${stamina.ceil()} trên ${TerrainRules.maxStamina.round()}',
      child: Container(
        key: const ValueKey('hero-stamina-bar'),
        width: width,
        height: 11,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: const Color(0xE6140F0A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: f <= 0 ? const Color(0xFFC4473B) : Pal.goldDim,
            width: 1,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            key: const ValueKey('hero-stamina-fill'),
            widthFactor: f,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar nhân vật chính trên bản đồ: hình người đi bộ (dùng lại [SoldierSprite]) + bóng dưới chân +
/// thanh thể lực phía trên. Bước chân nhún theo quãng đường thực đã đi (không dùng bộ đếm giờ riêng).
class HeroMarker extends StatelessWidget {
  const HeroMarker({
    super.key,
    required this.hero,
    required this.identity,
    required this.size,
    required this.moving,
  });

  final HeroState hero;
  final PlayerIdentity identity;
  final double size;
  final bool moving;

  static const double barBand = 20;

  /// Tổng chiều cao ô chứa: thanh thể lực + hình người.
  static double heightFor(double size) => size + barBand;

  @override
  Widget build(BuildContext context) {
    final phase = (hero.x + hero.y) / 9;
    final bob = moving ? -math.sin(phase).abs() * size * 0.07 : 0.0;
    final sway = moving ? math.sin(phase) * 0.05 : 0.0;
    return SizedBox(
      key: const ValueKey('hero-marker'),
      width: 96,
      height: heightFor(size),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: -2,
            child: Container(
              width: size * 0.7,
              height: size * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, bob),
              child: Transform.rotate(
                angle: sway,
                alignment: Alignment.bottomCenter,
                child: SoldierSprite(
                  role: Role.cavalry,
                  seed: identity.avatar.appearanceId.hashCode.abs(),
                  armorId: 'chain_mail',
                  weaponId: 'arming_sword',
                  shieldId: 'round_shield',
                  bust: false,
                  size: size,
                ),
              ),
            ),
          ),
          // Cờ quân đoàn cắm cạnh nhân vật (chỉ đọc cờ từ danh tính; không phải đơn vị mới).
          Positioned(
            key: const ValueKey('hero-legion-flag'),
            bottom: 0,
            left: 48 + size * 0.34,
            child: Transform.translate(
              offset: Offset(0, bob),
              child: _BannerPole(identity: identity, height: size * 0.92),
            ),
          ),
          Positioned(top: 0, child: StaminaBar(stamina: hero.stamina)),
        ],
      ),
    );
  }
}

/// Cột cờ nhỏ mang quân kỳ của người chơi, đặt cạnh nhân vật trên bản đồ.
class _BannerPole extends StatelessWidget {
  const _BannerPole({required this.identity, required this.height});

  final PlayerIdentity identity;
  final double height;

  @override
  Widget build(BuildContext context) {
    final flagW = (height * 0.42).clamp(16.0, 30.0).toDouble();
    return SizedBox(
      width: flagW + 3,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: const Color(0xFF3A2A18)),
          ),
          Positioned(
            left: 2,
            top: 1,
            child: FlagView(
              composition: composeFlag(identity.flag),
              width: flagW,
              showBorder: false,
            ),
          ),
        ],
      ),
    );
  }
}
