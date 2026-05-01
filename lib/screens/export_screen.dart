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
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        title: const Text('导出礼金本'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _GiftBookWidget(gifts: gifts, totalAmount: totalAmount),
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
                      backgroundColor: const Color(0xFF8B0000),
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
    final controller = ScreenshotController();
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy年MM月dd日 HH:mm');

    // 构建多页内容
    final pages = <Widget>[];
    const itemsPerPage = 15;

    for (var i = 0; i < gifts.length; i += itemsPerPage) {
      final pageGifts = gifts.skip(i).take(itemsPerPage).toList();
      pages.add(_buildPage(pageGifts, i ~/ itemsPerPage + 1, (gifts.length / itemsPerPage).ceil(), currencyFmt, dateFmt));
    }

    // 如果只有一页，直接截图
    if (pages.length == 1) {
      try {
        final image = await controller.captureFromWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Material(
              child: pages.first,
            ),
          ),
          pixelRatio: 3.0,
          delay: const Duration(milliseconds: 100),
        );

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/礼金本_${DateFormat('yyyyMMdd').format(DateTime.now())}.png');
        await file.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '礼金本_${dateFmt.format(DateTime.now())}',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败: $e')),
          );
        }
      }
    } else {
      // 多页：分页截图后分享
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成分页图片...')),
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
            pixelRatio: 3.0,
            delay: const Duration(milliseconds: 100),
          );

          final file = File('${directory.path}/礼金本_第${i + 1}页.png');
          await file.writeAsBytes(image);
          files.add(XFile(file.path));
        } catch (e) {
          // 跳过失败的页面
        }
      }

      if (files.isNotEmpty) {
        await Share.shareXFiles(files, text: '礼金本（共${files.length}页）');
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
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF5E6D3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面头部
          Center(
            child: Column(
              children: [
                const Text(
                  '礼 金 本',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                  style: TextStyle(fontSize: 14, color: Colors.brown[400]),
                ),
                if (totalPages > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    '第 $pageNum / $totalPages 页',
                    style: TextStyle(fontSize: 12, color: Colors.brown[300]),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF8B0000), thickness: 2),
          const SizedBox(height: 16),

          // 表格标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('序号', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000)))),
                Expanded(child: Text('姓名', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000)))),
                Expanded(child: Text('金额', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000)))),
                Text('签名', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000))),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 礼金记录
          ...pageGifts.asMap().entries.map((entry) {
            final index = entry.key;
            final gift = entry.value;
            final globalIndex = (pageNum - 1) * 15 + index;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.brown.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${globalIndex + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.brown[400], fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      gift.giverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      currencyFmt.format(gift.amount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60, child: Text('', textAlign: TextAlign.center)),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF8B0000), thickness: 1),
          const SizedBox(height: 12),

          // 汇总
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('本页笔数', style: TextStyle(fontSize: 12, color: Color(0xFF8B0000))),
                    Text(
                      '${pageGifts.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('本页小计', style: TextStyle(fontSize: 12, color: Color(0xFF8B0000))),
                    Text(
                      currencyFmt.format(pageGifts.fold(0.0, (sum, g) => sum + g.amount)),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('累计总额', style: TextStyle(fontSize: 12, color: Color(0xFF8B0000))),
                    Text(
                      currencyFmt.format(totalAmount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              '第 $pageNum / $totalPages 页',
              style: TextStyle(fontSize: 12, color: Colors.brown[300]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftBookWidget extends StatelessWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;

  const _GiftBookWidget({required this.gifts, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // 预览头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Text(
                '礼 金 本 预 览',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // 预览内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: '总笔数', value: '${gifts.length}'),
                    _StatItem(label: '总金额', value: currencyFmt.format(totalAmount), valueColor: const Color(0xFF8B0000)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '点击下方"分享图片"按钮导出完整礼金本',
                  style: TextStyle(color: Colors.brown[400], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '导出的图片包含所有 ${gifts.length} 笔记录及汇总信息',
                  style: TextStyle(color: Colors.brown[300], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.brown[400])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.brown[700],
          ),
        ),
      ],
    );
  }
}