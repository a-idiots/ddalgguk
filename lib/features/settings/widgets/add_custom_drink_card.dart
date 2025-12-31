import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

class AddCustomDrinkCard extends StatefulWidget {
  const AddCustomDrinkCard({
    required this.onCancel,
    required this.onAdd,
    super.key,
  });

  final VoidCallback onCancel;
  final Function(Drink) onAdd;

  @override
  State<AddCustomDrinkCard> createState() => _AddCustomDrinkCardState();
}

class _AddCustomDrinkCardState extends State<AddCustomDrinkCard> {
  final _nameController = TextEditingController();
  final _alcoholContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

      // Custom drinks start ID from 1000 and increment based on timestamp to ensure uniqueness locally
      // A collision is extremely unlikely with millisecond timestamp + random or just service handling ID generation
      // Here we generate a simple ID based on timestamp
      final id = DateTime.now().millisecondsSinceEpoch % 100000 + 1000;

      final newDrink = Drink(
        id: id,
        name: name,
        imagePath:
            'assets/imgs/alcohol_icons/soju.png', // Default icon for now? Design shows a generic bottle icon
        defaultAlcoholContent: alcoholContent,
        defaultUnit: '잔',
        glassVolume: 50.0, // Default values
        bottleVolume: 360.0,
      );

      widget.onAdd(newDrink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // Using an icon that looks like the one in the design (a bottle with a question mark or generic)
                  // If we don't have that strict asset yet, use a placeholder icon
                  child: const Icon(
                    Icons.wine_bar,
                    color: Colors.black54,
                    size: 30,
                  ),
                  // Or using the image asset if available
                  // child: Image.asset('assets/imgs/alcohol_icons/undecided.png', width: 30),
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
                          borderSide: BorderSide(
                            color: Colors.grey,
                          ), // Lighter grey
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  // Add button is separate or part of the form flow?
                  // In the design, it seems the "Save" button is for the whole screen.
                  // But for this 'inline add', we need a way to commit "this" drink.
                  // The user requirement said: "이 버튼을 누르면 값이 추가되면서 위에 표시해줘" referring to the "Add" button triggering the input.
                  // So we likely need a "Check" or "Add" button inside this card or logic to add.
                  // Adding a small "Add" text button or Check icon.
                  TextButton(
                    onPressed: _handleAdd,
                    child: const Text(
                      '추가',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
