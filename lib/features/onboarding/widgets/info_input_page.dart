import 'package:flutter/material.dart';

/// Reusable info input page for name and ID entry
class InfoInputPage extends StatefulWidget {
  const InfoInputPage({
    super.key,
    required this.title,
    required this.hintText,
    required this.onNext,
    required this.validator,
    this.initialValue,
    this.inputType = InfoInputType.name,
  });

  final String title;
  final String hintText;
  final ValueChanged<String> onNext;
  final String? Function(String?) validator;
  final String? initialValue;
  final InfoInputType inputType;

  @override
  State<InfoInputPage> createState() => _InfoInputPageState();
}

class _InfoInputPageState extends State<InfoInputPage> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  void _handleNext() {
    // 키보드 내림
    FocusScope.of(context).unfocus();

    final error = widget.validator(_controller.text);
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _errorText = null;
    });
    widget.onNext(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  final GlobalKey _textFieldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Build InputField widget (reusable)
    Widget buildInputField() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFE35252)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE35252).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // -----------------------
                // 1) 항상 고정된 '@' prefix
                // -----------------------
                if (widget.inputType == InfoInputType.id)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      '@',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),

                // -----------------------
                // 2) TextField (padding 복원)
                // -----------------------
                Expanded(
                  child: TextField(
                    key: _textFieldKey,
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _focusNode.unfocus(),
                    onEditingComplete: () => _focusNode.unfocus(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,

                      // 🔥 placeholder가 너무 왼쪽에 붙지 않도록 padding 삽입
                      // prefix 바로 옆에서 시작하되 내부 여백은 유지
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: widget.inputType == InfoInputType.id
                            ? 0
                            : 24,
                        vertical: 12,
                      ),

                      hintText: widget.hintText,
                      hintStyle: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),

                // NEXT 버튼
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleNext,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF7E7E7E),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: _errorText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 20, top: 4),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFE35252),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input field
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 120),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            buildInputField(),
          ],
        ),
      ),
    );
  }
}

/// Input type for validation
enum InfoInputType { name, id }
