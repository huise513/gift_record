import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/record.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_header.dart';
import '../widgets/record_list_tile.dart';
import '../widgets/add_record_dialog.dart';
import 'export_preview_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  List<Record> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final event = await DbService.getEvent(widget.eventId);
    final records = await DbService.getRecordsForEvent(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _addRecord() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const AddRecordDialog(),
    );
    if (result != null) {
      final record = Record(
        eventId: widget.eventId,
        guestName: result['name'] as String,
        amount: result['amountFen'] as int,
      );
      await DbService.insertRecord(record);
      _loadData();
    }
  }

  Future<void> _deleteRecord(Record record) async {
    await DbService.deleteRecord(record.id!, widget.eventId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('礼金详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('礼金详情')),
        body: const Center(child: Text('宴席不存在')),
      );
    }

    final event = _event!;
    final currencyFmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final dateFmt = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(event.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '导出礼金本图片',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExportPreviewScreen(event: event, records: _records),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          SummaryHeader(
            totalAmountFen: event.totalAmount,
            guestCount: event.guestCount,
          ),

          // Type & date chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.type == EventType.wedding ? '囍 婚宴' : '寿 寿宴',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(event.date),
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '序号',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '来宾姓名',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const Spacer(),
                Text(
                  '礼金',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Record list
          Expanded(
            child: _records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无礼金记录',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击右下角"记礼金"添加',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _records.length,
                    itemBuilder: (ctx, index) {
                      return RecordListTile(
                        index: index,
                        record: _records[index],
                        onDelete: () => _deleteRecord(_records[index]),
                      );
                    },
                  ),
          ),

          // Export button
          if (_records.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExportPreviewScreen(event: event, records: _records),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('导出礼金本图片'),
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
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
