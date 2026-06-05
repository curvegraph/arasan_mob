import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/support_ticket.dart';
import '../../../providers/support_provider.dart';

class UserFAQScreen extends StatefulWidget {
  const UserFAQScreen({super.key});

  @override
  State<UserFAQScreen> createState() => _UserFAQScreenState();
}

class _UserFAQScreenState extends State<UserFAQScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Load FAQs from database if not already loaded
    final provider = context.read<SupportProvider>();
    if (provider.faqs.isEmpty) {
      provider.loadFAQs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = context.watch<SupportProvider>();
    final categories = supportProvider.faqCategories;

    List<FAQItem> faqs;
    if (_searchQuery.isNotEmpty) {
      faqs = supportProvider.searchFAQs(_searchQuery);
    } else if (_selectedCategory != null) {
      faqs = supportProvider.getFAQsByCategory(_selectedCategory!);
    } else {
      faqs = supportProvider.faqs;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          _selectedCategory ?? 'FAQ',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search bar - dark surface
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.userPagePadding,
              AppSpacing.sm,
              AppSpacing.userPagePadding,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassWhite),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassWhite),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.userPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Category filters (only when not searching)
          if (_searchQuery.isEmpty)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Row(
                  children: [
                    _buildCategoryChip('All', null),
                    ...categories.map((c) => _buildCategoryChip(c, c)),
                  ],
                ),
              ),
            ),

          // FAQ list
          Expanded(
            child: faqs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.userPagePadding),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return FadeSlideIn(
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: PremiumDecorations.darkCard(borderRadius: 12),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.userPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: AppColors.userPrimary,
                                ),
                              ),
                              title: Text(
                                faq.question,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              iconColor: AppColors.userPrimary,
                              collapsedIconColor: AppColors.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              children: [
                                Divider(height: 1, color: AppColors.glassWhite),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  faq.answer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      faq.category,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.userPrimary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.userPrimary : AppColors.glassWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeSlideIn(
        index: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No FAQs available',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Try different keywords or browse categories',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
