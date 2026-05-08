import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gift_book.dart';
import '../models/gift_entry.dart';
import 'db_service.dart';

/// Excel 导出服务
class ExportExcelService {
  static final _currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
  static final _dateFmt = DateFormat('yyyy年MM月dd日');

  /// 格式化金额（截断不四舍五入）
  static String _fmtAmt(double amount) {
    if (amount == amount.roundToDouble()) {
      return '¥${amount.toInt()}';
    }
    final truncated = (amount * 100).floor() / 100;
    return '¥${truncated.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}';
  }

  /// 导出单个礼金本
  static Future<void> exportSingleBook(GiftBook book, List<GiftEntry> gifts) async {
    final excel = Excel.createExcel();
    final sheetName = _sanitizeSheetName(book.name);
    // 先创建目标 sheet，再删除默认 Sheet1（避免 delete 唯一 sheet 的限制）
    _buildSheet(excel[sheetName], book, gifts);
    excel.delete('Sheet1');
    await _saveAndShare(excel, '礼金本_${book.name}');
  }

  /// 导出所有礼金本
  static Future<void> exportAllBooks(List<GiftBook> books) async {
    final excel = Excel.createExcel();

    final sortedBooks = [...books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (var i = 0; i < sortedBooks.length; i++) {
      final book = sortedBooks[i];
      final gifts = await DbService.getGiftsForBook(book.id!);
      final sheetName = _sanitizeSheetName(book.name);
      _buildSheet(excel[sheetName], book, gifts);
    }
    // 删除默认 Sheet1（此时已有 N 个礼金本 sheet，delete 不会受阻）
    excel.delete('Sheet1');

    await _saveAndShare(excel, '所有礼金本');
  }

  /// 构建单个 sheet 的内容
  static void _buildSheet(Sheet sheet, GiftBook book, List<GiftEntry> gifts) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    // 标题行（行0）
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('${book.name}（${book.type.label}）  ${_dateFmt.format(book.createdAt)}');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('FFE07B54'),
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));

    // 统计行（行1）
    final totalAmount = gifts.fold<double>(0, (sum, g) => sum + g.amount);
    final summaryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    summaryCell.value = TextCellValue('共 ${gifts.length} 笔  合计：${_fmtAmt(totalAmount)}');
    summaryCell.cellStyle = CellStyle(
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('FF666666'),
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));

    // 列头（行2）
    final headers = ['序号', '姓名', '金额', '支付方式', '备注'];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('FFE07B54'),
        bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
      );
    }

    // 数据行（从行3开始）
    final startRow = 3;
    for (var i = 0; i < gifts.length; i++) {
      final gift = gifts[i];
      final bgColor = i.isEven ? ExcelColor.fromHexString('FFFAF7F2') : ExcelColor.white;

      // 序号
      final cell0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + i));
      cell0.value = IntCellValue(i + 1);
      cell0.cellStyle = _dataCellStyle(bgColor, HorizontalAlign.Center);

      // 姓名
      final cell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + i));
      cell1.value = TextCellValue(gift.giverName);
      cell1.cellStyle = _dataCellStyle(bgColor, HorizontalAlign.Left);

      // 金额
      final cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow + i));
      cell2.value = TextCellValue(_fmtAmt(gift.amount));
      cell2.cellStyle = _dataCellStyle(bgColor, HorizontalAlign.Right);

      // 支付方式
      final cell3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: startRow + i));
      cell3.value = TextCellValue(gift.paymentMethod);
      cell3.cellStyle = _dataCellStyle(bgColor, HorizontalAlign.Center);

      // 备注
      final cell4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: startRow + i));
      cell4.value = TextCellValue(gift.note ?? '');
      cell4.cellStyle = _dataCellStyle(bgColor, HorizontalAlign.Left);
    }

    // 设置列宽
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 25);
  }

  static CellStyle _dataCellStyle(ExcelColor bgColor, HorizontalAlign align) {
    return CellStyle(
      fontSize: 11,
      horizontalAlign: align,
      backgroundColorHex: bgColor,
      bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
      topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
      leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
      rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('FFD4603C')),
    );
  }

  /// Excel sheet 名称不能超过 31 字符，且不能包含 :/\?*[]
  static String _sanitizeSheetName(String name) {
    var sanitized = name.replaceAll(RegExp(r'[:\/?*\[\]]'), '');
    if (sanitized.length > 28) {
      sanitized = sanitized.substring(0, 28);
    }
    return sanitized;
  }

  static Future<void> _saveAndShare(Excel excel, String fileName) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/${fileName}_$timestamp.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: fileName,
    );
  }
}
