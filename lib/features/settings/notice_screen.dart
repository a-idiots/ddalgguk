import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Notice screen for displaying app announcements
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Notice> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/notices.json',
      );
      final data = json.decode(response) as Map<String, dynamic>;
      final noticesList = data['notices'] as List<dynamic>;

      setState(() {
        _notices = noticesList
            .map((notice) => Notice.fromJson(notice as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notices = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '공지사항',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
          ? const Center(
              child: Text(
                '공지사항이 없습니다',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _notices.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0E0E0),
              ),
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.content,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      if (notice.date != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          notice.date!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Notice model class
class Notice {
  Notice({required this.title, required this.content, this.date});

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      title: json['title'] as String,
      content: json['content'] as String,
      date: json['date'] as String?,
    );
  }

  final String title;
  final String content;
  final String? date;
}
