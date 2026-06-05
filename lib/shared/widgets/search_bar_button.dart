import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Tappable "search bar" placed below the header. It looks like a search input
/// but acts as a button — taps navigate to the dedicated /shop/search screen
/// where the real input + suggestion overlay lives.
class SearchBarButton extends StatelessWidget {
  const SearchBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => context.push('/shop/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search for products, brands and more',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
