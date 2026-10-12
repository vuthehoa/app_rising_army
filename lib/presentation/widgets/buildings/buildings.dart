/// Artwork của từng công trình, mỗi công trình một file/widget.
///
/// - Công trình trong trại (FacilityType): [FacilityArt] chọn theo loại,
///   hoặc dùng trực tiếp MeleeYardArt, ArcheryRangeArt, EnduranceYardArt, InfirmaryArt, CampfireArt.
/// - Công trình trong cảnh doanh trại (BuildingSpot): *SceneArt và hàm paint*Scene
///   mà CampPainter dùng để dựng cảnh.
library;

export 'archery_range_art.dart';
export 'camp_scene/barracks_scene_art.dart';
export 'camp_scene/board_scene_art.dart';
export 'camp_scene/gate_scene_art.dart';
export 'camp_scene/infirmary_scene_art.dart';
export 'camp_scene/scene_building_art.dart';
export 'camp_scene/smithy_scene_art.dart';
export 'camp_scene/tavern_scene_art.dart';
export 'camp_scene/training_ground_scene_art.dart';
export 'campfire_art.dart';
export 'facility_art.dart';
export 'gravestone_art.dart';
export 'infirmary_art.dart';
export 'melee_yard_art.dart';
export 'storage_chest_art.dart';
export 'shrine_art.dart';
