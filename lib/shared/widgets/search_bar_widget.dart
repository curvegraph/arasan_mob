import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.obsidian,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.smoke, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.smoke),
          filled: true,
          fillColor: AppColors.mist,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(980),
            borderSide: const BorderSide(color: AppColors.steel),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(980),
            borderSide: const BorderSide(color: AppColors.steel),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(980),
            borderSide: const BorderSide(color: AppColors.accentBlue, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
      ),
    );
  }
}
