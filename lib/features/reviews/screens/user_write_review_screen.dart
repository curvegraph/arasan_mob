import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/product.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';
import '../../../shared/widgets/rating_stars.dart';

class UserWriteReviewScreen extends StatefulWidget {
  final String productId;

  const UserWriteReviewScreen({super.key, required this.productId});

  @override
  State<UserWriteReviewScreen> createState() => _UserWriteReviewScreenState();
}

class _UserWriteReviewScreenState extends State<UserWriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  final List<Uint8List> _photoBytes = [];
  final List<String> _existingPhotoUrls = [];
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isLoadingExisting = true;
  String? _editingReviewId;
  String _eligibility = 'eligible';

  static const _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ReviewProvider>();
      final result = await provider.reviewEligibility(widget.productId);
      if (!mounted) return;

      if (result.status == 'already_reviewed' &&
          result.existingReviewId != null) {
        await provider.loadProductReviews(widget.productId);
        if (!mounted) return;
        final existing = provider.getUserReview(widget.productId);
        if (existing != null) {
          setState(() {
            _editingReviewId = existing.id;
            _rating = existing.rating;
            _commentController.text = existing.comment;
            _existingPhotoUrls.addAll(existing.photos);
          });
        }
      }
      setState(() {
        _eligibility = result.status;
        _isLoadingExisting = false;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _totalPhotos => _photoBytes.length + _existingPhotoUrls.length;

  Future<void> _pickPhotos() async {
    if (_totalPhotos >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can attach up to $_maxPhotos photos'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked.isEmpty) return;
      final remaining = _maxPhotos - _totalPhotos;
      final toAdd = picked.take(remaining);
      for (final x in toAdd) {
        final bytes = await x.readAsBytes();
        _photoBytes.add(bytes);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photos: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Excellent!';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    if (rating >= 1) return 'Poor';
    return 'Tap to rate';
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<ReviewProvider>();
      final success = _editingReviewId != null
          ? await provider.updateReview(
              reviewId: _editingReviewId!,
              rating: _rating,
              comment: _commentController.text.trim(),
              keepPhotos: _existingPhotoUrls,
              newPhotoBytes: _photoBytes,
            )
          : await provider.addReview(
              productId: widget.productId,
              rating: _rating,
              comment: _commentController.text.trim(),
              photoBytes: _photoBytes,
            );

      if (mounted) {
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<ReviewProvider>().error ?? 'Failed to submit review'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(AppSpacing.md),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Review submitted successfully!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(AppSpacing.md),
            ),
          );
          context.go('/shop/product/${widget.productId}/reviews');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit review. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Look up the product from provider
    final productProvider = context.watch<ProductProvider>();
    Product? product;
    try {
      product = productProvider.allProducts.firstWhere((p) => p.id == widget.productId);
    } catch (_) {
      product = null;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          _editingReviewId != null ? 'Edit Review' : 'Write a Review',
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
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator())
          : (_eligibility == 'not_purchased' && _editingReviewId == null)
              ? _buildNotEligible(product)
              : (_eligibility == 'not_signed_in' && _editingReviewId == null)
                  ? _buildNotSignedIn()
                  : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.userPagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product mini card
              if (product != null)
                FadeSlideIn(
                  index: 0,
                  child: _buildProductMiniCard(product),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Rating selector
              FadeSlideIn(
                index: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: PremiumDecorations.darkCard(borderRadius: 16),
                  child: Column(
                    children: [
                      const Text(
                        'How would you rate this product?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RatingStars(
                        rating: _rating,
                        size: 40,
                        interactive: true,
                        onRatingChanged: (value) => setState(() => _rating = value),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _ratingLabel(_rating),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _rating > 0
                              ? AppColors.userPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Review text
              FadeSlideIn(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write your review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write your review';
                        }
                        if (value.trim().length < 10) {
                          return 'Review must be at least 10 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Share your experience with this product. What did you like or dislike?',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        counterStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.glassWhite),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.glassWhite),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.userPrimary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Add photos button + thumbnails
              FadeSlideIn(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickPhotos,
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 20),
                      label: Text(
                        _totalPhotos == 0
                            ? 'Add Photos'
                            : 'Add Photos ($_totalPhotos/$_maxPhotos)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.userPrimary,
                        side: const BorderSide(color: AppColors.userPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_existingPhotoUrls.isNotEmpty ||
                        _photoBytes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingPhotoUrls.length +
                              _photoBytes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final isExisting = i < _existingPhotoUrls.length;
                            final newIndex = i - _existingPhotoUrls.length;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: isExisting
                                      ? Image.network(
                                          _existingPhotoUrls[i],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.memory(
                                          _photoBytes[newIndex],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: _isSubmitting
                                        ? null
                                        : () => setState(() {
                                              if (isExisting) {
                                                _existingPhotoUrls.removeAt(i);
                                              } else {
                                                _photoBytes.removeAt(newIndex);
                                              }
                                            }),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              FadeSlideIn(
                index: 4,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: _isSubmitting
                        ? null
                        : PremiumDecorations.goldGlowButton(borderRadius: 12),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.userPrimary.withValues(alpha: 0.3),
                        disabledForegroundColor: AppColors.textHint,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.userPrimary,
                              ),
                            )
                          : Text(
                              _editingReviewId != null
                                  ? 'Update Review'
                                  : 'Submit Review',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotEligible(Product? product) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (product != null) ...[
              _buildProductMiniCard(product),
              const SizedBox(height: AppSpacing.lg),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "You haven't received this product yet",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'You can write a review only after your order is delivered. '
                'This keeps reviews honest and trustworthy for other shoppers.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/shop/orders'),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('View My Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.userPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go(
                  '/shop/product/${widget.productId}/reviews'),
              child: const Text('See other reviews instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSignedIn() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Sign in to write a review',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductMiniCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImagePlaceholder(
              imageUrl: product.imageUrls.isNotEmpty
                  ? product.imageUrls.first
                  : null,
              width: 64,
              height: 64,
              icon: Icons.phone_android,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.effectivePrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.userPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
