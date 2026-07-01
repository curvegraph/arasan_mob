import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/address.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/user_order_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';
import '../../../shared/widgets/product_card_mini.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../orders/screens/user_orders_screen.dart';
import '../widgets/account_info_section.dart';

class UserAccountScreen extends StatefulWidget {
  final int initialTab;
  const UserAccountScreen({super.key, this.initialTab = 0});

  @override
  State<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  late int _selectedIndex = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return _buildLoginPrompt(context);
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildDesktopLayout(auth) : _buildMobileLayout(auth),
    );
  }

  // ─── Desktop: sidebar + detail panel ───
  Widget _buildDesktopLayout(AuthProvider auth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar
        SizedBox(
          width: 260,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(),
                const SizedBox(height: 8),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.6,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSidebarMenu(),
                const SizedBox(height: 24),
                _buildLogoutButton(auth),
              ],
            ),
          ),
        ),
        // Right detail panel
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildSelectedPanel(auth),
          ),
        ),
      ],
    );
  }

  // ─── Mobile: single column ───
  Widget _buildMobileLayout(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (auth.isDemoMode) _buildDemoBanner(),
          // No "Shopping > Account" breadcrumb — just the page title. Status-bar
          // inset added to the top padding since this screen has no app bar.
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.paddingOf(context).top + 16, 20, 0),
            child: const Text(
              'Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal tab bar for mobile
          _buildMobileTabBar(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildSelectedPanel(auth),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const AccountInfoSection(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildLogoutButton(auth),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/shop'),
          child: const Text(
            'Shopping',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<_SidebarItem> get _menuItems => [
        _SidebarItem(icon: Icons.person_outline, title: 'Profile'),
        _SidebarItem(icon: Icons.favorite_border, title: 'Wishlist'),
        _SidebarItem(icon: Icons.receipt_long_outlined, title: 'Orders'),
        _SidebarItem(icon: Icons.location_on_outlined, title: 'Addresses'),
        _SidebarItem(icon: Icons.rate_review_outlined, title: 'Reviews'),
      ];

  Widget _buildSidebarMenu() {
    return Column(
      children: List.generate(_menuItems.length, (index) {
        final item = _menuItems[index];
        final isSelected = _selectedIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1400E0).withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF1400E0)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? const Color(0xFF1400E0)
                        : const Color(0xFF334155),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMobileTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.title),
              selected: isSelected,
              // Wishlist and Orders render inline in the account page
              // (the _WishlistPanel / _OrdersPanel below) instead of pushing a
              // separate screen.
              onSelected: (_) => setState(() => _selectedIndex = index),
              selectedColor: const Color(0xFF1400E0).withValues(alpha: 0.10),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? const Color(0xFF1400E0)
                    : const Color(0xFF64748B),
                letterSpacing: 0.1,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF1400E0)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedPanel(AuthProvider auth) {
    switch (_selectedIndex) {
      case 0:
        return _MyDetailsPanel(auth: auth);
      case 1:
        return const _WishlistPanel();
      case 2:
        return const _OrdersPanel();
      case 3:
        return const _AddressesPanel();
      case 4:
        return const _MyReviewsPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.warning.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Demo Mode',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Some features are limited',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Are you sure you want to logout?',
                  style: TextStyle(color: AppColors.textSecondary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    auth.logout();
                    context.go('/shop');
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Log out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Arasan Mobiles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to view your orders, wishlist,\nand manage your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.push('/shop/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Login / Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => auth.loginAsDemo(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Demo Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            const AccountInfoSection(),
          ],
        ),
      ),
    );
  }
}

/// True for placeholder names the backend auto-fills for freshly-created
/// phone-auth customers ("Customer"). We treat these as "no real name yet"
/// and hide them in the UI until the user enters their own.
bool _isPlaceholderName(String? name) {
  final n = (name ?? '').trim().toLowerCase();
  return n.isEmpty || n == 'customer';
}

/// True for the synthetic email minted for phone-only sign-ins
/// (`phone-<digits>@phone.arasanmobiles.invalid`). Never a real address —
/// show nothing until the user enters their own.
bool _isPlaceholderEmail(String? email) {
  final e = (email ?? '').trim().toLowerCase();
  return e.isEmpty || e.endsWith('@phone.arasanmobiles.invalid');
}

String _realName(String? name) =>
    _isPlaceholderName(name) ? '' : name!.trim();

String _realEmail(String? email) =>
    _isPlaceholderEmail(email) ? '' : email!.trim();

/// Validates an email *if* one is supplied. Returns null (valid) on empty
/// input — phone-only signups never need a real email.
String? _optionalEmail(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return Validators.email(value);
}

// ─── My Details Panel (like the reference screenshot) ───
class _MyDetailsPanel extends StatefulWidget {
  final AuthProvider auth;
  const _MyDetailsPanel({required this.auth});

  @override
  State<_MyDetailsPanel> createState() => _MyDetailsPanelState();
}

class _MyDetailsPanelState extends State<_MyDetailsPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  String _gender = '';
  bool _isSaving = false;
  bool _isEditing = false;
  bool _editModeInitialized = false;
  UserProfileProvider? _profileProvider;

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProfileProvider>();
    final profile = provider.profile;
    final realName = _realName(profile.name);
    final nameParts = realName.isEmpty ? <String>[''] : realName.split(' ');
    _firstNameController = TextEditingController(text: nameParts.first);
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _emailController = TextEditingController(text: _realEmail(profile.email));
    _phoneController = TextEditingController(text: profile.phone);

    final addr = provider.defaultAddress;
    _addressLine1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _pincodeController = TextEditingController(text: addr?.pincode ?? '');

    // New users (no real saved name AND no saved address) start in edit
    // mode so they can immediately fill in their details. Returning users
    // start in read-only view mode — tap Edit to modify.
    _isEditing = _isPlaceholderName(profile.name) && addr == null;
    if (profile.id.isNotEmpty) {
      _editModeInitialized = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = context.read<UserProfileProvider>();
    if (_profileProvider != newProvider) {
      _profileProvider?.removeListener(_onProfileChanged);
      _profileProvider = newProvider;
      _profileProvider!.addListener(_onProfileChanged);
    }
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final provider = _profileProvider;
    if (provider == null) return;
    final profile = provider.profile;
    final addr = provider.defaultAddress;

    // On the first real profile load, decide whether to land in view or
    // edit mode based on whether the user already has saved data.
    if (!_editModeInitialized && profile.id.isNotEmpty) {
      setState(() {
        _isEditing = _isPlaceholderName(profile.name) && addr == null;
        _editModeInitialized = true;
      });
    }

    // While not actively editing, mirror the latest profile into the
    // form controllers so async loads and post-save reloads populate
    // the UI instead of leaving stale/empty fields.
    if (!_isEditing) {
      _syncControllersFromProfile(profile, addr);
    }
  }

  @override
  void dispose() {
    _profileProvider?.removeListener(_onProfileChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final phone = _phoneController.text.trim();
      final provider = context.read<UserProfileProvider>();

      final typedEmail = _emailController.text.trim();
      await provider.updateProfile(
        name: fullName,
        // Skip the field entirely when the user left it blank — we don't
        // want to overwrite the backend's synthetic phone-auth email with
        // an empty string.
        email: typedEmail.isEmpty ? null : typedEmail,
        phone: phone,
      );

      // Persist the default address if the user has filled in at least
      // the street + city + pincode. Other fields are required only when
      // a save is attempted.
      final line1 = _addressLine1Controller.text.trim();
      if (line1.isNotEmpty) {
        await provider.upsertDefaultAddress(
          fullName: fullName.isNotEmpty ? fullName : 'User',
          phone: phone,
          addressLine1: line1,
          addressLine2: _addressLine2Controller.text.trim().isEmpty
              ? null
              : _addressLine2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
        );
      }

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Saved successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _syncControllersFromProfile(UserProfile profile, UserAddress? addr) {
    final realName = _realName(profile.name);
    final parts = realName.isEmpty ? <String>[''] : realName.split(' ');
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_firstNameController, first);
    sync(_lastNameController, last);
    sync(_emailController, _realEmail(profile.email));
    sync(_phoneController, profile.phone);
    sync(_addressLine1Controller, addr?.addressLine1 ?? '');
    sync(_addressLine2Controller, addr?.addressLine2 ?? '');
    sync(_cityController, addr?.city ?? '');
    sync(_stateController, addr?.state ?? '');
    sync(_pincodeController, addr?.pincode ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProfileProvider>();
    final profile = provider.profile;
    final displayName = _realName(profile.name);
    final displayEmail = _realEmail(profile.email);
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    final addr = provider.defaultAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — title on the left, edit pencil on the right when
            // we're showing the read-only view.
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!_isEditing && _editModeInitialized)
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Avatar + Name row
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty ? displayName : 'Your name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: displayName.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (displayEmail.isNotEmpty)
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),

            if (!_isEditing) ...[
              _buildReadOnlyView(profile, addr),
            ] else if (isWide) ...[
              // Row 1: First name + Last name
              Row(
                children: [
                  Expanded(child: _buildField('First name', _firstNameController, validator: Validators.name)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField('Last name', _lastNameController)),
                ],
              ),
              const SizedBox(height: 20),
              // Row 2: Gender + Phone
              Row(
                children: [
                  Expanded(child: _buildGenderDropdown()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField('Phone number', _phoneController, keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 20),
              // Row 3: Email (full width)
              _buildField('Email address (optional)', _emailController, keyboardType: TextInputType.emailAddress, validator: _optionalEmail),
              const SizedBox(height: 28),
              _buildAddressHeader(),
              const SizedBox(height: 16),
              _buildField('Address line 1', _addressLine1Controller),
              const SizedBox(height: 20),
              _buildField('Address line 2 (optional)', _addressLine2Controller),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildField('City', _cityController)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField('State', _stateController)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField('Pincode', _pincodeController, keyboardType: TextInputType.number)),
                ],
              ),
            ] else ...[
              _buildField('First name', _firstNameController, validator: Validators.name),
              const SizedBox(height: 16),
              _buildField('Last name', _lastNameController),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),
              _buildField('Phone number', _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Email address (optional)', _emailController, keyboardType: TextInputType.emailAddress, validator: _optionalEmail),
              const SizedBox(height: 24),
              _buildAddressHeader(),
              const SizedBox(height: 12),
              _buildField('Address line 1', _addressLine1Controller),
              const SizedBox(height: 16),
              _buildField('Address line 2 (optional)', _addressLine2Controller),
              const SizedBox(height: 16),
              _buildField('City', _cityController),
              const SizedBox(height: 16),
              _buildField('State', _stateController),
              const SizedBox(height: 16),
              _buildField('Pincode', _pincodeController, keyboardType: TextInputType.number),
            ],

            if (_isEditing) ...[
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: isWide ? 220 : double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check, size: 18),
                    label: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: !_isEditing,
          style: TextStyle(
            fontSize: 15,
            color: _isEditing
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isEditing
                    ? AppColors.border
                    : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gender.isEmpty ? null : _gender,
          hint: const Text('Select', style: TextStyle(fontSize: 14)),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: _isEditing
              ? (val) => setState(() => _gender = val ?? '')
              : null,
          style: TextStyle(
            fontSize: 15,
            color: _isEditing
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressHeader() {
    return Row(
      children: const [
        Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
        SizedBox(width: 6),
        Text(
          'Default shipping address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyView(UserProfile profile, UserAddress? addr) {
    final realName = _realName(profile.name);
    final parts = realName.isEmpty ? <String>[''] : realName.split(' ');
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final addressLines = <String>[];
    if (addr != null) {
      addressLines.add(addr.addressLine1);
      if ((addr.addressLine2 ?? '').isNotEmpty) addressLines.add(addr.addressLine2!);
      addressLines.add('${addr.city}, ${addr.state} — ${addr.pincode}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readOnlyRow('First name', first),
        _readOnlyRow('Last name', last),
        _readOnlyRow('Gender', _gender),
        _readOnlyRow('Phone number', profile.phone),
        _readOnlyRow('Email address', _realEmail(profile.email)),
        const SizedBox(height: 20),
        _buildAddressHeader(),
        const SizedBox(height: 8),
        if (addressLines.isEmpty)
          _readOnlyRow('Address', '')
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              addressLines.join('\n'),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _readOnlyRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? '—' : value;
    final isEmpty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
                color: isEmpty ? AppColors.textTertiary : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String title;
  _SidebarItem({required this.icon, required this.title});
}


// ─── Wishlist Panel (product grid) ───
class _WishlistPanel extends StatelessWidget {
  const _WishlistPanel();

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final items = wishlistProvider.items;

    if (items.isEmpty) {
      return _buildEmptyPanel(
        icon: Icons.favorite_border,
        iconColor: AppColors.error,
        title: 'Your Wishlist is Empty',
        subtitle: 'Save items you love for later',
        buttonLabel: 'Start Shopping',
        onTap: () => context.go('/shop'),
      );
    }

    final productProvider = context.watch<ProductProvider>();

    // Kick off a background fetch for any wishlist row whose product isn't
    // cached yet; the grid rebuilds as products arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in items) {
        if (productProvider.getProductById(item.productId) == null) {
          productProvider.fetchProductById(item.productId);
        }
      }
    });

    final products = items
        .map((it) => productProvider.getProductById(it.productId))
        .whereType<Product>()
        .toList();

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Wishlist (${items.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.54,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                ProductCardMini(product: products[index]),
          ),
      ],
    );
  }
}

// ─── Orders Panel (inline) ───
class _OrdersPanel extends StatefulWidget {
  const _OrdersPanel();

  @override
  State<_OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<_OrdersPanel> {
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.authToken ?? 'guest';
      context.read<UserOrderProvider>().loadOrders(customerId);
    });
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFFF9800);
      case OrderStatus.confirmed: return const Color(0xFF2196F3);
      case OrderStatus.shipped: return const Color(0xFF7C4DFF);
      case OrderStatus.outForDelivery: return const Color(0xFF009688);
      case OrderStatus.delivered: return const Color(0xFF4CAF50);
      case OrderStatus.cancelled: return const Color(0xFFF44336);
      case OrderStatus.returned: return const Color(0xFF607D8B);
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cod': return 'Cash on Delivery';
      case 'upi': return 'UPI';
      case 'card': return 'Credit/Debit Card';
      default: return method.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();

    // If an order is selected, show detail inline
    if (_selectedOrderId != null) {
      final order = orderProvider.getOrderById(_selectedOrderId!);
      if (order != null) {
        return _buildOrderDetail(context, order, orderProvider);
      }
      // Order not found, go back to list
      _selectedOrderId = null;
    }

    return _buildOrdersList(context, orderProvider);
  }

  // ─── Orders List View — same product-card design as the standalone
  // My Orders page (UserOrdersScreen). Renders inline in the account page;
  // tapping a card opens the order detail page. ───
  Widget _buildOrdersList(BuildContext context, UserOrderProvider orderProvider) {
    if (orderProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (orderProvider.orders.isEmpty) {
      return _buildEmptyPanel(
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.userPrimary,
        title: orderProvider.statusFilter != null
            ? 'No ${orderProvider.statusFilter!.name} orders'
            : 'No Orders Yet',
        subtitle: 'Start shopping to see your orders here',
        buttonLabel: 'Browse Products',
        onTap: () => context.go('/shop'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final order in orderProvider.orders) OrderCard(order: order),
      ],
    );
  }

  // ─── Order Detail View (inline) ───
  Widget _buildOrderDetail(BuildContext context, Order order, UserOrderProvider orderProvider) {
    final statusColor = _statusColor(order.status);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back to orders
        GestureDetector(
          onTap: () => setState(() => _selectedOrderId = null),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Back to Orders', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Header: Order # + Status Badge
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Order #${order.orderNumber}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(order.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Placed on ${DateFormatter.formatWithTime(order.createdAt)}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Two-column on wide, single column on mobile
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _detailCard(Icons.person_outline, 'Customer Information', _buildCustomerInfo(order)),
                    const SizedBox(height: 14),
                    _detailCard(Icons.inventory_2_outlined, 'Product Details', _buildProductDetails(order)),
                    const SizedBox(height: 14),
                    _detailCard(Icons.local_shipping_outlined, 'Shipping Address', _buildShippingAddress(order)),
                    const SizedBox(height: 14),
                    _buildOrderActions(context, order, orderProvider),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _detailCard(Icons.timeline, 'Order Timeline', _buildTimeline(order, statusColor)),
                    const SizedBox(height: 14),
                    _detailCard(Icons.payment_outlined, 'Payment Info', _buildPaymentInfo(order)),
                    const SizedBox(height: 14),
                    _detailCard(Icons.receipt_outlined, 'Order Summary', _buildOrderSummary(order)),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _detailCard(Icons.person_outline, 'Customer Information', _buildCustomerInfo(order)),
              const SizedBox(height: 14),
              _detailCard(Icons.inventory_2_outlined, 'Product Details', _buildProductDetails(order)),
              const SizedBox(height: 14),
              _detailCard(Icons.timeline, 'Order Timeline', _buildTimeline(order, statusColor)),
              const SizedBox(height: 14),
              _detailCard(Icons.local_shipping_outlined, 'Shipping Address', _buildShippingAddress(order)),
              const SizedBox(height: 14),
              _detailCard(Icons.payment_outlined, 'Payment Info', _buildPaymentInfo(order)),
              const SizedBox(height: 14),
              _detailCard(Icons.receipt_outlined, 'Order Summary', _buildOrderSummary(order)),
              const SizedBox(height: 14),
              _buildOrderActions(context, order, orderProvider),
            ],
          ),
      ],
    );
  }

  Widget _detailCard(IconData icon, String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
    final initial = order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(initial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Text('Customer', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (order.customerEmail.isNotEmpty)
          _detailRow('Email:', order.customerEmail),
        const SizedBox(height: 4),
        _detailRow('Phone:', order.customerPhone),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 55, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildProductDetails(Order order) {
    return Column(
      children: order.items.map((item) {
        return Container(
          margin: EdgeInsets.only(bottom: order.items.last == item ? 0 : 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImagePlaceholder(imageUrl: item.imageUrl, width: 52, height: 52, icon: Icons.phone_android),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Quantity', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 4),
                        Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(width: 14),
                        Text('Unit Price', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(width: 4),
                        Text(CurrencyFormatter.format(item.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(CurrencyFormatter.format(item.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShippingAddress(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.shippingAddressLine1 != null && order.shippingAddressLine1!.isNotEmpty)
          Text(order.shippingAddressLine1!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
        if (order.shippingCity != null || order.shippingState != null || order.shippingPincode != null)
          Text(
            [order.shippingCity, order.shippingState, order.shippingPincode].where((e) => e != null && e.isNotEmpty).join(', '),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          )
        else
          Text(order.shippingAddress, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
      ],
    );
  }

  Widget _buildTimeline(Order order, Color statusColor) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final isReturned = order.status == OrderStatus.returned;

    List<_TimelineEntry> steps;
    if (isCancelled) {
      steps = [
        _TimelineEntry('Order Placed', order.createdAt, true),
        _TimelineEntry('Cancelled', order.cancelledAt, true),
      ];
    } else {
      steps = [
        _TimelineEntry('Order Placed', order.createdAt, true),
        _TimelineEntry('Processing', order.confirmedAt ?? (order.status.index >= OrderStatus.confirmed.index ? order.createdAt : null), order.status.index >= OrderStatus.confirmed.index),
        _TimelineEntry('Shipped', order.shippedAt, order.status.index >= OrderStatus.shipped.index),
        _TimelineEntry('Delivered', order.deliveredAt, order.status == OrderStatus.delivered || isReturned),
      ];
      if (isReturned) steps.add(_TimelineEntry('Returned', null, true));
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCancelStep = isCancelled && isLast;
        final dotColor = isCancelStep
            ? AppColors.error
            : step.isCompleted
                ? const Color(0xFF26C6A0)
                : AppColors.border;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: step.isCompleted ? dotColor.withValues(alpha: 0.2) : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: step.isCompleted ? Icon(Icons.check, size: 12, color: dotColor) : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          constraints: const BoxConstraints(minHeight: 24),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: step.isCompleted ? dotColor.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.label, style: TextStyle(fontSize: 13, fontWeight: step.isCompleted ? FontWeight.w700 : FontWeight.w500, color: step.isCompleted ? AppColors.textPrimary : AppColors.textHint)),
                      if (step.date != null)
                        Text(DateFormatter.formatWithTime(step.date!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                      else if (!step.isCompleted)
                        const Text('Pending', style: TextStyle(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPaymentInfo(Order order) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: order.isPaid ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.isPaid ? 'Paid' : 'Pending',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: order.isPaid ? AppColors.success : AppColors.warning),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.border, height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Method', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(_formatPaymentMethod(order.paymentMethod), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
        if (order.couponCode != null) ...[
          const Divider(color: AppColors.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Coupon', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(order.couponCode!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Column(
      children: [
        _summaryRow('Subtotal', CurrencyFormatter.format(order.subtotal)),
        const SizedBox(height: 8),
        _summaryRow('Delivery', order.deliveryCharge == 0 ? 'FREE' : CurrencyFormatter.format(order.deliveryCharge), valueColor: order.deliveryCharge == 0 ? AppColors.success : null),
        const SizedBox(height: 8),
        _summaryRow('Tax (GST)', CurrencyFormatter.format(order.taxAmount)),
        if (order.discountAmount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Discount', '-${CurrencyFormatter.format(order.discountAmount)}', valueColor: AppColors.success),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.border)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(CurrencyFormatter.format(order.totalAmount), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildOrderActions(BuildContext context, Order order, UserOrderProvider provider) {
    final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
    final isDelivered = order.status == OrderStatus.delivered;
    if (!canCancel && !isDelivered) return const SizedBox.shrink();

    return Column(
      children: [
        if (isDelivered) ...[
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                if (order.items.isNotEmpty) context.push('/shop/product/${order.items.first.productId}/write-review');
              },
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Write a Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Return/Refund feature coming soon'), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              label: const Text('Return / Refund', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
        if (canCancel) ...[
          if (isDelivered) const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context, order, provider),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Order', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog(BuildContext context, Order order, UserOrderProvider provider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withValues(alpha: 0.12))),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 20, color: AppColors.error),
                  SizedBox(width: 10),
                  Expanded(child: Text('Are you sure? This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.userPrimary)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty ? 'Customer requested cancellation' : reasonController.text.trim();
              provider.cancelOrder(order.id, reason);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Order cancelled'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

}

class _TimelineEntry {
  final String label;
  final DateTime? date;
  final bool isCompleted;
  _TimelineEntry(this.label, this.date, this.isCompleted);
}

// ─── Addresses Panel (inline) ───
class _AddressesPanel extends StatelessWidget {
  const _AddressesPanel();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final addresses = profileProvider.addresses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Addresses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddressDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.location_off_outlined, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('No Addresses Saved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Add a delivery address to get started', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...addresses.map((address) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: address.isDefault ? AppColors.primary : AppColors.border,
                  width: address.isDefault ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: address.isDefault ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          address.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: address.isDefault ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 10, color: AppColors.success),
                              SizedBox(width: 3),
                              Text('DEFAULT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                        color: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (_) => [
                          if (!address.isDefault)
                            const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                        onSelected: (value) {
                          if (value == 'default') {
                            profileProvider.setDefaultAddress(address.id);
                          } else if (value == 'edit') {
                            _showAddressDialog(context, address: address);
                          } else if (value == 'delete') {
                            profileProvider.removeAddress(address.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(address.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(address.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.formattedAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, {UserAddress? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressFormSheet(address: address),
    );
  }
}

// ─── Address Form Sheet (reused from addresses screen) ───
class _AddressFormSheet extends StatefulWidget {
  final UserAddress? address;
  const _AddressFormSheet({this.address});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;
  final _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _fullNameController = TextEditingController(text: a?.fullName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _addressLine1Controller = TextEditingController(text: a?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: a?.addressLine2 ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _stateController = TextEditingController(text: a?.state ?? '');
    _pincodeController = TextEditingController(text: a?.pincode ?? '');
    _selectedLabel = a?.label ?? 'Home';
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<UserProfileProvider>();
    final newAddress = UserAddress(
      id: widget.address?.id ?? 'ADDR${DateTime.now().millisecondsSinceEpoch}',
      label: _selectedLabel,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty ? null : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
    );
    if (widget.address != null) {
      await provider.updateAddress(newAddress);
    } else {
      await provider.addAddress(newAddress);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address != null ? 'Address updated' : 'Address added'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.address != null;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditing ? 'Edit Address' : 'Add New Address', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.glassWhite),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Address Label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      children: _labels.map((label) {
                        final selected = _selectedLabel == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedLabel = label),
                            selectedColor: AppColors.userPrimary,
                            backgroundColor: AppColors.surfaceVariant,
                            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500),
                            side: BorderSide(color: selected ? AppColors.userPrimary : AppColors.glassWhite),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _buildField('Full Name', _fullNameController, Validators.name, TextInputType.name),
                    _buildField('Phone Number', _phoneController, Validators.phone, TextInputType.phone),
                    _buildField('Address Line 1', _addressLine1Controller, Validators.address, TextInputType.streetAddress),
                    _buildField('Address Line 2 (Optional)', _addressLine2Controller, null, TextInputType.streetAddress),
                    Row(
                      children: [
                        Expanded(child: _buildField('City', _cityController, (v) => Validators.required(v, 'City'), TextInputType.text)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('State', _stateController, (v) => Validators.required(v, 'State'), TextInputType.text)),
                      ],
                    ),
                    _buildField('Pincode', _pincodeController, Validators.pincode, TextInputType.number),
                    CheckboxListTile(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v ?? false),
                      title: const Text('Set as default address', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.userPrimary,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isEditing ? 'Update Address' : 'Save Address', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String? Function(String?)? validator, TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.glassWhite)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.glassWhite)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.userPrimary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Shared empty panel builder ───
Widget _buildEmptyPanel({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required String buttonLabel,
  required VoidCallback onTap,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    ),
  );
}

// ─── My Reviews Panel ───
class _MyReviewsPanel extends StatefulWidget {
  const _MyReviewsPanel();

  @override
  State<_MyReviewsPanel> createState() => _MyReviewsPanelState();
}

class _MyReviewsPanelState extends State<_MyReviewsPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadMyReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final items = provider.myReviews;

    if (provider.isLoading && items.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              "You haven't written any reviews yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Reviews you write will appear here',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews (${items.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          ...items.map((item) => _buildItem(context, item, provider)),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, dynamic item, ReviewProvider provider) {
    final r = item.review;
    final isHidden = item.status == 'hidden' || item.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/shop/product/${r.productId}'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceVariant,
                    child: item.productImageUrl != null
                        ? Image.network(
                            item.productImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                color: AppColors.textHint),
                          )
                        : const Icon(Icons.phone_android,
                            color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingStars(rating: r.rating, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.format(r.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isHidden) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_off,
                      size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This review was hidden by moderation',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.5),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context
                    .go('/shop/product/${r.productId}/write-review'),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, item, provider),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic item,
      ReviewProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: Text('Your review of "${item.productName}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await provider.deleteReview(item.review.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Review deleted' : 'Failed to delete review'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}
