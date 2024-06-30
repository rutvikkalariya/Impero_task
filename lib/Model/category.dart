import 'package:flutter/cupertino.dart';

class Category {
  final int id;
  final String name;
  final int isAuthorize;
  final int update080819;
  final int update130919;

  Category({
    required this.id,
    required this.name,
    required this.isAuthorize,
    required this.update080819,
    required this.update130919,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['Id'],
      name: json['Name'],
      isAuthorize: json['IsAuthorize']?? 0,
      update080819: json['Update080819']?? 0,
      update130919: json['Update130919']?? 0,
    );
  }
}

// Define the SubCategory class to represent each 'SubCategory' object in the response
class SubCategory {
  final int id;
  final String name;
  final List<Product> products;
  int productsPage = 1;
  bool isProductsLastPage = false;
  ScrollController? productController;

  SubCategory({required this.id, required this.name, required this.products});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    var productList = json['Product'] as List;
    List<Product> products = productList.map((i) => Product.fromJson(i)).toList();

    return SubCategory(
      id: json['Id'],
      name: json['Name'],
      products: products,
    );
  }
}

// Define the Product class to represent each 'Product' object in the response
class Product {
  final String name;
  final String priceCode;
  final String imageName;
  final int id;

  Product({required this.name, required this.priceCode, required this.imageName, required this.id});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['Name'],
      priceCode: json['PriceCode'],
      imageName: json['ImageName'],
      id: json['Id'],
    );
  }
}