import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

class PromoBannersSection extends StatefulWidget {
  const PromoBannersSection({super.key});

  @override
  State<PromoBannersSection> createState() => _PromoBannersSectionState();
}

class _PromoBannersSectionState extends State<PromoBannersSection> {
  static const List<_CampaignData> _campaigns = [
    _CampaignData(
      title: 'SoundMax Pro 18',
      releaseNote: 'New this week',
      description: 'Spatial audio, ANC, and zero-latency listening.',
      searchQuery: 'SoundMax Pro 18',
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.headphones_rounded,
      gradient: [NexoraTheme.darkNavy, Color(0xFF0C4A6E)],
    ),
    _CampaignData(
      title: 'AuraFit Ultra 2',
      releaseNote: 'Limited stock',
      description: 'A vivid AMOLED display with a 14-day battery.',
      searchQuery: 'AuraFit Ultra 2',
      imageUrl: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.watch_rounded,
      gradient: [Color(0xFF071631), Color(0xFF0B4D99)],
    ),
    _CampaignData(
      title: 'Apex Pro Keyboards',
      releaseNote: 'Special edition',
      description: 'Responsive switches and focused desk-ready lighting.',
      searchQuery: 'Apex Pro Keyboards',
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.keyboard_rounded,
      gradient: [Color(0xFF0A1028), Color(0xFF123B68)],
    ),
  ];

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _autoSlideTimer?.cancel();
    } else {
      _startAutoSlideTimer();
    }
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _campaigns.length;
      _pageController.animateToPage(
        nextPage,
        duration: NexoraMotion.emphasized,
        curve: NexoraMotion.emphasizedCurve,
      );
    });
  }

  void _openCampaign(_CampaignData campaign) {
    Navigator.pushNamed(
      context,
      AppRoutes.search,
      arguments: campaign.searchQuery,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motionDuration = NexoraMotion.resolve(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final accessibilityGrowth = ((textScale - 1).clamp(0.0, 1.0) * 138);
            final bannerHeight =
                ((constraints.maxWidth * 0.68).clamp(232.0, 310.0) +
                        accessibilityGrowth)
                    .clamp(232.0, 448.0);

            return SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                key: const ValueKey('campaign-hero-rail'),
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = _campaigns[index];
                  return _CampaignCard(
                    key: ValueKey('promo-page-$index'),
                    campaign: campaign,
                    pageIndex: index,
                    pageCount: _campaigns.length,
                    onPressed: () => _openCampaign(campaign),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: NexoraSpacing.sm),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_campaigns.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: motionDuration,
                curve: NexoraMotion.standardCurve,
                width: isSelected ? 24 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(NexoraRadius.full),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    super.key,
    required this.campaign,
    required this.pageIndex,
    required this.pageCount,
    required this.onPressed,
  });

  final _CampaignData campaign;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final contentWidth = textScale > 1.3 ? 0.92 : 0.76;

    return Semantics(
      label: 'Promotion ${pageIndex + 1} of $pageCount',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: campaign.gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              campaign.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: NexoraSpacing.xxl),
                  child: Icon(
                    campaign.fallbackIcon,
                    size: 92,
                    color: NexoraTheme.secondary.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NexoraTheme.darkNavy.withValues(alpha: 0.98),
                    NexoraTheme.darkNavy.withValues(alpha: 0.82),
                    NexoraTheme.darkNavy.withValues(alpha: 0.12),
                  ],
                  stops: const [0, 0.58, 1],
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: contentWidth,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  NexoraSpacing.lg,
                  NexoraSpacing.xl,
                  NexoraSpacing.sm,
                  NexoraSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.06,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: NexoraSpacing.sm),
                    Text(
                      '${campaign.releaseNote} \u2022 ${campaign.description}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      key: ValueKey('promo-cta-$pageIndex'),
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        foregroundColor: NexoraTheme.darkNavy,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: NexoraSpacing.md,
                        ),
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Shop now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignData {
  const _CampaignData({
    required this.title,
    required this.releaseNote,
    required this.description,
    required this.searchQuery,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.gradient,
  });

  final String title;
  final String releaseNote;
  final String description;
  final String searchQuery;
  final String imageUrl;
  final IconData fallbackIcon;
  final List<Color> gradient;
}
