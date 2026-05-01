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
              child: _PreviewList(gifts: gifts, totalAmount: totalAmount),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
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
      width: 600,
      color: const Color(0xFFFAF7F2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(DateTime.now()),
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('总笔数', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('${allGifts.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('礼金总额', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(pageTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFE066))),
                        ],
                      ),
                      Container(width: 1, height: 24, color: Colors.white.withOpacity(0.25)),
                      Column(
                        children: [
                          Text('记录页数', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('$pageCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 支付方式统计（仅多种方式时显示）
          _buildPaymentSummary(allGifts, currencyFmt),

          // 表头 - 固定列宽
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.06),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.15), width: 1.5),
              ),
            ),
            child: const Row(
              children: [
                _HCell('序号', width: 40),
                _HCell('姓名', flex: 2),
                _HCell('金额', flex: 3),
                _HCell('备注', flex: 3),
              ],
            ),
          ),

          // 按页分组的记录
          ...List.generate(pageCount, (pageIndex) {
            final startIdx = pageIndex * 12;
            final endIdx = (startIdx + 12).clamp(0, allGifts.length);
            final pageGifts = allGifts.sublist(startIdx, endIdx);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 页眉（第一页之后显示）
                if (pageIndex > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    color: const Color(0xFFE07B54).withOpacity(0.04),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 12, color: Color(0xFFE07B54)),
                        const SizedBox(width: 4),
                        Text(
                          '第 ${pageIndex + 1} 页（续）',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFE07B54), fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          '本页小计：${currencyFmt.format(pageGifts.fold(0.0, (sum, g) => sum + g.amount))}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFE07B54)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                      border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.07))),
                    ),
                    child: Row(
                      children: [
                        _Cell('${globalIndex + 1}', width: 40, center: true, color: const Color(0xFFB8907A)),
                        _Cell(gift.giverName, flex: 2),
                        _Cell(_formatAmount(currencyFmt, gift), flex: 3),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                        border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.07))),
                      ),
                      child: Row(
                        children: const [
                          _Cell('', width: 40),
                          _Cell('', flex: 2),
                          _Cell('', flex: 3),
                          _Cell('', flex: 3),
                        ],
                      ),
                    );
                  }),

                // 页脚
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B54).withOpacity(0.03),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.1), width: 1),
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

          // 备注区域
          if (giftsWithNotes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B54).withOpacity(0.04),
                border: Border(top: BorderSide(color: const Color(0xFFE07B54).withOpacity(0.1), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.note_outlined, size: 12, color: Color(0xFFE07B54)),
                      SizedBox(width: 4),
                      Text(
                        '备注',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE07B54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...giftsWithNotes.map((gift) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
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
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
    if (hasMultiple <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart_outline, size: 12, color: Color(0xFFE07B54)),
          const SizedBox(width: 4),
          Text('支付方式', style: TextStyle(fontSize: 10, color: Colors.brown[400], fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          if (cashTotal > 0) _PaymentChip(label: '现金', amount: currencyFmt.format(cashTotal)),
          if (wechatTotal > 0) _PaymentChip(label: '微信', amount: currencyFmt.format(wechatTotal)),
          if (alipayTotal > 0) _PaymentChip(label: '支付宝', amount: currencyFmt.format(alipayTotal)),
          if (bankTotal > 0) _PaymentChip(label: '银行转账', amount: currencyFmt.format(bankTotal)),
        ],
      ),
    );
  }

  String _formatAmount(NumberFormat currencyFmt, GiftEntry gift) {
    if (gift.paymentMethod != '现金') {
      return '${currencyFmt.format(gift.amount)}（${gift.paymentMethod}）';
    }
    return currencyFmt.format(gift.amount);
  }

  double _sumByMethod(List<GiftEntry> gifts, String method) {
    return gifts.where((g) => g.paymentMethod == method).fold(0.0, (sum, g) => sum + g.amount);
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
      fontSize: 12,
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
    this.fontSize = 12,
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

class _PaymentChip extends StatelessWidget {
  final String label;
  final String amount;

  const _PaymentChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $amount',
        style: const TextStyle(fontSize: 10, color: Color(0xFF8B6347)),
      ),
    );
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
        Text(label, style: TextStyle(fontSize: 10, color: Colors.brown[400])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ─── 预览列表（与导出图片一致的布局）────────────────────────────────────────

class _PreviewList extends StatelessWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;

  const _PreviewList({required this.gifts, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final pageCount = (gifts.length / 12).ceil();

    return Column(
      children: [
        // 头部预览
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE07B54), Color(0xFFD4603C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '礼 金 本',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: '总笔数', value: '${gifts.length}'),
                  Container(width: 1, height: 28, color: Colors.white.withOpacity(0.3)),
                  _StatItem(label: '礼金总额', value: currencyFmt.format(totalAmount), valueColor: const Color(0xFFFFE066)),
                  Container(width: 1, height: 28, color: Colors.white.withOpacity(0.3)),
                  _StatItem(label: '记录页数', value: '$pageCount'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 表头
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE07B54).withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              _PHCell('序号', width: 40),
              _PHCell('姓名', flex: 2),
              _PHCell('金额', flex: 3),
              _PHCell('备注', flex: 3),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // 记录列表（只显示前12条作为预览）
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: List.generate(
                gifts.length.clamp(0, 12),
                (index) {
                  final gift = gifts[index];
                  final isEven = index % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFFAF7F2),
                      border: Border(
                        bottom: BorderSide(color: Colors.brown.withOpacity(0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _PCell('${index + 1}', width: 40, center: true, color: const Color(0xFFB8907A)),
                        _PCell(gift.giverName, flex: 2),
                        _PCell(_formatAmountPreview(currencyFmt, gift), flex: 3),
                        _PCell(gift.note ?? '', flex: 3, fontSize: 11, color: const Color(0xFF9E8B7D)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 支付方式汇总
        _buildSummary(currencyFmt),

        if (gifts.length > 12)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE07B54).withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFE07B54)),
                const SizedBox(width: 6),
                Text(
                  '共 ${gifts.length} 条记录，分 $pageCount 页导出',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE07B54)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(NumberFormat currencyFmt) {
    final cashTotal = _sumByMethod(gifts, '现金');
    final wechatTotal = _sumByMethod(gifts, '微信');
    final alipayTotal = _sumByMethod(gifts, '支付宝');

    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryCol(label: '总笔数', value: '${gifts.length}'),
              _SummaryCol(label: '礼金总额', value: currencyFmt.format(totalAmount), valueColor: const Color(0xFFE07B54)),
              _SummaryCol(label: '现金', value: currencyFmt.format(cashTotal)),
              _SummaryCol(label: '微信', value: currencyFmt.format(wechatTotal)),
              _SummaryCol(label: '支付宝', value: currencyFmt.format(alipayTotal)),
            ],
          ),
        );
  }

  String _formatAmountPreview(NumberFormat currencyFmt, GiftEntry gift) {
    if (gift.paymentMethod != '现金') {
      return '${currencyFmt.format(gift.amount)}（${gift.paymentMethod}）';
    }
    return currencyFmt.format(gift.amount);
  }

  double _sumByMethod(List<GiftEntry> gifts, String method) {
    return gifts.where((g) => g.paymentMethod == method).fold(0.0, (sum, g) => sum + g.amount);
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
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }
}

class _PHCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;

  const _PHCell(this.text, {this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontSize: 11,
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

class _PCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;
  final bool center;
  final double fontSize;
  final Color color;

  const _PCell(
    this.text, {
    this.width,
    this.flex,
    this.center = false,
    this.fontSize = 12,
    this.color = const Color(0xFF5C3D2E),
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, color: color);

    if (width != null) {
      return SizedBox(
        width: width,
        child: Text(text, textAlign: center ? TextAlign.center : TextAlign.start, style: style, overflow: TextOverflow.ellipsis),
      );
    }
    if (flex != null) {
      return Expanded(
        flex: flex!,
        child: Text(text, textAlign: center ? TextAlign.center : TextAlign.start, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
      );
    }
    return Text(text, style: style);
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryCol({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.brown[400])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF8B6347))),
      ],
    );
  }
}