import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../Model/category.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../bloc/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showLoader = true;
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  List<SubCategory> dummySubCategories = [];
  int selectedIndex = 1;
  int ceramicId = -1;
  int subCatPage = 1;
  int productPage = 1;
  bool isLast = false;
  ScrollController subCatController = ScrollController();
  bool isLoading = false;
  final AppBloc _appBloc = AppBloc();
  BuildContext? _progressContext;

  @override
  void initState() {
    subCatController.addListener(_scrollListener);
    initApiCall();

    super.initState();
  }

  fetchcategoryList() {
    _appBloc.add(
        fetchCategoriesEvent(0, 'Google', 'Android SDK built for x86', '', 1));
  }

  fetchSubcategoryList(int ceramicId, subCatPage) {
    _appBloc.add(
        fetchSubCategoriesEvent(ceramicId, subCatPage));
  }

  fetchProductList(int subCategoryIdd, int productPagee) {
    _appBloc.add(
        fetchProductsEvent(subCategoryIdd, productPagee));
  }

  void _scrollListener() {
    if (subCatController.position.pixels ==
        subCatController.position.maxScrollExtent &&
        !isLast) {
      if (!isLoading) {
        fetchSubcategoryList(ceramicId,subCatPage);
      }
    }
  }

  initApiCall() async {
    await fetchcategoryList();
    showLoader = false;
    selectedIndex = 1;
    setState(() {});
  }

  getProduct(List<SubCategory> temp) {
    List<SubCategory> temp1 = temp;
    temp1.forEach((element) async {
      List<Product> productsList = await fetchProducts(productPage,element.id, );
      log("Awaited");
      debugPrint("products::${productsList.length}");
      element.products.addAll(productsList);
      element.productsPage = productPage; // Initialize product page index for each subcategory
      element.isProductsLastPage = false; // Initialize the flag for last page
      element.productController = ScrollController();
      element.productController!.addListener(() {
        _productScrollListener(element);
      });
    });

    subCategories.addAll(temp1);

    if (subCategories.isNotEmpty) {
      subCatPage = subCatPage + 1;
    } else {
      isLast = true;
    }

    Future.delayed(
      const Duration(seconds: 1),
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
    return BlocConsumer(
      bloc: _appBloc,
      listener: (context, state) async {
        if (state is FetchCategoriesSuccessState) {
          hideProgressDialog();
          categories = state.categoryList;
          for (var element in categories) {
            if (element.name.toLowerCase() == 'ceramic') {
              ceramicId = element.id;
              break;
            }
          }
          if (ceramicId != -1) {
            await fetchSubcategoryList(ceramicId, subCatPage);
          }

          log("categories: ${categories.length}");
          log("success");
        } else if (state is FetchCategoriesFailureState) {
          hideProgressDialog();
          log("fail");
        } else if (state is FetchSubCategoriesSuccessState) {
          hideProgressDialog();
          dummySubCategories.addAll(state.subCategoryList);
          getProduct(dummySubCategories);
          log("dummySubCategories: ${dummySubCategories.length}");
        } else if (state is FetchSubCategoriesFailureState) {
          hideProgressDialog();
          log("fail");
        } else if (state is FetchProductsSuccessState) {
          hideProgressDialog();
          // productsList = state.productsList;
          // log("productsList${productsList.length}");
        } else if (state is FetchProductsFailureState) {
          hideProgressDialog();
          log("fail");
        }
        else if (state is LoadingState) {
          showProgressbarDialog(context);
        }
      },
      builder: (context, state) {
        return  Scaffold(
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
      },

    );
  }

  buildBody() {
    return
      SingleChildScrollView(
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


  void hideProgressDialog() {
    if (_progressContext != null) {
      Navigator.of(_progressContext!).pop(true);
      _progressContext = null;
    }
  }

  void showProgressbarDialog(BuildContext context,
      {Color? loaderColor, String? text}) {
    if (_progressContext == null) {
      displayProgressDialog(
          context: context,
          barrierDismissible: false,
          builder: (con) {
            _progressContext = con;
            return WillPopScope(
                onWillPop: () async => false,
                child: const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 5,
                    ),
                  ),
                ));
          });
    }
  }

  Future<T?>? displayProgressDialog<T>(
      {@required BuildContext? context,
        bool barrierDismissible = true,
        Widget? child,
        WidgetBuilder? builder,
        bool useRootNavigator = true}) {
    assert(child == null || builder == null);
    assert(useRootNavigator != null);
    assert(debugCheckHasMaterialLocalizations(context!));

    final ThemeData theme = Theme.of(context!);
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      pageBuilder: (BuildContext? buildContext, Animation<double>? animation,
          Animation<double>? secondaryAnimation) {
        final Widget pageChild = child ?? Builder(builder: builder!);
        return SafeArea(
          child: Builder(builder: (BuildContext context) {
            return theme != null
                ? Theme(data: theme, child: pageChild)
                : pageChild;
          }),
        );
      },
      useRootNavigator: useRootNavigator,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black12.withOpacity(0.6),
      transitionDuration: const Duration(seconds: 1),
    );
  }
}
