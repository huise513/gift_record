import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
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

    // 每页最多15条记录
    const itemsPerPage = 15;

    // 构建页面
    final pages = <Widget>[];
    for (var i = 0; i < gifts.length; i += itemsPerPage) {
      final pageGifts = gifts.skip(i).take(itemsPerPage).toList();
      final pageNum = i ~/ itemsPerPage + 1;
      pages.add(_buildPage(pageGifts, pageNum, currencyFmt, dateFmt));
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
    NumberFormat currencyFmt,
    DateFormat dateFmt,
  ) {
    const itemsPerPage = 15;
    final totalPages = (gifts.length / itemsPerPage).ceil();
    final pageTotal = pageGifts.fold(0.0, (sum, g) => sum + g.amount);

    return Container(
      width: 650,
      color: const Color(0xFFFAF7F2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '礼 金 本',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('笔数', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                          const SizedBox(height: 4),
                          Text('${pageGifts.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3)),
                      Column(
                        children: [
                          Text('本页小计', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                          const SizedBox(height: 4),
                          Text(currencyFmt.format(pageTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFE066))),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.08),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.15), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                _TableHeaderCell('序号', width: 60),
                _TableHeaderCell('姓名', flex: 2),
                _TableHeaderCell('金额', flex: 2),
                const _TableHeaderCell('签名', width: 80),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                border: Border(
                  bottom: BorderSide(color: Colors.brown.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  _TableCell('${globalIndex + 1}', width: 60, color: const Color(0xFFB8907A)),
                  _TableCell(gift.giverName, flex: 2),
                  _TableCell(currencyFmt.format(gift.amount), flex: 2, isAmount: true),
                  const _TableCell('', width: 80),
                ],
              ),
            );
          }),

          // 空白行（填充到最少15行）
          ...List.generate(itemsPerPage - pageGifts.length, (i) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: (pageGifts.length + i) % 2 == 0 ? Colors.white : const Color(0xFFFAF7F2),
                border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  _TableCell('', width: 60),
                  _TableCell('', flex: 2),
                  _TableCell('', flex: 2),
                  const _TableCell('', width: 80),
                ],
              ),
            );
          }),

          // 底部汇总
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.2), width: 2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryItem(label: '本页笔数', value: '${pageGifts.length}', color: const Color(0xFFE07B54)),
                    _SummaryItem(label: '本页小计', value: currencyFmt.format(pageTotal), color: const Color(0xFFE07B54)),
                    _SummaryItem(label: '累计总额', value: currencyFmt.format(totalAmount), color: const Color(0xFFD4603C)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '第 $pageNum / $totalPages 页',
                  style: TextStyle(fontSize: 11, color: Colors.brown[300]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;

  const _TableHeaderCell(this.text, {this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFE07B54),
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

class _TableCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;
  final bool isAmount;
  final Color? color;

  const _TableCell(this.text, {this.width, this.flex, this.isAmount = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: isAmount ? FontWeight.w600 : FontWeight.normal,
      color: color ?? (isAmount ? const Color(0xFFE07B54) : const Color(0xFF5C3D2E)),
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.brown[400])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
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
                        '共 ${gifts.length} 笔记录，自动分页',
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