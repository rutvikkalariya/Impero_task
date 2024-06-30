import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as mt;

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_constants.dart';

class Apis {
  BuildContext? globalContext;

  setContext(BuildContext ctx) {
    globalContext = ctx;
  }

  Future fetchCategories(int categoryId, String deviceManufacturer, String deviceModel,String deviceToken, int pageIndex ) async {
    Map<String, dynamic> params = Map();
    params["CategoryId"] = categoryId;
    params["DeviceManufacturer"] = deviceManufacturer;
    params["DeviceModel"] = deviceModel;
    params["DeviceToken"] = deviceToken;
    params["PageIndex"] = pageIndex;
    print("PARAMS IS HERE $params");
    final response = await postAPICallWithResponse(URLS.ALLCATEGORY, params);
    print("RESPONSE IS HERE $response");
    return response;
  }

  Future fetchSubCategories(int categoryId, int pageIndex) async {
    Map<String, dynamic> params = Map();
    params["CategoryId"] = categoryId;
    params["PageIndex"] = pageIndex;
    print("PARAMS IS HERE $params");
    final response = await postAPICallWithResponse(URLS.SUBCATEGORY, params);
    print("RESPONSE IS HERE $response");
    return response;
  }

  Future fetchProducts(int subCategoryId, int pageIndex) async {
    log("jdsjdsjsjh");
    Map<String, dynamic> params = Map();
    params["PageIndex"] = pageIndex;
    params["SubCategoryId"] = subCategoryId;
    log("PARAMS IS HEREE $params");
    final response = await postAPICallWithResponse(URLS.PRODUCTS, params);
    log("RESPONSE IS HEREE $response");
    return response;
  }
}


Future<String?> postAPICallWithResponse(String url, Map<String, dynamic> body,
    {Map<String, String>? headers, bool showLoader = true}) async {
  debugPrint("API Call _URL  $url");
  debugPrint("API Call INITIATED....");
  debugPrint("API Call INITIATED....$body");

  bool hasInternet = await isInternetAvailable();

  if (headers == null) {
    headers = Map();
  }
  headers["content-type"] = "application/json";

  if (hasInternet) {
    if (showLoader) {
      // return null;
    }

    debugPrint("REQUEST_PARAMS $body");
    try {
      var response = await http
          .post(Uri.parse(url), body: jsonEncode(body), headers: headers)
          .timeout(const Duration(seconds: 30),
          onTimeout: () {
            // APIResponseHandler().handleResponse(baseView,event, null);
            throw TimeoutException(
                'The connection has timed out, Please try again!');
          });
      if (response != null) {
        debugPrint("API Call ENDED...");
        print("RESPONSE_POST_CODE ${response.statusCode}");
        print("RESPONSE_POST ${response.body}");
        if (response.statusCode == 200) {
          return response.body;
          // APIResponseHandler().handleResponse(baseView,event, response.body);
        } else {
          return null;
          // APIResponseHandler().handleResponse(baseView,event, null);
        }
      } else {
        print("RESPONSE_POST iS NUll");
        return null;
        // APIResponseHandler().handleResponse(baseView,event, null);
      }
    } on TimeoutException catch (e) {
      return null;
      // APIResponseHandler().handleResponse(baseView,event, null);
    } on SocketException catch (e) {
      return null;
      // APIResponseHandler().handleResponse(baseView,event, null);
    } on Exception catch (e) {
      return null;
      // APIResponseHandler().handleResponse(baseView,event, null);
    } catch (e) {
      return null;
    }
  } else {
    return null;
  }
}


Future<bool> isInternetAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  } else {
    return false;
  }
}