# Player Avatar & Legion Flag — Spec và UI Contract

Trạng thái: logic ĐÃ triển khai (Phase C). UI do product owner thực hiện. Nhãn: **V** = đã kiểm chứng bằng code/test, **P** = đề xuất chờ duyệt, **A** = đã được product owner duyệt.

## 1. Phát hiện kiểm toán (V)
- Chưa từng có avatar/quân kỳ/legion/faction trong domain (`_factionNames` ở `deploy_screen.dart` chỉ là tên kẻ địch).
- Bản đồ không có vị trí hay di chuyển của người chơi; chỉ có `GameState.visiting` (thành phố đang ở). Viễn chinh là dịch chuyển tức thời. Bản đồ cũng không có điểm đánh dấu trại nhà.
- Không có asset ảnh; mọi hình vẽ bằng `CustomPainter`.
- Save v3; chuỗi migration v1→v3, v2→v3. `GameState.fromJson` đã có tiền lệ trường tùy chọn (`shops`, `tradeCount`).

## 2. Mô hình (file: `lib/domain/identity.dart`, `identity_catalog.dart`, `map_anchor.dart`)

```dart
class PlayerAvatar { String displayName; String appearanceId; }      // KHÔNG có chỉ số, id, cấp, HP, trang bị
class LegionFlag   { templateId, patternId, emblemId,
                     primaryColorId, secondaryColorId, emblemColorId } // chỉ id danh mục
class PlayerIdentity { PlayerAvatar avatar; LegionFlag flag; }
class IdentityDraft { /* cùng các trường, mọi trường nullable */ }     // trạng thái UI khi đang chỉnh
```
`GameState.identity` (mặc định `PlayerIdentity.defaults`) được lưu như một khóa tùy chọn `identity` của save v3.

### Vì sao avatar tách khỏi chiến đấu (V, có test)
- `identity.dart` không import `models/battle/rules/stats` (test kiểm tra import).
- Avatar không có id trong không gian id binh sĩ; đội hình/viễn chinh/`unitFrom` chỉ nhận `Soldier` tra theo id từ `GameState.soldiers`. Tạo game có identity không làm đổi roster, ứng viên, tinh thần hay bất kỳ dữ liệu chơi nào (test so sánh JSON ngoài `identity`).
- Không đổi `Soldier`, `battle.dart` hay chỉ số.

## 3. Danh mục (P — giá trị chờ duyệt)
**Ngoại hình avatar (6)**: `commander_1` … `commander_6` (nhãn "Chỉ huy 1…6"). Không bắt buộc giới tính; thêm mục mới = thêm một dòng trong `IdentityCatalog.avatars`.

**Khung (4)**
| id | silhouette | tỉ lệ rộng/cao | chia đôi | tâm huy hiệu (x=0.5, y) | cỡ huy hiệu (× rộng) |
|---|---|---|---|---|---|
| `rectangle` | rectangle | 3:2 | không | 0.5 | 0.5 |
| `vertical_banner` | verticalBanner (đáy có đuôi nhọn/xẻ — UI quyết định) | 2:3 | không | 0.4 | 0.6 |
| `split_field` | rectangle | 3:2 | có (x<0.5 màu chính, x≥0.5 màu phụ) | 0.5 | 0.5 |
| `shield` | shield | 5:6 | không | 0.42 | 0.5 |

**Hoa văn (4)**, vẽ bằng màu phụ phía trên nền: `solid` (không có lớp), `stripes` (sọc ngang), `diagonal` (chéo), `chevron` (chữ V). Mật độ/độ dày do renderer quyết định, chỉ cần xác định (không ngẫu nhiên).

**Huy hiệu (12)**: `lion, wolf, eagle, dragon` (animal) · `sword, crossed_swords` (weapon) · `shield, crown` (heraldic) · `star, sun` (celestial) · `mountain, tree` (nature).

**Màu (12, ARGB đục)**
| id | ARGB | id | ARGB |
|---|---|---|---|
| `crimson` | 0xFFB3202A | `royal_purple` | 0xFF5E3A8C |
| `azure` | 0xFF2B4C9B | `amber` | 0xFFD9772B |
| `forest` | 0xFF2F6B3A | `steel` | 0xFF7A8189 |
| `gold` | 0xFFD4A93A | `teal` | 0xFF2C8C8A |
| `ivory` | 0xFFF2EBD9 | `umber` | 0xFF6B4423 |
| `onyx` | 0xFF1B1B1F | `sky` | 0xFF5BA3D9 |

Mặc định (hợp lệ, xác định): avatar `commander_1`, tên "Chỉ huy"; khung `rectangle`, hoa văn `solid`, huy hiệu `lion`, chính `crimson`, phụ `ivory`, huy hiệu `gold`.

## 4. Kiểm tra (`validateIdentityDraft` / `validateIdentity`)
Trả `List<IdentityIssue(field, code, detail?)>`, thứ tự ổn định; rỗng = hợp lệ.
- Tên: cắt khoảng trắng, 1–24 ký tự (`nameEmpty`, `nameTooLong`; `missing` nếu null). Không có luật tên nào khác.
- Mỗi id phải tồn tại trong danh mục (`unknownId`, `detail` = id sai; `missing` nếu null).
- Tương phản huy hiệu (`emblemLowContrast` trên field `emblemColor`, `detail` = `"<colorId>:<tỉ lệ>"`): tỉ lệ tương phản WCAG ≥ **3.0** (`minEmblemContrast`) giữa màu huy hiệu và mọi màu nền huy hiệu phủ lên: màu chính luôn; màu phụ khi khung `split_field` HOẶC hoa văn ≠ `solid`. Chỉ báo, không tự đổi lựa chọn.
- Không có tổ hợp khung × hoa văn nào bị cấm; màu chính = màu phụ hợp lệ.

## 5. Hợp thành quân kỳ (`composeFlag(LegionFlag) → FlagComposition`)
`FlagComposition { silhouette, aspectRatio, emblemCenterY, emblemScale, layers }`. Vẽ `layers` từ dưới lên, cắt theo silhouette:
1. `field` (luôn có) — phủ toàn hình, màu chính.
2. `splitHalf` (chỉ `split_field`) — nửa x ≥ 0.5, màu phụ.
3. `pattern` (chỉ khi ≠ solid; `refId` = patternId) — màu phụ.
4. `emblem` (luôn cuối; `refId` = emblemId) — màu huy hiệu, căn giữa tại (0.5, `emblemCenterY`), cạnh = `emblemScale × chiều rộng`.

`composeFlag` không ném lỗi: id lạ rơi về mặc định để preview luôn vẽ được. Dùng validate để biết lựa chọn có hợp lệ không. Renderer không cần luật nghiệp vụ nào khác; chỉ ánh xạ `silhouette`/`pattern.refId`/`emblem.refId` sang hình vẽ.

## 6. Neo avatar trên bản đồ (V)
`resolveMapAnchor(GameState) → MapAnchor` (`GameController.avatarAnchor`): `visiting` hợp lệ → `MapAnchor.location(id, x, y)` theo `LocationDef`; ngược lại `MapAnchor.homeCamp()` với `x/y == null` vì bản đồ chưa có trại nhà — UI tự chọn chỗ vẽ. Không có trường vị trí nào được lưu. Avatar CHƯA di chuyển; chỉ đổi neo khi `visiting` đổi.

## 7. New Game & lưu (V)
- `GameRules.newGame({seed})` giữ nguyên; thêm `identity:` tùy chọn (ném `ArgumentError` nếu sai). Mọi call site cũ không đổi.
- `GameController.createGame({seed, required IdentityDraft draft}) → Future<NewGameResult>`: validate → dựng state → `repo.save` → chỉ khi lưu xong mới gán `_state`. Sai cấu hình → `NewGameResult.invalid(issues)`; lưu lỗi → `saveFailed(msg)`; cả hai không đổi state, report hay `hasSave`. (Lưu ý: `newGame()` cũ vẫn gán state trước khi lưu, giữ nguyên hành vi cũ theo phạm vi.)
- Save: **giữ version 3**. `identity` là khóa tùy chọn; thiếu/hỏng → mặc định; từng trường id lạ/sai kiểu → mặc định của riêng trường đó, phần còn lại giữ; tên rỗng → "Chỉ huy", dài >24 → cắt. Không kiểm tra tương phản khi tải. Không cần bump vì: loader thiếu khóa không lỗi (test), v1/v2 migrate xong đều ra mặc định (test), save v3 cũ đọc được (test). Rủi ro: bản app cũ mở save mới sẽ bỏ qua khóa này và ghi đè mất nó; bản v2/v1 gốc luôn được lưu trữ nguyên bản.

## 8. UI contract (do product owner thực hiện)

### API
```dart
c.checkIdentityDraft(IdentityDraft) -> List<IdentityIssue>       // thuần, gọi mỗi lần đổi
c.previewFlag(LegionFlag) -> FlagComposition                      // thuần
c.createGame({int? seed, required IdentityDraft draft}) -> Future<NewGameResult>
//   NewGameResult: ok | issues (field-specific) | saveError
c.identity -> PlayerIdentity?          // sau Continue/New: khôi phục từ save
c.avatarAnchor -> MapAnchor?
IdentityCatalog.{avatars,templates,patterns,emblems,colors}       // dữ liệu hiển thị lựa chọn
IdentityDraft.initial() / IdentityDraft.from(identity) / .copyWith(...) / .toIdentity()
```
`draft.copyWith(field: null)` bỏ chọn (sẽ báo `missing`); bỏ qua tham số = giữ nguyên.

### Màn hình / file đề xuất (chưa tạo — thuộc về bạn)
| File | Trách nhiệm | Dùng | Phát ra |
|---|---|---|---|
| `lib/presentation/screens/new_game_screen.dart` (hoặc 2 bước) | Giữ `IdentityDraft` trong state; bước avatar (tên + 6 ngoại hình) và bước quân kỳ; hiển thị lỗi theo `IdentityField`; nút xác nhận gọi `createGame` | `IdentityCatalog`, `checkIdentityDraft`, `previewFlag`, `createGame` | `createGame(draft)` khi xác nhận |
| `lib/presentation/widgets/flag_view.dart` | Renderer thuần hiển thị: nhận `FlagComposition`, vẽ theo §5 | `FlagComposition` | — |
| `lib/presentation/widgets/avatar_view.dart` | Vẽ avatar từ `appearanceId` | `PlayerAvatar` | — |
| `menu_screen.dart` `_startNewGame` | Điểm tích hợp duy nhất: thay `controller.newGame()` bằng điều hướng sang màn New Game (xác nhận ghi đè giữ nguyên); `shell.dart:191` tương tự cho "Bắt đầu ván mới" | — | — |
| `map_screen.dart` | Vẽ avatar tại `c.avatarAnchor` (homeCamp: tự chọn vị trí) | `MapAnchor`, `c.identity` | — |

Thứ tự đề xuất: (1) `flag_view` + `avatar_view`; (2) màn New Game bước avatar; (3) bước quân kỳ với preview; (4) nối `menu_screen`/`shell`; (5) vẽ avatar/quân kỳ trên map và HUD.

Trạng thái: **ban đầu** `IdentityDraft.initial()` (tên trống ⇒ nút xác nhận bị vô hiệu cho tới khi `checkIdentityDraft` rỗng). **Đang chọn**: mỗi thay đổi tạo draft mới + kiểm tra lại. **Đã xác nhận**: `createGame` → `ok` → `c.state != null`, shell tự hiện (như `newGame()` hiện tại). Lỗi: `issues` hiển thị theo `field`; `saveError` hiển thị chung, ván cũ còn nguyên. Điều hướng vào: từ menu/shell; ra: màn trại như hiện nay.

### Artwork cần cung cấp
- 6 ngoại hình avatar (`commander_1..6`): chân dung cho màn tạo và sprite/biểu tượng cho bản đồ — định dạng do bạn chọn (CustomPainter như phần còn lại hoặc PNG/SVG; dự án chưa có asset hay package SVG).
- 12 huy hiệu đơn sắc (tô được bằng màu huy hiệu), 3 hoa văn (stripes, diagonal, chevron) và 3 hình silhouette (vertical_banner, shield, rectangle). Chưa có asset nào — danh mục chỉ chứa id.

## 9. Hạn chế đã biết
- Avatar không di chuyển; chưa có điểm trại nhà trên bản đồ.
- Màu, tỉ lệ và vị trí huy hiệu là đề xuất (P). Ngưỡng tương phản 3.0 là lựa chọn của tôi.
- Nhãn danh mục là tiếng Việt cố định trong code, chưa có hệ thống i18n.
- 27 test UI (`landscape_flow_test`, `city_flow_test`) đang fail từ trước khi thay đổi này (đo ở cùng thời điểm với working tree đang có thay đổi UI của bạn); không liên quan tới logic ở đây.

## 10. Quyết định còn cần duyệt
1. Bảng màu §3 và hình học khung §3.
2. Ngưỡng tương phản 3.0.
3. Có sửa `newGame()` cũ để cũng lưu trước khi gán state không (hiện giữ nguyên).
