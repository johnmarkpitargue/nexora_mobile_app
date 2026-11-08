import 'package:flutter/material.dart';
import '../../features/home/presentation/widgets/product_card.dart';

/// Individual option in a variant group (e.g., "Matte Black", "Chalk White")
class ProductVariantOption {
  final String id;
  final String name;
  final Color? colorHex;
  final String? subtitle;
  final double priceOffset;
  final double? price;
  final int stock;
  final String? imageUrl;
  final String? sku;
  final String? color;
  final String? size;

  const ProductVariantOption({
    required this.id,
    required this.name,
    this.colorHex,
    this.subtitle,
    this.priceOffset = 0.0,
    this.price,
    this.stock = 0,
    this.imageUrl,
    this.sku,
    this.color,
    this.size,
  });
}

/// A group of variants for a product (e.g. "Color Palette", "Mount / Stand Type", "Size")
class ProductVariantGroup {
  final String groupName;
  final List<ProductVariantOption> options;

  const ProductVariantGroup({
    required this.groupName,
    required this.options,
  });
}

/// Individual user review for a product
class ProductReviewModel {
  final String id;
  final String userName;
  final String initials;
  final Color avatarColor;
  final double rating;
  final String date;
  final String variantName;
  final String comment;
  final List<String> reviewImages;
  int helpfulCount;
  bool hasLiked;

  ProductReviewModel({
    required this.id,
    required this.userName,
    required this.initials,
    required this.avatarColor,
    required this.rating,
    required this.date,
    required this.variantName,
    required this.comment,
    this.reviewImages = const [],
    this.helpfulCount = 0,
    this.hasLiked = false,
  });
}

/// Voucher ticket issued by a shop
class ShopVoucherModel {
  final String id;
  final String discountTitle; // e.g. "5% OFF", "₱100 OFF"
  final String tag; // e.g. "Store", "Welcome", "VIP"
  final String minSpend; // e.g. "Min. spend ₱2,000"
  final String expiry; // e.g. "Exp: 31.12.2026"
  final Color buttonColor;
  final double discountAmount;
  final bool isPercentage;

  const ShopVoucherModel({
    required this.id,
    required this.discountTitle,
    required this.tag,
    required this.minSpend,
    required this.expiry,
    required this.buttonColor,
    this.discountAmount = 0,
    this.isPercentage = false,
  });
}

/// Collection / category inside a shop
class ShopCategoryModel {
  final String id;
  final String title;
  final int itemCount;
  final String imageUrl;

  const ShopCategoryModel({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.imageUrl,
  });
}

/// Full Shop Entity representing an official store on Nexora
class ShopModel {
  final String id;
  final String name;
  final String badge; // 'NEXORA MALL', 'OFFICIAL STORE', 'TOP SELLER'
  final double rating;
  final String followers; // e.g. '129.4K'
  final String initials; // e.g. 'N\nMALL'
  final Color avatarBg;
  final String categoryGroupTitle; // e.g. 'AUDIO & STUDIO GEAR'
  final List<ShopCategoryModel> categories;
  final List<ShopVoucherModel> vouchers;
  final String guaranteeText;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isFollowing;
  final bool isVacationMode;
  final List<ProductModel> products;

  const ShopModel({
    required this.id,
    required this.name,
    this.badge = 'NEXORA MALL',
    this.rating = 4.9,
    required this.followers,
    required this.initials,
    this.avatarBg = const Color(0xFF0066FF),
    required this.categoryGroupTitle,
    required this.categories,
    required this.vouchers,
    this.guaranteeText = '100% Authentic Guaranteed • 24-Month Warranty',
    this.avatarUrl,
    this.bannerUrl,
    this.isFollowing = false,
    this.isVacationMode = false,
    this.products = const [],
  });
}

/// Dynamic marketplace category retrieved from Laravel /api/mobile/v1/buyer/categories
class AppCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;

  const AppCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
  });

  factory AppCategoryModel.fromJson(Map<String, dynamic> json) {
    return AppCategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }
}
