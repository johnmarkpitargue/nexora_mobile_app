import 'package:flutter/material.dart';

import '../../../../app/theme/nexora_theme.dart';
import 'product_card.dart';

class ShoppingProductGrid extends StatelessWidget {
  const ShoppingProductGrid({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.all(NexoraSpacing.md),
    this.shrinkWrap = false,
    this.physics,
  });

  final List<ProductModel> products;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 1080 => 5,
          >= 820 => 4,
          >= 560 => 3,
          _ => 2,
        };
        const spacing = NexoraSpacing.sm;
        final horizontalPadding = padding.horizontal;
        final cardWidth =
            (constraints.maxWidth -
                horizontalPadding -
                spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibilityGrowth = ((textScale - 1).clamp(0.0, 1.0) * 104);
        final cardHeight = cardWidth + 152.0 + accessibilityGrowth;

        return GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics:
              physics ??
              (shrinkWrap
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    )),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }
}

class ShoppingEmptyState extends StatelessWidget {
  const ShoppingEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NexoraSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: NexoraSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: NexoraSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NexoraSpacing.xl),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ShoppingSkeletonGrid extends StatelessWidget {
  const ShoppingSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(NexoraSpacing.md),
          itemCount: columns * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: NexoraSpacing.sm,
            mainAxisSpacing: NexoraSpacing.sm,
            mainAxisExtent: 292,
          ),
          itemBuilder: (context, index) {
            return _SkeletonCard(animate: !reduceMotion);
          },
        );
      },
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.animate});

  final bool animate;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 0.8,
      value: 0.6,
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SkeletonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0.6;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = NexoraTheme.surfaceContainerHigh.withValues(
          alpha: _controller.value,
        );
        return Semantics(
          label: 'Loading product',
          child: Material(
            color: NexoraTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(NexoraRadius.card),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: ColoredBox(color: color)),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(NexoraSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonLine(color: color, width: double.infinity),
                        const SizedBox(height: NexoraSpacing.xs),
                        _SkeletonLine(color: color, width: 92),
                        const Spacer(),
                        _SkeletonLine(color: color, width: 72),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(NexoraRadius.small),
      ),
    );
  }
}
