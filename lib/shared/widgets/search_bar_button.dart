import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/search_provider.dart';

/// Inline search bar shown below the header. Typing shows live product
/// suggestions in a dropdown right here — it does NOT navigate to a separate
/// page. Tapping a suggestion opens that product. Matches typed text against
/// product names so the customer doesn't have to type the full name.
class SearchBarButton extends StatefulWidget {
  /// When true, renders just the pill (no surrounding surface/padding) so it
  /// can sit inside a header row — used on the product detail page header.
  final bool compact;

  const SearchBarButton({super.key, this.compact = false});

  @override
  State<SearchBarButton> createState() => _SearchBarButtonState();
}

class _SearchBarButtonState extends State<SearchBarButton> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  Timer? _debounce;
  bool _focused = false;

  bool _seededFromRoute = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On the PDP header (compact), pre-fill the search bar from the `q` route
    // param — present only when the page was reached via a search result, so a
    // product opened by tapping a card shows an empty bar. Done once.
    if (widget.compact && !_seededFromRoute) {
      _seededFromRoute = true;
      final q = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
      if (q.isNotEmpty && _controller.text.isEmpty) {
        _controller.text = q;
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay so a tap on a suggestion registers before the overlay closes.
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) context.read<SearchProvider>().fetchProductSuggestions(q);
    });
    if (_overlay == null && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _overlay?.markNeedsBuild();
    }
    setState(() {}); // refresh the clear button
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _openProduct(String id) {
    _removeOverlay();
    _focusNode.unfocus();
    // Carry the typed search term to the PDP so its search bar keeps showing it.
    // A product opened by TAPPING A CARD pushes the plain route (no `q`), so its
    // PDP search bar stays empty — exactly the required distinction.
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      context.push('/shop/product/$id?q=${Uri.encodeComponent(q)}');
    } else {
      context.push('/shop/product/$id');
    }
  }

  Widget _buildOverlay() {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        final q = _controller.text.trim();
        final suggestions = provider.productSuggestions;
        if (q.isEmpty || suggestions.isEmpty) return const SizedBox.shrink();
        final count = suggestions.length > 8 ? 8 : suggestions.length;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                  _focusNode.unfocus();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: count,
                      itemBuilder: (context, i) {
                        final s = suggestions[i];
                        return InkWell(
                          onTap: () {
                            if (s.productId != null) _openProduct(s.productId!);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: const Color(0xFFF8FAFC),
                                    child: (s.imageUrl != null &&
                                            s.imageUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: s.imageUrl!,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.phone_android,
                                                    size: 20,
                                                    color: AppColors.textHint),
                                          )
                                        : const Icon(Icons.phone_android,
                                            size: 20, color: AppColors.textHint),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.query,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.north_west,
                                    size: 14, color: AppColors.textHint),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pill-shaped field. On focus the WHOLE pill gets a blue border (oval, not
    // a rectangle) — InputBorder.none on the TextField avoids the rectangle.
    final pill = Container(
      height: widget.compact ? 40 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        // Fully white pill everywhere (incl. the PDP compact header) — no grey fill.
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focused ? const Color(0xFF1400E0) : const Color(0xFFE2E8F0),
          width: _focused ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search,
              size: 20,
              color: _focused
                  ? const Color(0xFF1400E0)
                  : AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  context
                      .read<SearchProvider>()
                      .fetchProductSuggestions(q.trim());
                }
              },
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search products...',
                hintStyle:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                context.read<SearchProvider>().clearSearch();
                _overlay?.markNeedsBuild();
              },
              child: const Icon(Icons.close,
                  size: 18, color: AppColors.textSecondary),
            ),
        ],
      ),
    );

    final field = CompositedTransformTarget(link: _layerLink, child: pill);

    if (widget.compact) return field;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: field,
      ),
    );
  }
}
