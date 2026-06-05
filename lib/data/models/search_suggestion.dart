enum SearchSuggestionType { recent, popular, product }

class SearchSuggestion {
  final String query;
  final String? productId;
  final SearchSuggestionType type;
  final String? imageUrl;

  SearchSuggestion({
    required this.query,
    this.productId,
    required this.type,
    this.imageUrl,
  });
}
