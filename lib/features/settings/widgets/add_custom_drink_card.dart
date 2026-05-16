import 'dart:typed_data';

import 'package:ddalgguk/features/settings/services/custom_drink_icon_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 아이콘 선택 다이얼로그의 반환값. asset 경로 또는 업로드된 이미지 바이트.
class _IconSelectionResult {
  const _IconSelectionResult.asset(this.assetPath) : uploadedBytes = null;
  const _IconSelectionResult.upload(this.uploadedBytes) : assetPath = null;

  final String? assetPath;
  final Uint8List? uploadedBytes;
}

class AddCustomDrinkCard extends ConsumerStatefulWidget {
  const AddCustomDrinkCard({required this.onAdd, super.key});

  final Function(Drink) onAdd;

  @override
  ConsumerState<AddCustomDrinkCard> createState() => _AddCustomDrinkCardState();
}

class _AddCustomDrinkCardState extends ConsumerState<AddCustomDrinkCard> {
  final _nameController = TextEditingController();
  final _alcoholContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedImagePath = 'assets/imgs/alcohol_icons/undecided.png';
  Uint8List? _pendingIconBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _alcoholContentController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final name = _nameController.text.trim();
      final alcoholContent =
          double.tryParse(_alcoholContentController.text.trim()) ?? 0.0;

      final id = DateTime.now().millisecondsSinceEpoch % 100000 + 1000;

      String imagePath = _selectedImagePath;
      final pending = _pendingIconBytes;
      if (pending != null) {
        await ref
            .read(customDrinkIconServiceProvider)
            .persist(id, pending);
        imagePath = customDrinkIconMarker(id);
      }

      final newDrink = Drink(
        id: id,
        name: name,
        imagePath: imagePath,
        defaultAlcoholContent: alcoholContent,
        defaultUnit: 'ml',
        glassVolume: 50.0,
        bottleVolume: 360.0,
      );

      widget.onAdd(newDrink);

      _nameController.clear();
      _alcoholContentController.clear();
      if (mounted) {
        setState(() {
          _selectedImagePath = 'assets/imgs/alcohol_icons/undecided.png';
          _pendingIconBytes = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleIconTap() async {
    final result = await showDialog<_IconSelectionResult>(
      context: context,
      builder: (context) => const _IconSelectionDialog(),
    );

    if (result == null) {
      return;
    }
    if (result.uploadedBytes != null) {
      setState(() {
        _pendingIconBytes = result.uploadedBytes;
        _selectedImagePath = 'assets/imgs/alcohol_icons/undecided.png';
      });
    } else if (result.assetPath != null) {
      setState(() {
        _selectedImagePath = result.assetPath!;
        _pendingIconBytes = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Centering spacer
                const Text(
                  '커스텀 주종 추가',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Body
            Row(
              children: [
                // Icon (with pencil badge)
                GestureDetector(
                  onTap: _handleIconTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _pendingIconBytes != null
                          ? Container(
                              width: 60,
                              height: 60,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.memory(
                                _pendingIconBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                _selectedImagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0A9A9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Inputs
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: '술 이름',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _alcoholContentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: '도수',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          suffixText: '%',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '도수를 입력해주세요';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return '유효한 숫자를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Footer (Actions)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSubmitting ? null : _handleAdd,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : const Text(
                          '추가',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSelectionDialog extends ConsumerStatefulWidget {
  const _IconSelectionDialog();

  @override
  ConsumerState<_IconSelectionDialog> createState() =>
      _IconSelectionDialogState();
}

class _IconSelectionDialogState extends ConsumerState<_IconSelectionDialog> {
  bool _isProcessing = false;

  Future<void> _handleUploadTap() async {
    if (_isProcessing) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (file == null) {
        return;
      }
      final raw = await file.readAsBytes();
      final processed = await ref
          .read(customDrinkIconServiceProvider)
          .processImageBytes(raw);
      if (!mounted || processed == null) {
        return;
      }
      Navigator.pop(context, _IconSelectionResult.upload(processed));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 처리할 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableIcons = drinks
        .where((d) => d.id >= 1)
        .map((d) => d.imagePath)
        .toSet()
        .toList();

    // 그리드 아이템 수 = 기본 아이콘 + 업로드 버튼 1.
    final itemCount = availableIcons.length + 1;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  '아이콘 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _isProcessing ? null : () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == availableIcons.length) {
                    // 업로드 버튼.
                    return GestureDetector(
                      onTap: _isProcessing ? null : _handleUploadTap,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF0A9A9),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF0A9A9),
                                  ),
                                )
                              : const Icon(
                                  Icons.add,
                                  color: Color(0xFFF0A9A9),
                                  size: 28,
                                ),
                        ),
                      ),
                    );
                  }
                  final path = availableIcons[index];
                  return GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => Navigator.pop(
                            context,
                            _IconSelectionResult.asset(path),
                          ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(path, fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
