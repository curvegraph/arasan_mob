import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/support_ticket.dart';
import '../data/services/api_service.dart';

/// Support tickets + FAQs, talking to the Node backend (`/api/support` and
/// `/api/faqs`). Auth comes from the same Supabase JWT we already hold; the
/// backend's `authenticateUser` middleware validates it on every call.
class SupportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SupabaseClient _client = Supabase.instance.client;

  List<SupportTicket> _tickets = [];
  List<FAQItem> _faqs = [];
  bool _isLoading = false;
  String? _error;

  List<SupportTicket> get tickets => _tickets;
  List<FAQItem> get faqs => _faqs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FAQItem> getFAQsByCategory(String category) {
    return _faqs.where((f) => f.category == category).toList();
  }

  List<String> get faqCategories {
    return _faqs.map((f) => f.category).toSet().toList();
  }

  List<FAQItem> searchFAQs(String query) {
    if (query.isEmpty) return _faqs;
    final lowerQuery = query.toLowerCase();
    return _faqs
        .where((f) =>
            f.question.toLowerCase().contains(lowerQuery) ||
            f.answer.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Load user's support tickets via backend HTTP.
  Future<void> loadMyTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/support/my', requireAuth: true);
      final list = (response is Map && response['tickets'] is List)
          ? response['tickets'] as List
          : (response is List ? response : <dynamic>[]);
      _tickets = list
          .map((row) => SupportTicket.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('[SupportProvider] loadMyTickets failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load FAQs from backend HTTP.
  Future<void> loadFAQs() async {
    try {
      final response = await _api.get('/faqs');
      final list = (response is Map && response['faqs'] is List)
          ? response['faqs'] as List
          : (response is List ? response : <dynamic>[]);
      _faqs = list
          .map((row) => FAQItem.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[SupportProvider] loadFAQs failed: $e');
    }
  }

  /// Raise a new support ticket via backend HTTP.
  Future<bool> raiseTicket({
    required String subject,
    required String description,
    required TicketCategory category,
    String? orderId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _error = 'Please sign in to raise a support ticket';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        '/support',
        body: {
          'subject': subject,
          'description': description,
          'category': _categoryToString(category),
          if (orderId != null) 'order_id': orderId,
        },
        requireAuth: true,
      );

      // Backend returns { ticket: {...} } inside the data envelope.
      final ticketJson = (response is Map && response['ticket'] is Map)
          ? Map<String, dynamic>.from(response['ticket'] as Map)
          : Map<String, dynamic>.from(response as Map);
      final ticket = SupportTicket.fromJson(ticketJson);

      _tickets = [ticket, ..._tickets];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to submit ticket: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get ticket by ID
  SupportTicket? getTicket(String ticketId) {
    try {
      return _tickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  String _categoryToString(TicketCategory category) {
    switch (category) {
      case TicketCategory.order:
        return 'order';
      case TicketCategory.payment:
        return 'payment';
      case TicketCategory.delivery:
        return 'delivery';
      case TicketCategory.product:
        return 'product';
      case TicketCategory.account:
        return 'account';
      case TicketCategory.other:
        return 'other';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
