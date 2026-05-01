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
    final dateFmt = DateFormat('yyyy年MM月dd日');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成礼金本图片...')),
    );

    try {
      final pageController = ScreenshotController();
      final fullImage = _buildFullPage(gifts, currencyFmt, dateFmt);

      final image = await pageController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: fullImage,
          ),
        ),
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/gift_book.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles([XFile(file.path)], text: '礼金本（共${gifts.length}条记录）');
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，请重试')),
        );
      }
    }
  }

  Widget _buildFullPage(
    List<GiftEntry> allGifts,
    NumberFormat currencyFmt,
    DateFormat dateFmt,
  ) {
    final giftsWithNotes = allGifts.where((g) => g.note != null && g.note!.isNotEmpty).toList();
    final pageTotal = allGifts.fold(0.0, (sum, g) => sum + g.amount);
    final pageCount = (allGifts.length / 12).ceil();

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
                const Text(
                  '礼 金 本',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateFmt.format(DateTime.now()),
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
                          Text('总笔数', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('${allGifts.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('礼金总额', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(pageTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFE066))),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('记录页数', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('$pageCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 支付方式统计
          _buildPaymentSummary(allGifts, currencyFmt),

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
              ],
            ),
          ),

          // 按页分组的记录（每12条为1页，页间用分隔线）
          ...List.generate(pageCount, (pageIndex) {
            final startIdx = pageIndex * 12;
            final endIdx = (startIdx + 12).clamp(0, allGifts.length);
            final pageGifts = allGifts.sublist(startIdx, endIdx);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 页眉（第一页不显示，后续每页显示"续页"）
                if (pageIndex > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    color: const Color(0xFFE07B54).withOpacity(0.04),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 14, color: Color(0xFFE07B54)),
                        const SizedBox(width: 4),
                        Text(
                          '第 ${pageIndex + 1} 页（续）',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFE07B54), fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          currencyFmt.format(pageGifts.fold(0.0, (sum, g) => sum + g.amount)),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFE07B54)),
                        ),
                      ],
                    ),
                  ),

                // 记录行
                ...pageGifts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final gift = entry.value;
                  final globalIndex = startIdx + index;
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
                      ],
                    ),
                  );
                }),

                // 空白行填充
                if (pageIndex == pageCount - 1 && pageGifts.length < 12)
                  ...List.generate(12 - pageGifts.length, (i) {
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
                        ],
                      ),
                    );
                  }),

                // 页脚汇总
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B54).withOpacity(0.03),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.12), width: 1),
                      bottom: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.08), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '第 ${pageIndex + 1} / $pageCount 页',
                        style: TextStyle(fontSize: 10, color: Colors.brown[300]),
                      ),
                      Text(
                        '本页小计：${currencyFmt.format(pageGifts.fold(0.0, (sum, g) => sum + g.amount))}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFE07B54)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          // 备注区域（如果有备注）
          if (giftsWithNotes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B54).withOpacity(0.04),
                border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.12), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 14, color: Color(0xFFE07B54)),
                      const SizedBox(width: 6),
                      const Text(
                        '备注说明',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE07B54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...giftsWithNotes.map((gift) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${gift.giverName}：',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8B6347)),
                          ),
                          Expanded(
                            child: Text(
                              gift.note!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9E8B7D)),
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

          // 底部总汇总
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.25), width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryItem(label: '总笔数', value: '${allGifts.length}', color: const Color(0xFFE07B54)),
                _SummaryItem(label: '礼金总额', value: currencyFmt.format(pageTotal), color: const Color(0xFFE07B54)),
                _SummaryItem(label: '现金', value: currencyFmt.format(_sumByMethod(allGifts, '现金')), color: const Color(0xFF8B6347)),
                _SummaryItem(label: '微信', value: currencyFmt.format(_sumByMethod(allGifts, '微信')), color: const Color(0xFF4CAF50)),
                _SummaryItem(label: '支付宝', value: currencyFmt.format(_sumByMethod(allGifts, '支付宝')), color: const Color(0xFF2196F3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(List<GiftEntry> allGifts, NumberFormat currencyFmt) {
    final cashTotal = _sumByMethod(allGifts, '现金');
    final wechatTotal = _sumByMethod(allGifts, '微信');
    final alipayTotal = _sumByMethod(allGifts, '支付宝');
    final bankTotal = _sumByMethod(allGifts, '银行转账');

    final hasMultiple = [cashTotal, wechatTotal, alipayTotal, bankTotal].where((t) => t > 0).length;

    // 只有一种支付方式时不显示统计行
    if (hasMultiple <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart_outline, size: 14, color: Color(0xFFE07B54)),
          const SizedBox(width: 6),
          Text('支付方式分布', style: TextStyle(fontSize: 11, color: Colors.brown[400], fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          if (cashTotal > 0) _PaymentChip(method: '现金', emoji: '💵', amount: currencyFmt.format(cashTotal)),
          if (wechatTotal > 0) _PaymentChip(method: '微信', emoji: '💚', amount: currencyFmt.format(wechatTotal)),
          if (alipayTotal > 0) _PaymentChip(method: '支付宝', emoji: '🔵', amount: currencyFmt.format(alipayTotal)),
          if (bankTotal > 0) _PaymentChip(method: '银行转账', emoji: '🏦', amount: currencyFmt.format(bankTotal)),
        ],
      ),
    );
  }

  double _sumByMethod(List<GiftEntry> gifts, String method) {
    return gifts.where((g) => g.paymentMethod == method).fold(0.0, (sum, g) => sum + g.amount);
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

class _PaymentChip extends StatelessWidget {
  final String method;
  final String emoji;
  final String amount;

  const _PaymentChip({required this.method, required this.emoji, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF8B6347))),
        ],
      ),
    );
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
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
    final pageCount = (gifts.length / 12).ceil();

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
                    Container(width: 1, height: 50, color: Colors.brown.withOpacity(0.1)),
                    _StatBox(label: '记录页数', value: '$pageCount'),
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
                        '所有记录合并为1张长图，每12条为1页',
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