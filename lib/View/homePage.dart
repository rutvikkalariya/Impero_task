import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../Model/category.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showLoader = true;
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  int selectedIndex = 1;
  int ceramicId = -1;
  int subCatPage = 1;
  int productPage = 1;
  bool isLast = false;
  ScrollController subCatController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    subCatController.addListener(_scrollListener);
    initApiCall();
    super.initState();
  }

  void _scrollListener() {
    if (subCatController.position.pixels ==
            subCatController.position.maxScrollExtent &&
        !isLast) {
      if (!isLoading) {
        fetchSubCategory();
      }
    }
  }

  initApiCall() async {
    await fetchData();
    showLoader = false;
    selectedIndex = 1;
    setState(() {});
  }

  Future<void> fetchSubCategory() async {
    isLoading = true;
    setState(() {});
    List<SubCategory> temp = await fetchSubCategories(ceramicId, subCatPage);
    await getProduct(temp);
  }

  getProduct(List<SubCategory> temp) {
    List<SubCategory> temp1 = temp;
    temp1.forEach((element) async {
      List<Product> products = await fetchProducts(productPage, element.id);
      debugPrint("products::${products.length}");
      element.products.addAll(products);
      element.productsPage = productPage; // Initialize product page index for each subcategory
      element.isProductsLastPage = false; // Initialize the flag for last page
      element.productController = ScrollController();
      element.productController!.addListener(() {
        _productScrollListener(element);
      });
    });

    subCategories.addAll(temp1);

    Future.delayed(
      const Duration(seconds: 3),
      () {
        isLoading = false;
        setState(() {});
      },
    );
  }

  Future<List<Product>> fetchProducts(int pageIndex, int subCategoryId) async {
    final params = {
      "PageIndex": pageIndex.toString(),
      "SubCategoryId": subCategoryId.toString(),
    };

    final response = await http.post(
        Uri.parse(
            'http://esptiles.imperoserver.in/api/API/Product/ProductList'),
        body: jsonEncode(params),
        headers: {
          'Content-Type': 'application/json',
          // Add any necessary headers here
        });
    debugPrint("response::$response");
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData["Status"] == 200 && jsonData["Message"] == "OK") {
        debugPrint("responseINSIDE::$response");
        // Extract the list of products from the "Result" key
        List<dynamic> productsJson = jsonData["Result"];
        if (productsJson.isEmpty) {
          isLoading = false;
          setState(() {});
          return [];
        } else {
          List<Product> products = productsJson.map((json) => Product.fromJson(json)).toList();
          debugPrint("responseINSIDE1::${products.length}");
          return products;
        }
      } else {
        debugPrint("response::$response");
        isLoading = false;
        setState(() {});
        return [];
      }
    } else {
      isLoading = false;
      setState(() {});
      return [];
    }
  }

  fetchData() async {
    List<Category> fetchedCategories = await fetchCategories();
    setState(() {
      categories = fetchedCategories;
    });
    for (var element in fetchedCategories) {
      if (element.name.toLowerCase() == 'ceramic') {
        ceramicId = element.id;
        break;
      }
    }

    if (ceramicId != -1) {
      await fetchSubCategory();
    }
  }

  Future<List<Category>> fetchCategories() async {
    String apiUrl = 'http://esptiles.imperoserver.in/api/API/Product/DashBoard';
    Map<String, dynamic> requestParams = {
      "CategoryId": 0,
      "DeviceManufacturer": "Google",
      "DeviceModel": "Android SDK built for x86",
      "DeviceToken": " ",
      "PageIndex": 1,
    };
    String requestBody = jsonEncode(requestParams);

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        // Extract list of categories
        List<Category> categories = [];
        var categoryList = jsonResponse['Result']['Category'] as List;
        categoryList.forEach((categoryJson) {
          categories.add(Category(
            id: categoryJson['Id'],
            name: categoryJson['Name'],
            isAuthorize: categoryJson['IsAuthorize'] ?? 0,
            update080819: categoryJson['Update080819'] ?? 0,
            update130919: categoryJson['Update130919'] ?? 0,
            subCategories: [],
          ));
        });

        return categories;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<SubCategory>> fetchSubCategories(
      int categoryId, int pageIndex) async {
    String apiUrl = 'http://esptiles.imperoserver.in/api/API/Product/DashBoard';
    Map<String, dynamic> requestParams = {
      "CategoryId": categoryId,
      "PageIndex": pageIndex,
    };

    String requestBody = jsonEncode(requestParams);

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      List<SubCategory> subCategories = [];
      var categoryList = jsonResponse['Result']['Category'] as List;
      categoryList.forEach((categoryJson) {
        if (categoryJson['SubCategories'] != null) {
          var subCategoryList = categoryJson['SubCategories'] as List;
          subCategoryList.forEach((subCategoryJson) {
            subCategories.add(SubCategory(
                id: subCategoryJson['Id'],
                name: subCategoryJson['Name'],
                products: []));
          });
        }
      });

      if (subCategories.isNotEmpty) {
        subCatPage = subCatPage + 1;
      } else {
        isLast = true;
      }

      return subCategories;
    } else {
      // Handle errors
      print('Request failed with status: ${response.statusCode}.');
      return [];
    }
  }

  void _productScrollListener(SubCategory subCategory) {
    if (subCategory.productController!.position.pixels ==
        subCategory.productController!.position.maxScrollExtent &&
        !subCategory.isProductsLastPage &&
        !isLoading) {
      fetchMoreProducts(subCategory);
    }
  }

  Future<void> fetchMoreProducts(SubCategory subCategory) async {
    isLoading = true;
    setState(() {});
    List<Product> newProducts = await fetchProducts(subCategory.productsPage, subCategory.id);
    if (newProducts.isNotEmpty) {
      subCategory.products.addAll(newProducts);
      subCategory.productsPage++;
      debugPrint("inside");
    } else {
      subCategory.isProductsLastPage = true;
      debugPrint("inside");
    }
    debugPrint("isLoading r:$isLoading");
    isLoading = false;
    debugPrint("isLoading s:$isLoading");
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: const [
          Icon(
            Icons.sort,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(
            width: 16,
          ),
          Icon(
            Icons.search,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(
            width: 16,
          ),
        ],
        title: const Text(
          "ESP TILES",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: buildBody(),
    );
  }

  buildBody() {
    return showLoader
        ? const Center(
            child: SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 5,
              ),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Colors.black,
                  height: 55,
                  child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            selectedIndex = index;
                            setState(() {});
                          },
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              categories[index].name,
                              style: TextStyle(
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  fontSize: selectedIndex == index ? 16 : 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          width: 10,
                        );
                      },
                      itemCount: categories.length),
                ),
                selectedIndex == 1 ? ceramicView() : noDataFoundView()
              ],
            ),
          );
  }

  ceramicView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 700,
          child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 10),
              controller: subCatController,
              itemBuilder: (context, index) {
                return subCategoryItem(index);
              },
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 10,
                );
              },
              itemCount: subCategories.length),
        ),
        isLoading
            ? const SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 5,
                ),
              )
            : Container(),
      ],
    );
  }

  subCategoryItem(index) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Text(
            subCategories[index].name,
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
                controller: subCategories[index].productController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(right: 16),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, indexx) {
                  return Column(
                    children: [
                      Container(
                        height: 90,
                        width: 110,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8)),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                subCategories[index].products[indexx].imageName,
                                height: 90,
                                width: 110,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              top: 5,
                              left: 10,
                              child: Container(
                                height: 15,
                                width: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(3)),
                                child: Text(
                                  subCategories[index]
                                      .products[indexx]
                                      .priceCode,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          subCategories[index].products[indexx].name,
                          maxLines: 1,
                          style: const TextStyle(
                              overflow: TextOverflow.ellipsis,
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    width: 10,
                  );
                },
                itemCount: subCategories[index].products.length),
          )
        ],
      ),
    );
  }

  noDataFoundView() {
    return Container(
      height: 200,
      width: 200,
      alignment: Alignment.center,
      child: const Text(
        'No data found',
        style: TextStyle(
            color: Colors.black, fontSize: 26, fontWeight: FontWeight.w600),
      ),
    );
  }
}