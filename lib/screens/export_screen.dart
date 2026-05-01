import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/gift_entry.dart';

class ExportGiftBookScreen extends StatelessWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;

  const ExportGiftBookScreen({
    super.key,
    required this.gifts,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('导出礼金本'),
        backgroundColor: const Color(0xFFE07B54),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _PreviewCard(gifts: gifts, totalAmount: totalAmount),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareImage(context),
                    icon: const Icon(Icons.share),
                    label: const Text('分享图片'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE07B54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy年MM月dd日 HH:mm');

    const itemsPerPage = 12;
    final totalPages = (gifts.length / itemsPerPage).ceil();

    final pages = <Widget>[];
    for (var i = 0; i < gifts.length; i += itemsPerPage) {
      final pageGifts = gifts.skip(i).take(itemsPerPage).toList();
      final pageNum = i ~/ itemsPerPage + 1;
      pages.add(_buildPage(pageGifts, pageNum, totalPages, currencyFmt, dateFmt));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成礼金本图片...')),
    );

    final files = <XFile>[];
    final directory = await getTemporaryDirectory();

    for (var i = 0; i < pages.length; i++) {
      try {
        final pageController = ScreenshotController();
        final image = await pageController.captureFromWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Material(
              child: pages[i],
            ),
          ),
          pixelRatio: 2.5,
          delay: const Duration(milliseconds: 100),
        );

        final file = File('${directory.path}/gift_book_${i + 1}.png');
        await file.writeAsBytes(image);
        files.add(XFile(file.path));
      } catch (e) {
        debugPrint('Page $i capture failed: $e');
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(files, text: '礼金本（共${files.length}页）');
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，请重试')),
        );
      }
    }
  }

  Widget _buildPage(
    List<GiftEntry> pageGifts,
    int pageNum,
    int totalPages,
    NumberFormat currencyFmt,
    DateFormat dateFmt,
  ) {
    const itemsPerPage = 12;
    final pageTotal = pageGifts.fold(0.0, (sum, g) => sum + g.amount);
    final giftsWithNotes = pageGifts.where((g) => g.note != null && g.note!.isNotEmpty).toList();

    return Container(
      width: 680,
      color: const Color(0xFFFAF7F2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    const Text(
                      '礼 金 本',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pageNum / $totalPages',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('本页笔数', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('${pageGifts.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('本页小计', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(pageTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFE066))),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('累计总额', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.06),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.15), width: 1.5),
              ),
            ),
            child: const Row(
              children: [
                _HCell('序号', width: 44),
                _HCell('姓名', flex: 2),
                _HCell('金额', flex: 2),
                _HCell('方式', width: 66),
                _HCell('备注', flex: 3),
                _HCell('签名', width: 56),
              ],
            ),
          ),

          // 记录行
          ...pageGifts.asMap().entries.map((entry) {
            final index = entry.key;
            final gift = entry.value;
            final globalIndex = (pageNum - 1) * itemsPerPage + index;
            final isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.07))),
              ),
              child: Row(
                children: [
                  _Cell('${globalIndex + 1}', width: 44, center: true, color: const Color(0xFFB8907A)),
                  _Cell(gift.giverName, flex: 2),
                  _Cell(currencyFmt.format(gift.amount), flex: 2, bold: true, color: const Color(0xFFE07B54)),
                  _Cell(_paymentEmoji(gift.paymentMethod) + gift.paymentMethod, width: 66, center: true, fontSize: 11, color: const Color(0xFF8B6347)),
                  _Cell(gift.note ?? '', flex: 3, fontSize: 11, color: const Color(0xFF9E8B7D)),
                  const _Cell('', width: 56),
                ],
              ),
            );
          }),

          // 空白行填充
          ...List.generate(itemsPerPage - pageGifts.length, (i) {
            final isEven = (pageGifts.length + i) % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.07))),
              ),
              child: Row(
                children: [
                  const _Cell('', width: 44),
                  const _Cell('', flex: 2),
                  const _Cell('', flex: 2),
                  const _Cell('', width: 66),
                  const _Cell('', flex: 3),
                  const _Cell('', width: 56),
                ],
              ),
            );
          }),

          // 备注区域（如果有备注）
          if (giftsWithNotes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B54).withOpacity(0.04),
                border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.12), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 13, color: Color(0xFFE07B54)),
                      const SizedBox(width: 4),
                      const Text(
                        '备注',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE07B54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...giftsWithNotes.map((gift) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${gift.giverName}：',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF8B6347)),
                          ),
                          Expanded(
                            child: Text(
                              gift.note!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9E8B7D)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // 底部汇总
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.2), width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryItem(label: '本页笔数', value: '${pageGifts.length}', color: const Color(0xFFE07B54)),
                _SummaryItem(label: '本页小计', value: currencyFmt.format(pageTotal), color: const Color(0xFFE07B54)),
                _SummaryItem(label: '累计总额', value: currencyFmt.format(totalAmount), color: const Color(0xFFD4603C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _paymentEmoji(String method) {
    return switch (method) {
      '微信' => '💚 ',
      '支付宝' => '🔵 ',
      '银行转账' => '🏦 ',
      _ => '💵 ',
    };
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;

  const _HCell(this.text, {this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Color(0xFFE07B54),
    );

    if (width != null) {
      return SizedBox(width: width, child: Text(text, textAlign: TextAlign.center, style: style));
    }
    if (flex != null) {
      return Expanded(flex: flex!, child: Text(text, textAlign: TextAlign.center, style: style));
    }
    return Text(text, textAlign: TextAlign.center, style: style);
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;
  final bool center;
  final bool bold;
  final double fontSize;
  final Color color;

  const _Cell(
    this.text, {
    this.width,
    this.flex,
    this.center = false,
    this.bold = false,
    this.fontSize = 13,
    this.color = const Color(0xFF5C3D2E),
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      color: color,
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (flex != null) {
      return Expanded(
        flex: flex!,
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }
    return Text(text, style: style);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.brown[400])),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;

  const _PreviewCard({required this.gifts, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE07B54), Color(0xFFD4603C)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '礼金本预览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(label: '总笔数', value: '${gifts.length}'),
                    Container(width: 1, height: 50, color: Colors.brown.withOpacity(0.1)),
                    _StatBox(label: '总金额', value: currencyFmt.format(totalAmount), valueColor: const Color(0xFFE07B54)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFE07B54), size: 28),
                      const SizedBox(height: 8),
                      const Text('点击"分享图片"导出完整礼金本', style: TextStyle(fontSize: 14, color: Color(0xFF8B6347))),
                      const SizedBox(height: 4),
                      Text(
                        '含姓名、金额、支付方式、备注',
                        style: TextStyle(fontSize: 12, color: Colors.brown[300]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.brown[400])),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF5C3D2E)),
        ),
      ],
    );
  }
}