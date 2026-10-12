import 'catalog.dart';
import 'models.dart';

enum MapAnchorKind { homeCamp, location }

/// Neo hiển thị của avatar trên bản đồ, dẫn xuất từ state hiện có (không lưu thêm vị trí).
/// Đây KHÔNG phải vị trí di chuyển: game chưa có hệ thống di chuyển (viễn chinh là dịch chuyển tức thời).
///
/// Với [MapAnchorKind.homeCamp], bản đồ hiện tại chưa có điểm đánh dấu trại nhà nên [x]/[y] là null;
/// UI tự quyết định chỗ vẽ.
class MapAnchor {
  const MapAnchor.homeCamp()
    : kind = MapAnchorKind.homeCamp,
      locationId = null,
      x = null,
      y = null;
  const MapAnchor.location(String this.locationId, double this.x, double this.y)
    : kind = MapAnchorKind.location;

  final MapAnchorKind kind;
  final String? locationId;

  /// Toạ độ 0..1 trên bản đồ (cùng hệ với [LocationDef.x]/[LocationDef.y]).
  final double? x, y;
}

/// `visiting` khác null và có trong danh mục → địa điểm đó; ngược lại → trại nhà.
MapAnchor resolveMapAnchor(GameState s) {
  final loc = s.visiting == null ? null : locationById(s.visiting!);
  return loc == null
      ? const MapAnchor.homeCamp()
      : MapAnchor.location(loc.id, loc.x, loc.y);
}
