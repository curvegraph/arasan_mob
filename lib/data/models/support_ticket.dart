enum TicketStatus { open, inProgress, resolved, closed }

enum TicketCategory { order, payment, delivery, product, account, other }

class SupportTicket {
  final String id;
  final String? ticketNumber;
  final String userId;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketStatus status;
  final String? orderId;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    this.ticketNumber,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    this.status = TicketStatus.open,
    this.orderId,
    this.adminResponse,
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String?,
      userId: json['customer_id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: _categoryFromString(json['category'] as String? ?? 'other'),
      status: _statusFromString(json['status'] as String? ?? 'open'),
      orderId: json['order_id'] as String?,
      adminResponse: json['admin_response'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      resolvedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': userId,
      'subject': subject,
      'description': description,
      'category': category.name,
      'order_id': orderId,
    };
  }

  static TicketCategory _categoryFromString(String value) {
    switch (value) {
      case 'order':
        return TicketCategory.order;
      case 'payment':
        return TicketCategory.payment;
      case 'delivery':
        return TicketCategory.delivery;
      case 'product':
        return TicketCategory.product;
      case 'account':
        return TicketCategory.account;
      default:
        return TicketCategory.other;
    }
  }

  static TicketStatus _statusFromString(String value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get categoryLabel {
    switch (category) {
      case TicketCategory.order:
        return 'Order Issue';
      case TicketCategory.payment:
        return 'Payment';
      case TicketCategory.delivery:
        return 'Delivery';
      case TicketCategory.product:
        return 'Product';
      case TicketCategory.account:
        return 'Account';
      case TicketCategory.other:
        return 'Other';
    }
  }
}

class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String? ?? 'General',
    );
  }
}
