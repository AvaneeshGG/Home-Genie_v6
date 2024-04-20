import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import'package:home_genie/Inventory.dart';

Future<String?> _getFirebaseCode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('globalConnectCode');
}

Future<void> addFruit({
  required String globalConnectCode,
  required String? itemName,
  required String category,
  String? quantity,
  String? metricWeight,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category)
        .add({
      'title': itemName,
      'quantity': quantity,
      'weight': metricWeight,
      'limit': '2'
    });
    print('add + pantry block executed');
  } catch (e) {
    print('Error adding fruit: $e');
  }
}

Future<bool> checkIfItemExists(
    String globalConnectCode,
    String itemName,
    String category,
    ) async {
  var query = FirebaseFirestore.instance
      .collection('sharedCollection')
      .doc(globalConnectCode)
      .collection(category)
      .where('title', isEqualTo: itemName);

  var result = await query.get();
  return result.docs.isNotEmpty;
}


Future<String?> getFieldFromFirebase(String globalConnectCode, String itemName, String category, String field) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document for each item in the category
      var document = querySnapshot.docs.first;
      return document[field];
    } else {
      return null; // Item not found
    }
  } catch (e) {
    print('Error fetching $field from Firebase: $e');
    return null;
  }
}

Future<void> updateFieldInFirebase(String globalConnectCode, String itemName, String category, String newValue, String fieldToUpdate) async {
  var limit;
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var documentID = querySnapshot.docs.first.id;
        limit = querySnapshot.docs.first['limit'];
        FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(globalConnectCode)
            .collection(category)
            .doc(documentID)
            .update({fieldToUpdate: newValue});
      }
    });
    try {
      var parsedNumber;
      if (category == 'quantity'){
        parsedNumber = int.tryParse(newValue) ?? 0;
      }
      if (category == 'weight') {
        parsedNumber = toKgs(newValue);
      }
      int parsedLimit = int.tryParse(limit) ?? 2;
      if (parsedNumber < parsedLimit) {
        await FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(globalConnectCode)
            .collection('refill')
            .add({'title': itemName});
      }
      else {
        QuerySnapshot refillSnapshot = await FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(globalConnectCode)
            .collection('refill')
            .where('title', isEqualTo: itemName)
            .get();
        refillSnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      }
    } catch (e) {
      print('Error updating refill in Firebase: $e');
    }
    print('$fieldToUpdate updated successfully for $itemName');
  } catch (e) {
    print('Error updating $fieldToUpdate in Firebase: $e');
  }
}

double toKgs(String metric) {
  List<String> splitMetric = metric.split(" ");
  double value = double.parse(splitMetric[0]);
  String unit = splitMetric[1].toLowerCase();
  if (unit == "gms") {
    return value / 1000;
  } else if (unit == "kgs") {
    return value;
  } else {
    // Handle invalid unit
    return 0;
  }
}

String metricCalc(String metric1, String metric2, String operation) {
  // Function to convert metric to kilograms
  double toKgs(String metric) {
    List<String> splitMetric = metric.split(" ");
    double value = double.parse(splitMetric[0]);
    String unit = splitMetric[1].toLowerCase();
    if (unit == "gms") {
      return value / 1000;
    } else if (unit == "kgs") {
      return value;
    } else {
      // Handle invalid unit
      return 0;
    }
  }

  // Perform the operation based on the operation string
  if (operation == "normalize") {
    // Convert metric1 to kilograms and return
    return "${toKgs(metric1).toStringAsFixed(2)} kgs";
  } else {
    // Convert input metrics to kilograms
    double value1 = toKgs(metric1);
    double value2 = toKgs(metric2);

    // Perform the specified operation
    double result;
    if (operation == "add") {
      result = value1 + value2;
    } else if (operation == "subtract") {
      result = value1 - value2;
      if(result<=0){
        return "N/A";
      }
    } else {
      // Handle invalid operation
      return "N/A";
    }

    // Construct the result string in kgs
    return "${result.toStringAsFixed(2)} kgs";
  }
}

Future<void> deleteItemFromFirebase(String globalConnectCode, String itemName, String category) async {
  try {
    await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });
    print('Item $itemName in category $category deleted successfully.');
  } catch (e) {
    print('Error deleting item: $e');
  }
}


Future<Map<String, dynamic>?> fetchItemData(String globalConnectCode, String category, String itemName) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category)
        .where('title', isEqualTo: itemName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Assuming there's only one document for each item in the category
      var document = querySnapshot.docs.first;
      return {
        'quantity': document['quantity'],
        'weight': document['weight'],
      };
    } else {
      return null; // Item not found
    }
  } catch (e) {
    print('Error fetching item data from Firebase: $e');
    return null;
  }
}

Future<String?> fetchData(String response) async {
  if (response == null || response.isEmpty) { //checkChange
    return 'Start speaking into the mic';
  }
  String? globalConnectCode = await _getFirebaseCode();
  if (globalConnectCode == null) {
    print('Global connect code not found in SharedPreferences.');
    return 'We could not get your Access Code';
  }
  Map<String, dynamic> jsonResponse = jsonDecode(response);
  // '{"items":[{"category":"fruits","item":"banana","metric_weight":"3 kgs"}],"labels":["add","pantry"]}');
  //print(jsonResponse);
  var items = jsonResponse['items'];
  if (items.isEmpty) {
    return 'Didn\'t hear that. Try again.' /*phrases to try'*/;
  }
  var labels = jsonResponse['labels'];
  if (labels.contains('add') && labels.contains('pantry')) {
    // Retrieve the global connect code
    for (var item in items) {
      var itemName = item['item'] ?? null;
      var category = item['category'] ?? null;
      var quantity = item['quantity'] ?? null;
      var metricWeight = item['metric_weight'] ?? null;
      print(itemName);
      print(category);
      print(quantity);
      print(metricWeight);

      if (globalConnectCode.isNotEmpty && category.isNotEmpty) {
        // Check if item already exists
        bool exists = await checkIfItemExists(
          globalConnectCode,
          itemName,
          category,
        );

        if (exists) {
          print('$itemName in category $category already exists.');
          // Fetch the quantity and metric weight from Firebase
          String? existingQuantity = await getFieldFromFirebase(globalConnectCode, itemName, category, 'quantity');
          String? existingMetricWeight = await getFieldFromFirebase(globalConnectCode, itemName, category, 'weight');

          if (existingQuantity != null && existingQuantity != 'N/A' && quantity != null) {
            // Convert existing quantity to an integer, add new quantity, and save as a string to Firebase
            int existingQuantityInt = int.tryParse(existingQuantity) ?? 0;
            int newQuantityInt = int.tryParse(quantity) ?? 0;
            int totalQuantity = existingQuantityInt + newQuantityInt;
            await updateFieldInFirebase(globalConnectCode, itemName, category, totalQuantity.toString(),'quantity');
            print('$itemName has been added with quantity $totalQuantity successfully');
            return '$existingMetricWeight $itemName have been added, current quantity is $metricWeight'; //checkChange
          }
          else if (existingMetricWeight != null && existingMetricWeight != 'N/A' && metricWeight != null) {
            String result = metricCalc(existingMetricWeight, metricWeight, "add");
            await updateFieldInFirebase(globalConnectCode, itemName, category, result, 'weight');
            print('$itemName has been added with weight $existingMetricWeight successfully');
            return '$existingMetricWeight of $itemName has been added, current weight is $metricWeight';//checkChange
          }
          else {
            print('Both quantity and metric_weight for $itemName are N/A.');
            return 'No quantity or weight was provided, try again?'; //checkChange
          }
        }
        else {
          // Example: Adding data to Firestore
          await addFruit(
            globalConnectCode: globalConnectCode,
            itemName: itemName,
            category: category,
            quantity: quantity,
            metricWeight: metricWeight,
          );
        }
      }
      else {
        print('Error: globalConnectCode or category is null or empty.');
        return 'We could not get your Access Code or Item Category'; //checkChange
      }
    }
  }

  else if (labels.contains('add') && labels.contains('chores')) {

    for (var item in items) {
      var itemName = item['item'] ?? null; // Move itemName declaration here
      try {
        await FirebaseFirestore.instance
            .collection('sharedCollection')
            .doc(globalConnectCode)
            .collection('todos') // Subcollection name
            .add({
          'title': itemName,
          'description': ''
        });
        print('Item added to todos subcollection.');
        return 'Your to-do has been added successfully!'; //checkChange
      }
      catch (e) {
        print('Error adding item to todos subcollection: $e');
        return 'There was some problem in adding chores, Try again.'; //checkChange
      }
    }
  }

  else if (labels.contains('fetch')) {
    var response;
    for (var item in items) {
      var itemName = item['item'] ?? null;
      var category = item['category'] ?? null;

    if(items.isEmpty && category){
      var querySnapshot = await FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc(globalConnectCode)
          .collection(category)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs;
        print(document);
        return document as String;
      }
    }
    else {

        if (category.isNotEmpty) {
          var itemData = await fetchItemData(globalConnectCode, category, itemName);
          if (itemData != null) {
            response = response + '''\nItem Name: $itemName
              Quantity: ${itemData['quantity']}
              Weight: ${itemData['weight']}''';
          }
          else {
            print('Item $itemName not found in category $category.');
            return 'Item $itemName not found in category $category.';
          }
        }
        else {
          print('category is null or empty.');
          return 'category is null or empty.';
        }
      }
      return response;
    }
  }
  else if (labels.contains('remove') && labels.contains('pantry')) {
    print("Removing");
    // Retrieve the global connect code
    for (var item in items) {
      var itemName = item['item'] ?? null;
      var category = item['category'] ?? null;
      if (category.isEmpty) {
        print('Error: category is null or empty.');
        return 'We could not find any category for your item. Try again.';
      }
      var quantity = item['quantity'] ?? null;
      var metricWeight = item['metric_weight'] ?? null;
      print(itemName);
      print(category);
      print(quantity);
      print(metricWeight);
      // Check if item already exists
      bool exists = await checkIfItemExists(globalConnectCode,itemName,category);
      if (exists) {
        print('$itemName in category $category already exists.');
        // Fetch the quantity and metric weight from Firebase
        String? existingQuantity = await getFieldFromFirebase(globalConnectCode, itemName, category, 'quantity');
        String? existingMetricWeight = await getFieldFromFirebase(globalConnectCode, itemName, category, 'weight');

        if (existingQuantity != null && existingQuantity != 'N/A' && quantity != null) {
          // Convert existing quantity to an integer, add new quantity, and save as a string to Firebase
          int existingQuantityInt = int.tryParse(existingQuantity) ?? 0;
          int newQuantityInt = int.tryParse(quantity) ?? 0;
          int totalQuantity = (existingQuantityInt - newQuantityInt);
          if (totalQuantity <= 0) {
            await deleteItemFromFirebase(globalConnectCode, itemName, category);
            print('No Quantity, Removed $itemName from $category');
            return 'Removed $itemName from $category';
          }
          else {
            await updateFieldInFirebase(globalConnectCode, itemName, category,totalQuantity.toString(), 'quantity');
            print('Quantity for $itemName is not N/A: $totalQuantity');
          }
        }
        else if (existingMetricWeight != null && existingMetricWeight != 'N/A' && metricWeight != null) {
          String result = metricCalc(existingMetricWeight, metricWeight, "subtract");
          print(result);

          if (result == "N/A") {
            await deleteItemFromFirebase(globalConnectCode, itemName, category);
            print('No Weight, Removed $itemName from $category');
            return '$itemName has been removed';
          }
          else {
            await updateFieldInFirebase(globalConnectCode, itemName, category, result, 'weight');
            print('Metric weight for $itemName is not N/A: $existingMetricWeight');
            return '$existingMetricWeight has been removed from $itemName, current weight is $metricWeight';
          }
        }
        else {
          print('Both quantity and metric_weight for $itemName are N/A.');
          await deleteItemFromFirebase(globalConnectCode, itemName, category);
          print('No Quantity and Weight, Removed $itemName from $category');
          return 'Removed $itemName from $category';
        }
      }
      return 'Item could not be found. Try again?';
    }
  }
  else {
    print('The given case does not exist');
  }
}