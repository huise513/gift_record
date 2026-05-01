# 礼金簿 (Gift Record Book) - V1.0 MVP Specification

## 1. Project Overview

- **Project Name**: 礼金簿 (Gift Record Book)
- **Type**: Mobile offline-first Flutter application (Android primary, iOS secondary)
- **Core Feature**: Minimalist gift record management for weddings/birthday banquets, with traditional styled export images
- **Target Users**: Chinese families organizing banquets who need quick guest gift recording

## 2. Technology Stack

- **Framework**: Flutter 3.41.5 / Dart 3.11.3
- **Database**: SQLite via `sqflite` (local offline, no network)
- **State Management**: StatefulWidget + Provider for reactive UI
- **Image Export**: `screenshot` + `share_plus` + `path_provider`
- **Image Generation**: Custom Canvas/Painter for traditional paper texture + scrollable long-image composition

## 3. UI/UX Specification

### 3.1 Color Palette
| Role        | Hex       | Description              |
|-------------|-----------|--------------------------|
| Primary     | #8B0000   | Dark red (婚宴/寿宴氛围) |
| Accent      | #FFD700   | Gold (标题/金额)          |
| Background  | #F5E6D3   | Warm cream (仿宣纸)       |
| Surface     | #FFF8F0   | Light warm white          |
| Text Dark   | #4A2C2A   | Dark brown                |
| Text Light  | #8B7355   | Medium brown              |

### 3.2 Typography
- **Headings**: System default (PingHei/SimHei), Bold
- **Numbers**: Bold, prominent (礼金金额)
- **Body**: System default, readable

### 3.3 Screen Structure

```
App
├── HomeScreen (宴席列表)
│   ├── Empty state → "暂无宴席，点击创建"
│   └── Event list (card per event)
│       → tap → EventDetailScreen
│       → FAB → CreateEventDialog
├── EventDetailScreen (礼金详情)
│   ├── Summary header (total amount, guest count)
│   ├── Scrollable record list (序号/姓名/金额)
│   ├── Bottom: "导出图片" button
│   └── FAB: Quick add record
│       → FAB → AddRecordDialog
│       → long press record → DeleteConfirmDialog
├── CreateEventDialog / EditEventDialog (Modal)
│   ├── Event name input
│   ├── Type selector (婚宴/寿宴)
│   ├── Date picker
│   └── Confirm/Cancel
├── AddRecordDialog (Modal)
│   ├── Guest name input (auto-focus, immediate clear after add)
│   ├── Amount input (numeric keyboard)
│   └── Confirm (stays open for fast consecutive entry)
└── ExportPreviewScreen
    ├── Preview of generated long-image
    ├── Save to gallery
    └── Share via system
```

### 3.4 Navigation
- Navigator 1.0 with MaterialPageRoute (simple, sufficient for 3-level depth)
- No complex routing needed for MVP

## 4. Data Specification

### 4.1 Database Schema

**Table: events**
| Column       | Type    | Constraints          |
|--------------|---------|----------------------|
| id           | INTEGER | PRIMARY KEY AUTOINCREMENT |
| name         | TEXT    | NOT NULL             |
| type         | TEXT    | NOT NULL ('wedding'/'birthday') |
| date         | INTEGER | NOT NULL (epoch ms)  |
| total_amount | INTEGER | DEFAULT 0            |
| guest_count  | INTEGER | DEFAULT 0            |

**Table: records**
| Column       | Type    | Constraints          |
|--------------|---------|----------------------|
| id           | INTEGER | PRIMARY KEY AUTOINCREMENT |
| event_id     | INTEGER | FOREIGN KEY → events.id |
| guest_name   | TEXT    | NOT NULL             |
| amount       | INTEGER | NOT NULL (unit: 分, int) |
| created_time | INTEGER | NOT NULL (epoch ms)  |

> **Note**: amount stored as integer (分/ cents), displayed as 元 (÷100). This avoids floating-point precision issues.

### 4.2 Data Operations
- `getAllEvents()` → list sorted by date DESC
- `getEvent(id)` → single event
- `insertEvent(event)` → returns new id
- `updateEvent(event)` → bool
- `deleteEvent(id)` → deletes event + all its records
- `getRecordsForEvent(eventId)` → ordered list
- `insertRecord(record)` → returns new id
- `deleteRecord(id)` → bool
- `recalcEventTotals(eventId)` → updates total_amount & guest_count

## 5. Functionality Specification

### 5.1 Event Management
- **Create**: name (required), type (婚宴/寿宴 radio), date (date picker, defaults today)
- **Edit**: tap edit icon on event card → same dialog pre-filled
- **Delete**: tap delete icon → confirmation dialog ("删除后清除所有记录") → cascade delete records
- **List display**: name, type icon, date, total amount, guest count

### 5.2 Record Management
- **Add**: dialog with name + amount fields, numeric keyboard for amount
- **Fast mode**: after confirming a record, amount field clears, name field clears, focus returns to name field
- **Real-time totals**: header card shows SUM(amount) and COUNT(*), updates immediately
- **Delete**: long-press record → confirmation → delete from DB → refresh totals
- **Auto-scroll**: list scrolls to newest item after add

### 5.3 Export Image (Traditional 礼金本 Style)
- **Dimensions**: width=1080px fixed, height auto (grows with record count)
- **Background**: cream/paper texture (#F5E6D3 warm aged paper look)
- **Header decoration**:
  - Wedding: red double-happiness (囍) motif + decorative banner
  - Birthday: gold circular 寿 character + crane motif
- **Title area**: event name (楷书 style) + date, centered below decoration
- **Table**:
  - Outer border: double dark red lines
  - Column headers: 深红底白字 (序号/姓名/礼金)
  - Alternating row colors: 米白 (#FFF8F0) and 暖黄 (#FFF0E0)
  - Every 5 rows: dashed light red separator line
  - Amount column: ¥ prefix, bold SongTi-style numbers
- **Footer summary**: red-tinted row, gold bold text "合计: ¥XXXX元  共XX人"
- **Seal**: red square篆刻印章 bottom-right, default text "礼金簿"
- **Date stamp**: small gray text below seal "导出日期: yyyy年MM月dd日"
- **Export options**: Save to gallery (requires permission) + Share via system share sheet

### 5.4 Permissions
- Android: WRITE_EXTERNAL_STORAGE (for gallery save on Android < 10)
- Uses `image_gallery_saver` or `share_plus` (which uses system share, no storage permission needed for Android 10+)

## 6. Non-Functional Requirements

- **Offline only**: zero network calls, all data local
- **Performance**: 300+ records scroll without jank; export image < 3s
- **Privacy**: no analytics, no network, no ads
- **Compatibility**: Android 6.0+ (API 23+), iOS 13+

## 7. File Structure

```
lib/
├── main.dart
├── models/
│   ├── event.dart
│   └── record.dart
├── services/
│   └── db_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── event_detail_screen.dart
│   └── export_preview_screen.dart
├── widgets/
│   ├── event_card.dart
│   ├── record_list_tile.dart
│   ├── add_event_dialog.dart
│   ├── add_record_dialog.dart
│   ├── summary_header.dart
│   └── gift_book_painter.dart
└── theme/
    └── app_theme.dart
```

## 8. Version

- **MVP V1.0**: All features listed above
- **Future**: relationship tags, return-gift tracking, statistics charts, data backup, app lock
