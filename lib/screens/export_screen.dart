import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import '../models/gift_entry.dart';

/// 导出列配置
class ExportColumnConfig {
  final bool showIndex;
  final bool showName;
  final bool showAmount;
  final bool showNote;
  final bool paymentAsSeparateColumn; // 支付方式作为单独列显示

  const ExportColumnConfig({
    this.showIndex = true,
    this.showName = true,
    this.showAmount = true,
    this.showNote = true,
    this.paymentAsSeparateColumn = false,
  });

  ExportColumnConfig copyWith({
    bool? showIndex,
    bool? showName,
    bool? showAmount,
    bool? showNote,
    bool? paymentAsSeparateColumn,
  }) {
    return ExportColumnConfig(
      showIndex: showIndex ?? this.showIndex,
      showName: showName ?? this.showName,
      showAmount: showAmount ?? this.showAmount,
      showNote: showNote ?? this.showNote,
      paymentAsSeparateColumn: paymentAsSeparateColumn ?? this.paymentAsSeparateColumn,
    );
  }
}

class ExportGiftBookScreen extends StatefulWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;
  final int recordsPerPage;

  const ExportGiftBookScreen({
    super.key,
    required this.gifts,
    required this.totalAmount,
    this.recordsPerPage = 14,
  });

  @override
  State<ExportGiftBookScreen> createState() => _ExportGiftBookScreenState();
}

class _ExportGiftBookScreenState extends State<ExportGiftBookScreen> {
  final GlobalKey _screenRepaintKey = GlobalKey();
  ExportColumnConfig _columnConfig = const ExportColumnConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('导出礼金本'),
        backgroundColor: const Color(0xFFE07B54),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '配置列',
            onPressed: _showColumnConfigSheet,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (ctx, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscapeBody();
          }
          return _buildPortraitBody();
        },
      ),
    );
  }

  void _showColumnConfigSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '导出列配置',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5C3D2E)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile('序号', _columnConfig.showIndex, (v) {
                    setSheetState(() => _columnConfig = _columnConfig.copyWith(showIndex: v));
                    setState(() {});
                  }),
                  _buildSwitchTile('姓名', _columnConfig.showName, (v) {
                    setSheetState(() => _columnConfig = _columnConfig.copyWith(showName: v));
                    setState(() {});
                  }),
                  _buildSwitchTile('金额', _columnConfig.showAmount, (v) {
                    setSheetState(() => _columnConfig = _columnConfig.copyWith(showAmount: v));
                    setState(() {});
                  }),
                  _buildSwitchTile('备注', _columnConfig.showNote, (v) {
                    setSheetState(() => _columnConfig = _columnConfig.copyWith(showNote: v));
                    setState(() {});
                  }),
                  const Divider(height: 24),
                  _buildSwitchTile('支付方式单独列', _columnConfig.paymentAsSeparateColumn, (v) {
                    setSheetState(() => _columnConfig = _columnConfig.copyWith(paymentAsSeparateColumn: v));
                    setState(() {});
                  }, subtitle: '关闭时支付方式显示在金额后括号内'),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF5C3D2E))),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.brown[300])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFE07B54),
          ),
        ],
      ),
    );
  }

  // 竖屏：上下滚动，宽度不限制
  Widget _buildPortraitBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _PreviewCard(
              gifts: widget.gifts,
              totalAmount: widget.totalAmount,
              recordsPerPage: widget.recordsPerPage,
              repaintKey: _screenRepaintKey,
              columnConfig: _columnConfig,
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  // 横屏：横向滚动，高度限制为屏幕高度，宽度按内容
  Widget _buildLandscapeBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _PreviewCard(
                gifts: widget.gifts,
                totalAmount: widget.totalAmount,
                recordsPerPage: widget.recordsPerPage,
                repaintKey: _screenRepaintKey,
                columnConfig: _columnConfig,
              ),
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _shareImage(context, _screenRepaintKey),
          icon: const Icon(Icons.save_alt),
          label: const Text('保存到相册'),
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
    );
  }

  Future<void> _shareImage(BuildContext context, GlobalKey repaintKey) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成礼金本图片...'), duration: Duration(seconds: 2)),
    );

    try {
      // 等待一帧，确保 widget 完全渲染
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('无法获取渲染边界');

      // 分辨率提高到 4.0
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图片转换失败');

      final result = await ImageGallerySaverPlus.saveImage(
        byteData.buffer.asUint8List(),
        quality: 100,
        name: '礼簿_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (context.mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存到相册'), duration: Duration(seconds: 2)),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: ${result['errorMessage']}'), duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }
}

// ─── 预览卡片（与导出图片完全一致的布局）────────────────────────────────────

class _PreviewCard extends StatefulWidget {
  final List<GiftEntry> gifts;
  final double totalAmount;
  final int recordsPerPage;
  final GlobalKey repaintKey;
  final ExportColumnConfig columnConfig;

  const _PreviewCard({
    required this.gifts,
    required this.totalAmount,
    this.recordsPerPage = 14,
    required this.repaintKey,
    required this.columnConfig,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy年MM月dd日');
    final pageCount = (widget.gifts.length / widget.recordsPerPage).ceil();

    return RepaintBoundary(
      key: widget.repaintKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFFAF7F2),
        child: Column(
          children: [
            // 头部
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
                          dateFmt.format(DateTime.now()),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('总笔数', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text('${widget.gifts.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.3)),
                      Column(
                        children: [
                          Text('礼金总额', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(widget.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFE066))),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.3)),
                      Column(
                        children: [
                          Text('现金', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(_sumByMethod(widget.gifts, '现金')), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.3)),
                      Column(
                        children: [
                          Text('微信', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 2),
                          Text(currencyFmt.format(_sumByMethod(widget.gifts, '微信')), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B54).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (widget.columnConfig.showIndex) _PHCell('序号', width: 40),
                  if (widget.columnConfig.showName) _PHCell('姓名', flex: 2),
                  if (widget.columnConfig.showAmount)
                    if (widget.columnConfig.paymentAsSeparateColumn) ...[
                      _PHCell('金额', flex: 3),
                      _PHCell('支付', width: 50),
                    ] else
                      _PHCell('金额', flex: 4),
                  if (widget.columnConfig.showNote) _PHCell('备注', flex: 2),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 全部记录（按页分组，与导出图片完全一致）
            ...List.generate(pageCount, (pageIndex) {
              final startIdx = pageIndex * widget.recordsPerPage;
              final endIdx = (startIdx + widget.recordsPerPage).clamp(0, widget.gifts.length);
              final pageGifts = widget.gifts.sublist(startIdx, endIdx);

              return Column(
                children: [
                  // 记录列表
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: pageIndex == 0 ? const Radius.circular(10) : Radius.zero,
                        bottom: pageIndex == pageCount - 1 ? const Radius.circular(10) : const Radius.circular(0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: pageIndex == 0 ? const Radius.circular(10) : Radius.zero,
                        bottom: pageIndex == pageCount - 1 ? const Radius.circular(10) : Radius.zero,
                      ),
                      child: Column(
                        children: pageGifts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final gift = entry.value;
                          final globalIndex = startIdx + index;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.06))),
                            ),
                            child: Row(
                              children: [
                                if (widget.columnConfig.showIndex)
                                  _PCell('${globalIndex + 1}', width: 40, center: true, color: const Color(0xFFB8907A)),
                                if (widget.columnConfig.showName) _PCell(gift.giverName, flex: 2),
                                if (widget.columnConfig.showAmount)
                                  if (widget.columnConfig.paymentAsSeparateColumn)
                                    _PCell('¥${gift.amountDisplay}', flex: 3)
                                  else
                                    _PCell(_formatAmount(currencyFmt, gift), flex: 4),
                                if (widget.columnConfig.showNote) _PCell(gift.note ?? '', flex: 2, fontSize: 11, color: const Color(0xFF9E8B7D)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // 页脚
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07B54).withOpacity(0.03),
                      borderRadius: BorderRadius.vertical(
                        bottom: pageIndex == pageCount - 1 ? const Radius.circular(10) : Radius.zero,
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

                  const SizedBox(height: 8),
                ],
              );
            }),

          ],
        ),
      ),
    );
  }

  String _formatAmount(NumberFormat currencyFmt, GiftEntry gift) {
    // 使用截断不四舍五入的 display 格式
    final display = gift.amountDisplay;
    if (gift.paymentMethod != '现金') {
      return '¥$display（${gift.paymentMethod}）';
    }
    return '¥$display';
  }

  double _sumByMethod(List<GiftEntry> gifts, String method) {
    return gifts.where((g) => g.paymentMethod == method).fold(0.0, (sum, g) => sum + g.amount);
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
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.center,
          style: style,
        ),
      );
    }
    if (flex != null) {
      return Flexible(
        fit: FlexFit.loose,
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.center,
          style: style,
        ),
      );
    }
    return Text(text, textAlign: TextAlign.center, style: style);
  }
}
