import 'package:flutter/material.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categories = const ['All', 'Spice', 'Food', 'Raw Material', 'Electronics', 'Chemical'],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search product name, SKU/code, barcode, brand...',
            prefixIcon: const Icon(Icons.search, color: Colors.orange),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.orange.withValues(alpha: 0.2),
                  onSelected: (_) => onCategorySelected(cat),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade900 : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
