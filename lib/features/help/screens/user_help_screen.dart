import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/support_ticket.dart';
import '../../../providers/support_provider.dart';

class UserHelpScreen extends StatefulWidget {
  const UserHelpScreen({super.key});

  @override
  State<UserHelpScreen> createState() => _UserHelpScreenState();
}

class _UserHelpScreenState extends State<UserHelpScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load FAQs and tickets from database
    final provider = context.read<SupportProvider>();
    provider.loadFAQs();
    provider.loadMyTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _ticketStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.info;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = context.watch<SupportProvider>();
    final faqCategories = supportProvider.faqCategories;
    final tickets = supportProvider.tickets;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Help Center',
          style: TextStyle(
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search - dark surface
            FadeSlideIn(
              index: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.glassWhite),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.userPagePadding,
                  0,
                  AppSpacing.userPagePadding,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: const Color(0xFF1400E0),
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            context.push('/shop/help/faq');
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search FAQs, articles, topics…',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF1400E0),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Quick Actions
            FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    _SectionGradientBar(),
                    SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.4,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ScaleOnTap(
                        onTap: () async {
                          final uri = Uri.parse('tel:');
                          try {
                            await launchUrl(uri);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Could not open dialer'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(AppSpacing.md),
                                ),
                              );
                            }
                          }
                        },
                        child: _buildQuickAction(
                          icon: Icons.phone_outlined,
                          label: 'Call Us',
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ScaleOnTap(
                        onTap: () async {
                          final uri = Uri.parse('mailto:');
                          try {
                            await launchUrl(uri);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Could not open email app'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(AppSpacing.md),
                                ),
                              );
                            }
                          }
                        },
                        child: _buildQuickAction(
                          icon: Icons.email_outlined,
                          label: 'Email Us',
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ScaleOnTap(
                        onTap: () => context.push('/shop/help/ticket'),
                        child: _buildQuickAction(
                          icon: Icons.support_agent_outlined,
                          label: 'Raise Ticket',
                          color: AppColors.userPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // FAQ Categories
            FadeSlideIn(
              index: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FAQ Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/shop/help/faq'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.userPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              index: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.userPagePadding,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: faqCategories.map((category) {
                    return ActionChip(
                      label: Text(category),
                      avatar: Icon(
                        _categoryIcon(category),
                        size: 18,
                        color: AppColors.userPrimary,
                      ),
                      onPressed: () => context.push('/shop/help/faq'),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.glassWhite),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // My Tickets
            if (tickets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionSpacing),
              FadeSlideIn(
                index: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.userPagePadding,
                  ),
                  child: const Text(
                    'My Tickets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...tickets.asMap().entries.map(
                    (entry) => FadeSlideIn(
                      index: 6 + entry.key,
                      child: _buildTicketCard(entry.value),
                    ),
                  ),
            ],

            const SizedBox(height: AppSpacing.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final statusColor = _ticketStatusColor(ticket.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.userPagePadding,
        0,
        AppSpacing.userPagePadding,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Ticket ${ticket.ticketNumber ?? '#${ticket.id.substring(0, 8)}'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                DateFormatter.format(ticket.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ticket.categoryLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('order')) return Icons.shopping_bag_outlined;
    if (lower.contains('payment')) return Icons.payment;
    if (lower.contains('deliver')) return Icons.local_shipping_outlined;
    if (lower.contains('return') || lower.contains('refund')) {
      return Icons.assignment_return_outlined;
    }
    if (lower.contains('account')) return Icons.person_outline;
    if (lower.contains('product')) return Icons.phone_android;
    return Icons.help_outline;
  }
}

class _SectionGradientBar extends StatelessWidget {
  const _SectionGradientBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 22,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1400E0), Color(0xFFA0D911)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}
