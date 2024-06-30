import 'dart:convert';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import '../Model/category.dart';
import '../apiRepository/apis.dart';
import 'app_event.dart';
import 'app_state.dart';


class AppBloc extends Bloc<AppEvent, AppState> {
  final _service = Apis();

  AppBloc() : super(AppInitial()) {
    on<fetchCategoriesEvent>((event, emit) => _getAllCategoryBloc(event, emit));
    on<fetchSubCategoriesEvent>((event, emit) => _getSubCategoryBloc(event, emit));
    on<fetchProductsEvent>((event, emit) => _getProductsBloc(event, emit));
  }

  setContext(BuildContext context) {
    _service.setContext(context);
  }

  _getAllCategoryBloc(fetchCategoriesEvent event, Emitter<AppState> emit) async {
    bool hasInternet = await isInternetAvailable();
    if (hasInternet) {
      emit(LoadingState());
      debugPrint("LOADING");
      final response = await _service.fetchCategories(event.categoryId, event.deviceManufacturer,  event.deviceModel, event.deviceToken, event.pageIndex);
      debugPrint("RESPONSE IS $response");
      if (response != null) {
        Map<String, dynamic> temp = json.decode(response);
        log("Response: $temp");

        if (temp['Status'] == 200 && temp['Message'] == 'OK') {
          List<Category> categories = (temp['Result']['Category'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
          emit(FetchCategoriesSuccessState(categories));

        } else {
          String message = temp['Message'] ?? "Something went wrong";
          emit(FetchCategoriesFailureState(message));
        }
      } else {
        emit(FetchCategoriesFailureState("Something went wrong"));
      }
    }
  }


  _getSubCategoryBloc(fetchSubCategoriesEvent event, Emitter<AppState> emit) async {
    bool hasInternet = await isInternetAvailable();
    if (hasInternet) {
      emit(LoadingState());
      debugPrint("LOADING");
      final response = await _service.fetchSubCategories(event.categoryId, event.pageIndex);
      debugPrint("RESPONSE IS $response");
      if (response != null) {
        var temp = json.decode(response);
        log("Response: $temp");
        if (temp['Status'] == 200 && temp['Message'] == 'OK') {
          List<SubCategory> subCategories = [];
          var categoryList = temp['Result']['Category'] as List;
          categoryList.forEach((categoryJson) {
            if (categoryJson['SubCategories'] != null) {
              var subCategoryList = categoryJson['SubCategories'] as List;
              subCategoryList.forEach((subCategoryJson) {
                subCategories.addAll(subCategoryList.map((subCategoryJson) => SubCategory(
                  id: subCategoryJson['Id'],
                  name: subCategoryJson['Name'],
                  products: [],
                )));
              });
            }
          });
          emit(FetchSubCategoriesSuccessState(subCategories));
        } else {
          String message = temp['Message'] ?? "Something went wrong";
          emit(FetchSubCategoriesFailureState(message));
        }
      } else {
        emit(FetchCategoriesFailureState("Something went wrong"));
      }
    }
  }


  _getProductsBloc(fetchProductsEvent event, Emitter<AppState> emit) async {
    bool hasInternet = await isInternetAvailable();
    if (hasInternet) {
      log("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
      emit(LoadingState());
      print("LOADING");
      final response = await _service.fetchProducts(event.pageIndex,event.subCategoryId);
      print("RESPONSE IS $response");
      if (response != null) {
        var temp = json.decode(response);
        log("Responseee: $temp");
        if (temp['Status'] == 200 && temp['Message'] == 'OK') {
          debugPrint("responseINSIDE::$response");
          // Extract the list of products from the "Result" key
          List<dynamic> productsJson = temp["Result"];
            List<Product> products = productsJson.map((json) => Product.fromJson(json)).toList();
            debugPrint("responseINSIDE1::${products.length}");
          emit(FetchProductsSuccessState(products));
        } else {
          String message = temp['Message'] ?? "Something went wrong";
          log("messagemessage:${message}");
          emit(FetchProductsFailureState(message));
        }
      } else {
        emit(FetchCategoriesFailureState("Something went wrong"));
      }
    }
  }



}
