# Phase 3 Changelog — kinh tế và thành phố

## Trạng thái ban đầu kiểm tra thực tế
`git status`: nhánh `main`, một commit rỗng ("first commit"), toàn bộ file chưa được theo dõi, có remote `origin`. **Không commit/push/đổi remote.** Ba backup giữ nguyên.
Source khớp báo cáo trước: domain/data/application/presentation tách riêng, save v2, 78 test, landscape.

## Phase A — kinh tế
- Công cụ: `tool/economy_sim.dart` (11 policy, 4 kịch bản softlock, chạy 60/150 ngày, CSV từng ngày), hook thu/chi `GameRules.ledgerIn/Out` và `dayHook` (null trong game thật).
- Sửa lỗi công cụ trong quá trình làm (ghi nhận để minh bạch): đếm nhiệm vụ hỏng, scout khi khám phá, đội thu thập yếu, ngưỡng nguy hiểm (hiệu chuẩn 0.8), vài đoạn vá không áp dụng do định dạng.
- Thay đổi luật/thông số (số liệu trước/sau ở [ECONOMY_V2_SIMULATION_REPORT.md](ECONOMY_V2_SIMULATION_REPORT.md)): phục kích 30%→20% và cấp địch `1+bậc`→`1+bậc~/2`; trợ cấp khẩn tuyến tính khi quân <6; bổng lộc đồng xu 10→16, thức ăn 12→10.
- Không loại permadeath, không hồi sinh binh sĩ.

## Phase B — thành phố và người bán
- Domain: `LocKind.city`, 3 thành phố, 8 người bán, `VendorDef`, `ShopStock`, tái cung, kho đồ có sức chứa, mua/bán/mua-và-trang-bị/lô tài nguyên, nhiệm vụ `visit` và `gearCount`.
- UI: `city_screen.dart`, `vendor_screen.dart`, `CityPainter`, `ResourceStrip`, liên kết bản đồ → đội hộ tống → thành phố; panel thành phố trên bản đồ.
- Save: trường tùy chọn, không tăng phiên bản.

## File
Mới: `lib/presentation/screens/city_screen.dart`, `vendor_screen.dart`, `test/economy_v2_test.dart`, `test/city_trade_test.dart`, `test/city_flow_test.dart`,
`integration_test/city_write_test.dart`, `docs/qa/ECONOMY_V2_SIMULATION_REPORT.md`, `docs/game-design/CITIES_AND_VENDORS_DESIGN.md`, `docs/qa/generated/{baseline_,}econ_*`, `long150_*`.
Sửa: `lib/domain/{catalog,models,rules}.dart`, `lib/application/game_controller.dart`, `lib/presentation/{screens/{map,squad,camp_hub,missions}_screen.dart,widgets/{art,common,hud}.dart}`, `tool/economy_sim.dart`.
Cập nhật: test cũ dùng hằng số bổng lộc thay vì số cứng (mô hình kinh tế đổi); `tool/battle_sim.dart` giữ nguyên.
Không đổi: bundle ID, signing, phiên bản save, `legacy`, migration.

## Lỗi thật tìm thấy nhờ test/chạy thật trong phase này
1. Trạng thái cửa hàng chưa được ghi vào save (test round-trip bắt được).
2. Giao dịch thất bại vẫn tạo tồn kho khởi tạo (đọc làm thay đổi state, kể cả khi dựng widget): tách `peekStock` (thuần) khỏi `stockOf` (ghi).
3. Phục kích gây tử trận hàng loạt khi thu thập (chỉ lộ ra khi mô phỏng nhiều ngày): xem báo cáo kinh tế.
