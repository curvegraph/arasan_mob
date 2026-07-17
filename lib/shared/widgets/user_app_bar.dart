import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/screens/login_dialog.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/search_provider.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showBack;
  final String? title;

  const UserAppBar({
    super.key,
    this.showSearch = true,
    this.showBack = false,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);
  // Actual rendered height adapts (60 on mobile, 70 on desktop) inside
  // _HeaderBar — this preferredSize is only consulted when UserAppBar is
  // used as a PreferredSizeWidget (legacy callers).

  @override
  Widget build(BuildContext context) {
    return const _HeaderBar();
  }
}

/// Modern header with logo, search, and action icons
class _HeaderBar extends StatefulWidget {
  const _HeaderBar();

  @override
  State<_HeaderBar> createState() => _HeaderBarState();
}

class _HeaderBarState extends State<_HeaderBar> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // Opacity glow: dim → bright → dim
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_glowController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGlowIfGuest();
    });
  }

  void _startGlowIfGuest() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !context.read<AuthProvider>().isLoggedIn) {
          _glowController.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCount = context.watch<WishlistProvider>().itemCount;
    final notificationCount = context.watch<NotificationProvider>().unreadCount;
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final width = MediaQuery.sizeOf(context).width;
    // Match the Svelte web breakpoints — < md (768) is mobile chrome where
    // the search bar collapses to an icon and wishlist/cart/account move to
    // the bottom nav. < sm (640) also hides the wordmark to keep the bar tight.
    final isMobile = width < 768;
    final isCompact = width < 600;

    // If user logs in, stop glow
    if (isLoggedIn && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Resume glow when guest scrolls
        if (!isLoggedIn && notification is ScrollUpdateNotification) {
          if (!_glowController.isAnimating && notification.metrics.pixels > 300) {
            _glowController.repeat();
          }
        }
        return false;
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: isMobile ? 60 : 70,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : (isCompact ? 16 : 60),
              ),
              child: isMobile
                  ? _buildMobileBar(
                      isLoggedIn: isLoggedIn,
                      wishlistCount: wishlistCount,
                      notificationCount: notificationCount,
                    )
                  : _buildDesktopBar(
                      isCompact: isCompact,
                      isLoggedIn: isLoggedIn,
                      wishlistCount: wishlistCount,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBar({
    required bool isLoggedIn,
    required int wishlistCount,
    required int notificationCount,
  }) {
    return Row(
      children: [
        const _Logo(isCompact: false, compactWordmark: true, mobileSize: true),
        const Spacer(),
        _ActionIcon(
          icon: Icons.notifications_outlined,
          count: notificationCount,
          badgeColor: const Color(0xFFEF4444),
          onTap: () async {
            if (!isLoggedIn) {
              final loggedIn = await LoginDialog.show(context);
              if (!loggedIn || !context.mounted) return;
            }
            if (!context.mounted) return;
            context.push('/shop/notifications');
          },
        ),
        _ActionIcon(
          icon: Icons.favorite_outline,
          count: wishlistCount,
          onTap: () async {
            if (!isLoggedIn) {
              final loggedIn = await LoginDialog.show(context);
              if (!loggedIn || !context.mounted) return;
            }
            if (!context.mounted) return;
            context.push('/shop/wishlist');
          },
        ),
      ],
    );
  }

  Widget _buildDesktopBar({
    required bool isCompact,
    required bool isLoggedIn,
    required int wishlistCount,
  }) {
    return Row(
      children: [
        _Logo(isCompact: isCompact),
        const SizedBox(width: 20),
        Expanded(child: _SearchBar(isCompact: isCompact)),
        const SizedBox(width: 12),
        _WishlistHeaderButton(
          wishlistCount: wishlistCount,
          isCompact: isCompact,
          isLoggedIn: isLoggedIn,
        ),
        const SizedBox(width: 4),
        _CartHeaderButton(isCompact: isCompact),
        const SizedBox(width: 4),
        _AccountHeaderButton(
          isCompact: isCompact,
          isLoggedIn: isLoggedIn,
        ),
      ],
    );
  }
}

/// Plain icon button used on the mobile header — replaces the full search bar
/// + wishlist/cart/account cluster (those move to the bottom nav).
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x33334155),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

/// Glowing login button for guest users — subtle glow effect (boxShadow pulse, not scale)
class _GlowingLoginButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onTap;

  const _GlowingLoginButton({
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4 * animation.value),
                blurRadius: 12 * animation.value,
                spreadRadius: 2 * animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'Login',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand logo
class _Logo extends StatelessWidget {
  final bool isCompact;
  final bool compactWordmark;
  final bool mobileSize;

  const _Logo({
    required this.isCompact,
    this.compactWordmark = false,
    this.mobileSize = false,
  });

  @override
  Widget build(BuildContext context) {
    // Match Svelte web's exact wordmark palette:
    //   "Arasan"  \u2192 text-danger  #DC2626
    //   "Mobiles" \u2192 text-success #16A34A
    //   "\u00AE"       \u2192 slate-200    #E2E8F0 (light grey on the navy chrome)
    final double logoSize = mobileSize ? 32 : 50;
    final double nameSize = mobileSize ? 17 : (compactWordmark ? 24 : 26);
    final double regSize = mobileSize ? 10 : (compactWordmark ? 13 : 14);
    final double regOffset = mobileSize ? -6 : (compactWordmark ? -9 : -10);
    final double gap = mobileSize ? 6 : (compactWordmark ? 8 : 10);
    return GestureDetector(
      onTap: () => context.go('/shop'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(logoSize / 2),
            child: Image.asset(
              'assets/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.cover,
            ),
          ),
          if (!isCompact) ...[
            SizedBox(width: gap),
            RichText(
              overflow: TextOverflow.visible,
              maxLines: 1,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Arasan ',
                    style: TextStyle(
                      color: const Color(0xFFDC2626),
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Mobiles',
                    style: TextStyle(
                      color: const Color(0xFF16A34A),
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: Transform.translate(
                      offset: Offset(0, regOffset),
                      child: Text(
                        '\u00AE',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: regSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline search bar with overlay dropdown for suggestions & results
class _SearchBar extends StatefulWidget {
  final bool isCompact;
  final bool mobileSize;

  const _SearchBar({required this.isCompact, this.mobileSize = false});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay removal so taps on overlay items register first
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();

    // Fetch product suggestions with debounce
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<SearchProvider>().fetchProductSuggestions(query);
      }
    });

    // Rebuild overlay immediately for local suggestions
    _overlayEntry?.markNeedsBuild();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    context.read<SearchProvider>().search(query);
    _focusNode.unfocus();
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _removeOverlay();
    final searchProvider = context.read<SearchProvider>();

    _overlayEntry = OverlayEntry(
      builder: (context) => _SearchOverlay(
        layerLink: _layerLink,
        controller: _controller,
        onSearch: (query) {
          _controller.text = query;
          _performSearch();
        },
        onProductTap: (productId) {
          _removeOverlay();
          _focusNode.unfocus();
          context.push('/shop/product/$productId');
        },
        onClose: () {
          _removeOverlay();
          _focusNode.unfocus();
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = widget.mobileSize;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: mobile ? 38 : 48,
        constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 720),
        padding: EdgeInsets.only(left: mobile ? 12 : 18, right: mobile ? 8 : 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: mobile ? 18 : 22, color: const Color(0xFF64748B)),
            SizedBox(width: mobile ? 8 : 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                style: TextStyle(fontSize: mobile ? 13 : 15, color: const Color(0xFF0F172A)),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: mobile
                      ? 'Search products...'
                      : widget.isCompact
                          ? 'Search...'
                          : 'Search phones, accessories, brands...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: mobile ? 13 : 15,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: mobile ? 8 : 12),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  context.read<SearchProvider>().clearSearch();
                  _focusNode.requestFocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.close, size: mobile ? 16 : 18, color: const Color(0xFF94A3B8)),
                ),
              ),
            if (!mobile) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _performSearch,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
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
}

/// The dropdown overlay that appears below the search bar
class _SearchOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onProductTap;
  final VoidCallback onClose;

  const _SearchOverlay({
    required this.layerLink,
    required this.controller,
    required this.onSearch,
    required this.onProductTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final query = controller.text.trim();
    final hasSearched = searchProvider.query.isNotEmpty && !searchProvider.isSearching;

    // Don't show dropdown if no query and no recent searches
    final hasContent = query.isNotEmpty ||
        searchProvider.isSearching ||
        hasSearched ||
        searchProvider.recentSearches.isNotEmpty;

    return Stack(
      children: [
        // Dismiss on tap outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // Dropdown positioned below the search bar — only if there's content
        if (hasContent)
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 420),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildContent(context, searchProvider, query, hasSearched),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SearchProvider provider, String query, bool hasSearched) {
    // Loading state
    if (provider.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }

    // Show search results if a search was performed
    if (hasSearched && query.isNotEmpty) {
      return _buildResults(context, provider);
    }

    // Show suggestions while typing
    if (query.isNotEmpty) {
      final suggestions = provider.getSuggestions(query);
      if (suggestions.isNotEmpty) {
        return _buildSuggestions(suggestions);
      }
      // Show product suggestions from live fetch
      if (provider.productSuggestions.isNotEmpty) {
        return _buildSuggestions(provider.productSuggestions);
      }
    }

    // Idle: show recent + popular
    return _buildIdleState(provider);
  }

  Widget _buildIdleState(SearchProvider provider) {
    final hasRecent = provider.recentSearches.isNotEmpty;

    if (!hasRecent) {
      return const SizedBox.shrink();
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => provider.clearRecentSearches(),
                child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        ...provider.recentSearches.map((s) => _SuggestionTile(
              icon: Icons.history,
              iconColor: AppColors.textHint,
              text: s.query,
              onTap: () => onSearch(s.query),
            )),
      ],
    );
  }

  Widget _buildSuggestions(List suggestions) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: suggestions.length > 8 ? 8 : suggestions.length,
      itemBuilder: (context, index) {
        final s = suggestions[index];
        final bool isProduct = s.productId != null;
        return _SuggestionTile(
          icon: isProduct ? Icons.phone_android : Icons.search,
          iconColor: isProduct ? AppColors.primary : AppColors.textHint,
          text: s.query,
          imageUrl: s.imageUrl,
          onTap: () {
            if (isProduct) {
              onProductTap(s.productId!);
            } else {
              onSearch(s.query);
            }
          },
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider provider) {
    if (!provider.hasResults) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'No results for "${provider.query}"',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final results = provider.results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} for "${provider.query}"',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: results.length > 6 ? 7 : results.length,
            itemBuilder: (context, index) {
              // Show "View all" at the end if there are more results
              if (index == 6) {
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.grid_view, color: AppColors.primary, size: 20),
                  title: Text(
                    'View all ${results.length} results',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    onClose();
                    context.push('/shop/search');
                  },
                );
              }
              final product = results[index];
              return _ProductResultTile(
                name: product.name,
                brand: product.brand,
                price: product.effectivePrice,
                originalPrice: product.hasDiscount ? product.price : null,
                imageUrl: product.imageUrl,
                onTap: () => onProductTap(product.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single suggestion row in the overlay
class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(icon, size: 18, color: iconColor),
                ),
              )
            else
              Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.north_west, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// A product result row in the overlay
class _ProductResultTile extends StatelessWidget {
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final VoidCallback onTap;

  const _ProductResultTile({
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF8FAFC),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.phone_android, color: AppColors.textHint, size: 22),
                      )
                    : const Icon(Icons.phone_android, color: AppColors.textHint, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(brand, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\u20B9${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (originalPrice != null)
                  Text(
                    '\u20B9${originalPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint, decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wishlist header button — shows inline "Please login" message for guests
class _WishlistHeaderButton extends StatefulWidget {
  final int wishlistCount;
  final bool isCompact;
  final bool isLoggedIn;

  const _WishlistHeaderButton({
    required this.wishlistCount,
    required this.isCompact,
    required this.isLoggedIn,
  });

  @override
  State<_WishlistHeaderButton> createState() => _WishlistHeaderButtonState();
}

class _WishlistHeaderButtonState extends State<_WishlistHeaderButton> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  void _handleTap() {
    if (widget.isLoggedIn) {
      context.go('/shop/wishlist');
    } else {
      _showLoginMessage();
    }
  }

  void _showLoginMessage() {
    _overlayEntry?.remove();
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height + 4,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Please login to view wishlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionIcon(
      key: _buttonKey,
      icon: Icons.favorite_outline,
      label: widget.isCompact ? null : 'Wishlist',
      count: widget.wishlistCount,
      badgeColor: const Color(0xFFFF3D00),
      onTap: _handleTap,
    );
  }
}

/// Action icon with optional badge and label — clean outlined style
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final String? label;
  final int count;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ActionIcon({
    super.key,
    required this.icon,
    this.label,
    this.count = 0,
    this.badgeColor,
    required this.onTap,
  });

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0x14334155) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: widget.count > 0,
                offset: const Offset(6, -6),
                label: Text(
                  widget.count > 9 ? '9+' : '${widget.count}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: widget.badgeColor ?? const Color(0xFFFF3D00),
                child: Icon(
                  widget.icon,
                  color: _hovering ? AppColors.primary : const Color(0xFF334155),
                  size: 26,
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: _hovering ? AppColors.primary : const Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart header button — navigates to cart with badge for item count
class _CartHeaderButton extends StatelessWidget {
  final bool isCompact;

  const _CartHeaderButton({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    return _ActionIcon(
      icon: Icons.shopping_cart_outlined,
      label: isCompact ? null : 'Cart',
      count: cartCount,
      badgeColor: const Color(0xFFA0D911),
      onTap: () => context.go('/shop/cart'),
    );
  }
}

/// Account header button — navigates to account if logged in, opens login dialog otherwise
class _AccountHeaderButton extends StatelessWidget {
  final bool isCompact;
  final bool isLoggedIn;

  const _AccountHeaderButton({required this.isCompact, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return _ActionIcon(
      icon: Icons.person_outline,
      label: isCompact ? null : (isLoggedIn ? 'Account' : 'Login'),
      onTap: () {
        if (isLoggedIn) {
          context.go('/shop/account');
        } else {
          LoginDialog.show(context);
        }
      },
    );
  }
}
