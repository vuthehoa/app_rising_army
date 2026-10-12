> **Cập nhật tái thiết:** tài liệu này mô tả prototype v1 (quân theo số lượng, 5 ải). Mô hình hiện hành: docs/game-design/GAMEPLAY_RECONSTRUCTION_PLAN.md và docs/RECONSTRUCTION_CHANGELOG.md.

# Lộ trình

1. (Xong) Audit, domain, save, UI MVP, test, build simulator.
2. Cân bằng: mô phỏng hàng loạt để chỉnh độ khó ải 3-5 và nhịp kinh tế.
3. Tướng lĩnh + trang bị (cần mở rộng GameState và tăng save version, viết migration v1→v2).
4. Màn chiến đấu có animation, âm thanh, minh họa chất lượng cao thay icon.
5. Bản đồ chiến dịch, cài đặt, landscape.
6. Đo hiệu năng trên thiết bị thật (Flutter DevTools), cấu hình bundle id/ký ứng dụng (cần tài khoản Apple của người dùng).
