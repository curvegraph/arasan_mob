import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/search_suggestion.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/widgets/product_card_mini.dart';
import '../../../shared/widgets/image_placeholder.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _showSuggestions = true;
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _searchController.text = query;
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    context.read<SearchProvider>().search(query.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchProvider>().clearSearch();
    _focusNode.requestFocus();
    setState(() {
      _showSuggestions = true;
    });
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    if (suggestion.productId != null) {
      context.push('/shop/product/${suggestion.productId}');
    } else {
      _performSearch(suggestion.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final query = _searchController.text.trim();
    final suggestions = searchProvider.getSuggestions(query);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.go('/shop'),
        ),
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: _clearSearch,
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: _buildBody(searchProvider, query, suggestions),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
        ),
        cursorColor: const Color(0xFF1400E0),
        decoration: const InputDecoration(
          hintText: 'Search phones, accessories, brands…',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF1400E0),
            size: 22,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildBody(
    SearchProvider searchProvider,
    String query,
    List<SearchSuggestion> suggestions,
  ) {
    // Search results mode
    if (!_showSuggestions && searchProvider.query.isNotEmpty) {
      return _buildSearchResults(searchProvider);
    }

    // Typing suggestions mode
    if (query.isNotEmpty && suggestions.isNotEmpty && _showSuggestions) {
      return _buildSuggestionsList(suggestions);
    }

    // Idle: recent + popular searches
    return _buildIdleState(searchProvider);
  }

  // -------------------------------------------------------------------------
  // Idle state: Recent Searches + Popular Searches
  // -------------------------------------------------------------------------
  Widget _buildIdleState(SearchProvider searchProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (searchProvider.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => searchProvider.clearRecentSearches(),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: searchProvider.recentSearches.map((search) {
                return GestureDetector(
                  onTap: () => _performSearch(search.query),
                  child: Chip(
                    label: Text(
                      search.query,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    avatar: const Icon(
                      Icons.history,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    backgroundColor: AppColors.surfaceVariant,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: AppColors.textHint,
                    onDeleted: () =>
                        searchProvider.removeRecentSearch(search.query),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Popular Searches
          if (searchProvider.popularSearches.isNotEmpty) ...[
            const Text(
              'Popular Searches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: searchProvider.popularSearches.map((search) {
                return GestureDetector(
                  onTap: () => _performSearch(search.query),
                  child: Chip(
                    label: Text(
                      search.query,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    avatar: const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.surfaceVariant,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Suggestions list (while typing)
  // -------------------------------------------------------------------------
  Widget _buildSuggestionsList(List<SearchSuggestion> suggestions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: suggestion.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: ImagePlaceholder(
                    imageUrl: suggestion.imageUrl,
                    width: 40,
                    height: 40,
                    icon: Icons.phone_android,
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
          title: Text(
            suggestion.query,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(
            Icons.north_west,
            size: 16,
            color: AppColors.textHint,
          ),
          onTap: () => _onSuggestionTap(suggestion),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Search results
  // -------------------------------------------------------------------------
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!searchProvider.hasResults) {
      return _buildEmptyResults(searchProvider.query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Text(
            '${searchProvider.results.length} result${searchProvider.results.length == 1 ? '' : 's'} for "${searchProvider.query}"',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: searchProvider.results.length,
            itemBuilder: (context, index) {
              return ProductCardMini(
                product: searchProvider.results[index],
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Empty results
  // -------------------------------------------------------------------------
  Widget _buildEmptyResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results found for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Try searching with different keywords\nor check the spelling',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
