import 'package:flutter/material.dart';
import 'package:caosbox/ui/widgets/caos_search_bar.dart';

/// Wrapper de compatibilidad: mismo API que usabas antes.
class SearchBarRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onOpenFilters;
  final VoidCallback? onExportData;
  final VoidCallback? onImportData;

  const SearchBarRow({
    super.key,
    required this.controller,
    this.hint = 'Buscar… (usa -palabra para excluir)',
    this.onOpenFilters,
    this.onExportData,
    this.onImportData,
  });

  @override
  Widget build(BuildContext context) {
    return CaosSearchBar(
      controller: controller,
      hint: hint,
      onOpenFilters: onOpenFilters,
      onExportData: onExportData,
      onImportData: onImportData,
    );
  }
}
