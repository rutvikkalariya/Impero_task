import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();
}

class fetchCategoriesEvent extends AppEvent {
  int categoryId;
  String deviceManufacturer;
  String deviceModel;
  String deviceToken;
  int pageIndex;

  fetchCategoriesEvent(this.categoryId, this.deviceManufacturer, this.deviceModel, this.deviceToken, this.pageIndex);

  @override
  List<Object?> get props => [];
}

class fetchSubCategoriesEvent extends AppEvent {
  int categoryId;
  int pageIndex;

  fetchSubCategoriesEvent(this.categoryId, this.pageIndex);

  @override
  List<Object?> get props => [];
}

class fetchProductsEvent extends AppEvent {
  int pageIndex;
  int subCategoryId;

  fetchProductsEvent(this.pageIndex,this.subCategoryId);

  @override
  List<Object?> get props => [];
}
