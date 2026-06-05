import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/address.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../auth/login_dialog.dart';

/// Indian states list for dropdown
const _indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Delhi',
  'Jammu & Kashmir',
  'Ladakh',
  'Puducherry',
  'Chandigarh',
  'Andaman & Nicobar Islands',
  'Dadra & Nagar Haveli and Daman & Diu',
  'Lakshadweep',
];

/// Address selection step — shows saved addresses or an address entry form.
class AddressSelection extends StatefulWidget {
  const AddressSelection({super.key});

  @override
  State<AddressSelection> createState() => _AddressSelectionState();
}

class _AddressSelectionState extends State<AddressSelection> {
  bool _showForm = false;
  String? _editingAddressId;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _selectedLabel = 'Home';
  String? _selectedState;
  bool _isDefault = true;

  @override
  void initState() {
    super.initState();
    // Load addresses from Supabase via UserProfileProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<UserProfileProvider>();
      if (!profileProvider.isInitialized) {
        profileProvider.loadAddresses();
      }
      // Show form if no addresses
      final addresses = profileProvider.addresses;
      if (addresses.isEmpty) {
        setState(() => _showForm = true);
      } else {
        // Auto-select default address if none selected
        final checkoutProvider = context.read<CheckoutProvider>();
        if (checkoutProvider.selectedAddress == null) {
          final defaultAddr = profileProvider.defaultAddress;
          if (defaultAddr != null) {
            checkoutProvider.setAddress(defaultAddr);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _pincodeController.clear();
    _selectedLabel = 'Home';
    _selectedState = null;
    _isDefault = true;
    _editingAddressId = null;
  }

  void _editAddress(UserAddress address) {
    _editingAddressId = address.id;
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phone.replaceFirst('+91 ', '');
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _cityController.text = address.city;
    _selectedState = address.state;
    _pincodeController.text = address.pincode;
    _selectedLabel = address.label;
    _isDefault = address.isDefault;
    setState(() => _showForm = true);
  }

  Future<void> _deleteAddress(String addressId) async {
    final profileProvider = context.read<UserProfileProvider>();
    final checkoutProvider = context.read<CheckoutProvider>();

    try {
      await profileProvider.removeAddress(addressId);

      // Update checkout selected address if deleted
      if (checkoutProvider.selectedAddress?.id == addressId) {
        final defaultAddr = profileProvider.defaultAddress;
        if (defaultAddr != null) {
          checkoutProvider.setAddress(defaultAddr);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Address deleted'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete address: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a state'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Check if user is logged in - show login dialog if not
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      final loggedIn = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LoginDialog(),
      );
      if (loggedIn != true) {
        return; // User cancelled login
      }
      // Wait for profile provider to load after login
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    final phone = '+91 ${_phoneController.text.trim()}';

    final newAddress = UserAddress(
      id: _editingAddressId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      label: _selectedLabel,
      fullName: _fullNameController.text.trim(),
      phone: phone,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _selectedState!,
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
    );

    final profileProvider = context.read<UserProfileProvider>();
    final checkoutProvider = context.read<CheckoutProvider>();

    try {
      if (_editingAddressId != null) {
        await profileProvider.updateAddress(newAddress);
      } else {
        await profileProvider.addAddress(newAddress);
      }

      // Select the saved address for checkout
      // Use the latest address from profile (has correct ID from Supabase)
      final savedAddr = profileProvider.addresses.firstWhere(
        (a) => a.addressLine1 == newAddress.addressLine1 && a.phone == newAddress.phone,
        orElse: () => newAddress,
      );
      checkoutProvider.setAddress(savedAddr);

      _clearForm();
      if (mounted) {
        setState(() {
          _showForm = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingAddressId != null
                ? 'Address updated'
                : 'Address saved successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = context.watch<CheckoutProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final addresses = profileProvider.addresses;
    final selectedAddress = checkoutProvider.selectedAddress;

    // Show loading indicator while loading addresses
    if (profileProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            _SectionGradientBar(),
            SizedBox(width: 12),
            Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Where should we deliver your order?',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Saved addresses
        if (addresses.isNotEmpty && !_showForm) ...[
          ...addresses.map((address) => _AddressCard(
                address: address,
                isSelected: selectedAddress?.id == address.id,
                onSelect: () => checkoutProvider.setAddress(address),
                onEdit: () => _editAddress(address),
                onDelete: () => _deleteAddress(address.id),
              )),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _clearForm();
                setState(() => _showForm = true);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],

        // Address form
        if (_showForm) ...[
          if (addresses.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _clearForm();
                  setState(() => _showForm = false);
                },
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          _buildAddressForm(),
        ],
      ],
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address type selector
            const Text(
              'Address Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: ['Home', 'Office', 'Other'].map((label) {
                final isSelected = _selectedLabel == label;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLabel = label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusRound),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Full Name
            _FormField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),

            const SizedBox(height: AppSpacing.md),

            // Phone Number with +91 prefix
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    if (v.trim().length < 10) {
                      return 'Enter valid 10-digit phone number';
                    }
                    return null;
                  },
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary),
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: '10-digit mobile number',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    counterText: '',
                    prefixIcon: Container(
                      width: 72,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 12),
                          Icon(Icons.phone_outlined,
                              size: 20, color: AppColors.textHint),
                          SizedBox(width: 6),
                          Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Address Line 1
            _FormField(
              controller: _addressLine1Controller,
              label: 'Address Line 1',
              hint: 'House no, Building, Street',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),

            const SizedBox(height: AppSpacing.md),

            // Address Line 2
            _FormField(
              controller: _addressLine2Controller,
              label: 'Address Line 2 (Optional)',
              hint: 'Landmark, Area',
              icon: Icons.near_me_outlined,
            ),

            const SizedBox(height: AppSpacing.md),

            // City & State row
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'City',
                    icon: Icons.location_city_outlined,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'City is required'
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'State',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        isExpanded: true,
                        hint: const Text(
                          'Select State',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.error),
                          ),
                        ),
                        validator: (v) =>
                            v == null ? 'State is required' : null,
                        items: _indianStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(
                              state,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedState = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Pincode
            _FormField(
              controller: _pincodeController,
              label: 'Pincode',
              hint: '6-digit pincode',
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Pincode is required';
                }
                if (v.trim().length != 6) return 'Enter valid 6-digit pincode';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Default toggle
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _isDefault,
                    onChanged: (v) =>
                        setState(() => _isDefault = v ?? true),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Set as default address',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save Address button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _editingAddressId != null
                            ? 'Update Address'
                            : 'Save Address',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual form field with icon, label, and validation.
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Saved address card with selection radio, edit and delete buttons.
class _AddressCard extends StatelessWidget {
  final UserAddress address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label badges + action buttons
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          address.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Edit button
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete button
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    address.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.formattedAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionGradientBar extends StatelessWidget {
  const _SectionGradientBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 24,
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
