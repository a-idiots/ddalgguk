import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

class AddCustomDrinkCard extends StatefulWidget {
  const AddCustomDrinkCard({required this.onAdd, super.key});

  final Function(Drink) onAdd;

  @override
  State<AddCustomDrinkCard> createState() => _AddCustomDrinkCardState();
}

class _AddCustomDrinkCardState extends State<AddCustomDrinkCard> {
  final _nameController = TextEditingController();
  final _alcoholContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedImagePath = 'assets/imgs/alcohol_icons/undecided.png';

  @override
  void dispose() {
    _nameController.dispose();
    _alcoholContentController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final alcoholContent =
          double.tryParse(_alcoholContentController.text.trim()) ?? 0.0;

      final id = DateTime.now().millisecondsSinceEpoch % 100000 + 1000;

      final newDrink = Drink(
        id: id,
        name: name,
        imagePath: _selectedImagePath,
        defaultAlcoholContent: alcoholContent,
        defaultUnit: 'ml',
        glassVolume: 50.0,
        bottleVolume: 360.0,
      );

      widget.onAdd(newDrink);

      // Clear fields
      _nameController.clear();
      _alcoholContentController.clear();
      setState(() {
        _selectedImagePath = 'assets/imgs/alcohol_icons/undecided.png';
      });
    }
  }

  Future<void> _handleIconTap() async {
    final selectedPath = await showDialog<String>(
      context: context,
      builder: (context) => const _IconSelectionDialog(),
    );

    if (selectedPath != null) {
      setState(() {
        _selectedImagePath = selectedPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        child: Row(
          children: [
            // Icon
            GestureDetector(
              onTap: _handleIconTap,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(_selectedImagePath, fit: BoxFit.contain),
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
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
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
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
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
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _handleAdd,
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
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

class _IconSelectionDialog extends StatelessWidget {
  const _IconSelectionDialog();

  @override
  Widget build(BuildContext context) {
    // Only standard drinks (ID >= 1) usually have valid icons we want to reuse
    final availableIcons = drinks
        .where((d) => d.id >= 1)
        .map((d) => d.imagePath)
        .toSet()
        .toList();

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
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: availableIcons.length,
                itemBuilder: (context, index) {
                  final path = availableIcons[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, path),
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
