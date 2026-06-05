import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/address.dart';
import '../../../providers/user_profile_provider.dart';

class UserAddressesScreen extends StatelessWidget {
  const UserAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final addresses = profileProvider.addresses;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'My Addresses',
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
      body: addresses.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.userPagePadding),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                return FadeSlideIn(
                  index: index,
                  child: _buildAddressCard(context, addresses[index], profileProvider),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressDialog(context),
        backgroundColor: AppColors.userPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sectionSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.userPrimary.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 40,
                  color: AppColors.userPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No Addresses Saved',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Add a delivery address to get started',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    UserAddress address,
    UserProfileProvider provider,
  ) {
    return Dismissible(
      key: Key(address.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Address', style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('Are you sure you want to delete this address?',
                style: TextStyle(color: AppColors.textSecondary)),
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.removeAddress(address.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Address removed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: address.isDefault ? AppColors.userPrimary : AppColors.glassWhite,
            width: address.isDefault ? 1.5 : 1,
          ),
          boxShadow: address.isDefault
              ? [
                  BoxShadow(
                    color: AppColors.userPrimary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: address.isDefault
                          ? AppColors.userPrimary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      address.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: address.isDefault ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (address.isDefault) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    color: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      if (!address.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 8),
                              Text('Set as Default', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'default') {
                        provider.setDefaultAddress(address.id);
                      } else if (value == 'edit') {
                        _showAddressDialog(context, address: address);
                      } else if (value == 'delete') {
                        provider.removeAddress(address.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Address removed'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(AppSpacing.md),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Address details
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        address.phone,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
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

  void _showAddressDialog(BuildContext context, {UserAddress? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressFormSheet(address: address),
    );
  }
}

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
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
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
          content: Text(
            widget.address != null ? 'Address updated' : 'Address added',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.address != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Address' : 'Add New Address',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.glassWhite),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.userPagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label selector
                    const Text(
                      'Address Label',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: _labels.map((label) {
                        final selected = _selectedLabel == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedLabel = label),
                            selectedColor: AppColors.userPrimary,
                            backgroundColor: AppColors.surfaceVariant,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: selected ? AppColors.userPrimary : AppColors.glassWhite,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildField('Full Name', _fullNameController, Validators.name,
                        TextInputType.name),
                    _buildField('Phone Number', _phoneController, Validators.phone,
                        TextInputType.phone),
                    _buildField('Address Line 1', _addressLine1Controller,
                        Validators.address, TextInputType.streetAddress),
                    _buildField('Address Line 2 (Optional)', _addressLine2Controller,
                        null, TextInputType.streetAddress),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField('City', _cityController,
                              (v) => Validators.required(v, 'City'), TextInputType.text),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildField('State', _stateController,
                              (v) => Validators.required(v, 'State'), TextInputType.text),
                        ),
                      ],
                    ),
                    _buildField('Pincode', _pincodeController, Validators.pincode,
                        TextInputType.number),

                    // Default checkbox
                    CheckboxListTile(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v ?? false),
                      title: const Text(
                        'Set as default address',
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.userPrimary,
                      checkColor: Colors.white,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Save button - gold gradient
                    ScaleOnTap(
                      onTap: _isSaving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: PremiumDecorations.goldGlowButton(),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'Update Address' : 'Save Address',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.glassWhite),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.glassWhite),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.userPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
