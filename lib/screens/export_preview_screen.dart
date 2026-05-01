import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/record.dart';
import '../theme/app_theme.dart';
import 'gift_book_painter.dart';

class ExportPreviewScreen extends StatelessWidget {
  final Event event;
  final List<Record> records;

  const ExportPreviewScreen({
    super.key,
    required this.event,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('导出预览'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: GiftBookPainter.computeSize(records.length),
                      painter: GiftBookPainter(event: event, records: records),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '共 ${records.length} 笔记录',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveImage(context),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('保存到相册'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareImage(context),
                          icon: const Icon(Icons.share),
                          label: const Text('分享图片'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    final painter = GiftBookPainter(event: event, records: records);
    await painter.shareImage(context);
  }

  Future<void> _saveImage(BuildContext context) async {
    final painter = GiftBookPainter(event: event, records: records);
    final success = await painter.saveToGallery(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已保存到相册' : '保存失败，请检查权限'),
          backgroundColor: success ? Colors.green[400] : Colors.red[400],
        ),
      );
    }
  }
}
