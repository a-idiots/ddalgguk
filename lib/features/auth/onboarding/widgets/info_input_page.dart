import 'package:flutter/material.dart';
import 'package:ddalgguk/features/auth/onboarding/widgets/saku_character.dart';
import 'package:ddalgguk/features/auth/onboarding/widgets/speech_bubble.dart';

/// Reusable info input page for name and ID entry
class InfoInputPage extends StatefulWidget {
  const InfoInputPage({
    super.key,
    required this.title,
    required this.speechBubbleText,
    required this.hintText,
    required this.onNext,
    required this.validator,
    this.initialValue,
    this.inputType = InfoInputType.name,
  });

  final String title;
  final String speechBubbleText;
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
  Offset? _cursorOffset;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    // Listen to cursor position changes
    _controller.addListener(_updateCursorPosition);
    _focusNode.addListener(_updateCursorPosition);
  }

  void _updateCursorPosition() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _cursorOffset = null;
      });
      return;
    }

    // Get cursor position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          // Find the text field's render box
          final textFieldContext = _textFieldKey.currentContext;
          if (textFieldContext != null) {
            final textFieldRenderBox =
                textFieldContext.findRenderObject() as RenderBox?;
            if (textFieldRenderBox != null) {
              final textFieldPosition = textFieldRenderBox.localToGlobal(
                Offset.zero,
              );

              // Calculate cursor position (approximate)
              final cursorX =
                  textFieldPosition.dx +
                  _controller.selection.baseOffset * 8.0; // Approximate
              final cursorY =
                  textFieldPosition.dy + textFieldRenderBox.size.height / 2;

              setState(() {
                _cursorOffset = Offset(cursorX, cursorY);
              });
            }
          }
        }
      } catch (e) {
        // Ignore errors during layout
      }
    });
  }

  void _handleNext() {
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Build InputField widget (reusable)
    Widget buildInputField() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: _textFieldKey,
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefix: Text(
                        '@',
                        style: TextStyle(
                          color: widget.inputType == InfoInputType.id ? Colors.black : Colors.black87,
                          fontSize: 16,
                        ),
                      )
                    ),
                    onSubmitted: (_) => _handleNext(),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleNext,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black87,
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
                        color: Colors.white,
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
      child: Transform.translate(
        offset: Offset(0, -keyboardHeight * 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 85),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              SpeechBubble(text: widget.speechBubbleText),
              const SizedBox(height: 20),
              SakuCharacter(cursorOffset: _cursorOffset, size: 120),
              const SizedBox(height: 40),
              buildInputField(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// Input type for validation
enum InfoInputType { name, id }
