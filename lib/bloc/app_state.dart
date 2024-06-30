import 'package:equatable/equatable.dart';
import '../Model/category.dart';

abstract class AppState extends Equatable {
  const AppState();
}

class AppInitial extends AppState {
  @override
  List<Object?> get props => [];
}

class FetchCategoriesSuccessState extends AppState {
  List<Category> categoryList;

  FetchCategoriesSuccessState(this.categoryList);

  @override
  List<Object?> get props => [categoryList];
}

class FetchCategoriesFailureState extends AppState {
  String? errorMessage;

  FetchCategoriesFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class FetchSubCategoriesSuccessState extends AppState {
  List<SubCategory> subCategoryList;

  FetchSubCategoriesSuccessState(this.subCategoryList);

  @override
  List<Object?> get props => [subCategoryList];
}

class FetchSubCategoriesFailureState extends AppState {
  String? errorMessage;

  FetchSubCategoriesFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}


class FetchProductsSuccessState extends AppState {
  List<Product> productsList;

  FetchProductsSuccessState(this.productsList);

  @override
  List<Object?> get props => [productsList];
}

class FetchProductsFailureState extends AppState {
  String? errorMessage;

  FetchProductsFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}


class LoadingState extends AppState {
  @override
  List<Object?> get props => [];
}

