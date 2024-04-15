import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FirebaseTodo {
  late CollectionReference _todosCollection;

  FirebaseTodo({required String category, required String globalConnectCode}) {
    _todosCollection = FirebaseFirestore.instance
        .collection('sharedCollection')
        .doc(globalConnectCode)
        .collection(category);
  }

  Future<void> addTodo({
    required String title,
    required String quantity,
    required String weight,
    required String limit,
  }) async {
    await _todosCollection.add({
      'title': title,
      'quantity': quantity,
      'weight': weight,
      'limit': limit,
    });
  }

  Future<void> updateTodo({
    required String docId,
    required String title,
    required String quantity,
    required String weight,
    required String limit,
  }) async {
    // Ensure that docId is not empty or null
    assert(docId.isNotEmpty);

    await _todosCollection.doc(docId).update({
      'title': title,
      'quantity': quantity,
      'weight': weight,
      'limit': limit,
    });
  }

  Future<void> deleteTodo({
    required String docId,
  }) async {
    await _todosCollection.doc(docId).delete();
  }

  Stream<QuerySnapshot> getTodos() {
    return _todosCollection.snapshots();
  }
}

class FirebaseTodoList extends StatelessWidget {
  final FirebaseTodo firebaseTodo;
  final Function(BuildContext, String, String, String, String, String) showEditDialog;

  FirebaseTodoList({
    required this.firebaseTodo,
    required this.showEditDialog,
  });

  Color _calculateBackgroundColor(String quantity, String weight, String limit) {
    bool isQuantityNA = quantity == 'N/A';
    bool isWeightNA = weight == 'N/A';

    if (isQuantityNA && isWeightNA) {
      return Colors.white;
    } else {
      int parsedQuantity = isQuantityNA ? 0 : int.tryParse(quantity) ?? 0;
      int parsedWeight = isWeightNA ? 0 : int.tryParse(weight) ?? 0;
      int parsedLimit = int.tryParse(limit) ?? 2;

      if ((isQuantityNA && parsedWeight < parsedLimit) || (isWeightNA && parsedQuantity < parsedLimit)) {
        return Colors.red[100] ?? Colors.red;
      } else {
        return Colors.white;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement your refresh logic here
        // For example, you could fetch new data from Firebase
        // or reload the existing data
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: firebaseTodo.getTodos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var todos = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: todos.length,
              itemBuilder: (context, index) {
                var inventory = todos[index];
                String documentName = inventory.id;
                Map<String, dynamic> data = inventory.data() as Map<String, dynamic>;
                String title = data['title'] != null ? data['title'].toString() : 'Untitled'; // Get the title from data
                String weight = data['weight'] != null ? data['weight'].toString() : 'N/A';
                String limit = data['limit'] != null ? data['limit'].toString() : '2';
                String quantity = data['quantity'] != null ? data['quantity'].toString() : 'N/A';

                // Determine the background color based on the quantity and the limit
                Color backgroundColor = _calculateBackgroundColor(quantity, weight, limit);

                return Slidable(
                  actionPane: SlidableDrawerActionPane(),
                  actions: [
                    IconSlideAction(
                      caption: 'Edit',
                      color: Colors.green,
                      icon: Icons.edit,
                      onTap: () {
                        showEditDialog(context, documentName, quantity, weight, title, limit);
                      },
                    ),
                  ],
                  secondaryActions: <Widget>[
                    IconSlideAction(
                      caption: 'Delete',
                      color: Colors.red,
                      icon: Icons.delete,
                      onTap: () {
                        firebaseTodo.deleteTodo(docId: inventory.id);
                      },
                    ),
                  ],
                  child: Container(
                    color: backgroundColor, // Set the background color
                    child: ListTile(
                      title: Text(title), // Display title instead of documentName
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity: $quantity'),
                          Text('Weight: $weight'),
                          Text('Limit: $limit'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late TextEditingController _limitController;
  String? selectedCategory;
  String? globalConnectCode;
  FirebaseTodo? firebaseTodo;

  @override
  void initState() {
    super.initState();
    selectedCategory = 'fruits';
    _getGlobalConnectCode();
    _titleController = TextEditingController();
    _quantityController = TextEditingController();
    _weightController = TextEditingController();
    _limitController = TextEditingController();
  }

  void _getGlobalConnectCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      globalConnectCode = prefs.getString('globalConnectCode');
    });
  }

  void _addItem() {
    String title = _titleController.text;
    String quantity = _quantityController.text;
    String weight = _weightController.text;
    String limit = _limitController.text;
    if (selectedCategory != null && globalConnectCode != null) {
      firebaseTodo = FirebaseTodo(
        category: selectedCategory!,
        globalConnectCode: globalConnectCode!,
      );
      firebaseTodo!.addTodo(
        title: title,
        quantity: quantity,
        weight: weight,
        limit: limit,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildExpandableSection(
              title: 'Fruits',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'fruits',
                  globalConnectCode: globalConnectCode ?? '',
                ),
                showEditDialog: _showEditDialog,
              ),
            ),
            _buildExpandableSection(
              title: 'Vegetables',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'vegetables',
                  globalConnectCode: globalConnectCode ?? '',
                ),
                showEditDialog: _showEditDialog,
              ),
            ),
            _buildExpandableSection(
              title: 'Daily Essentials',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'daily essentials',
                  globalConnectCode: globalConnectCode ?? '',
                ),
                showEditDialog: _showEditDialog,
              ),
            ),
            _buildExpandableSection(
              title: 'Medicines',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'medicines',
                  globalConnectCode: globalConnectCode ?? '',
                ),
                showEditDialog: _showEditDialog,
              ),
            ),
            _buildExpandableSection(
              title: 'Pulses',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'pulses',
                  globalConnectCode: globalConnectCode ?? '',
                ),
                showEditDialog: _showEditDialog,
              ),
            ),
            Text(
              'Global Connect Code: ${globalConnectCode ?? "Not Available"}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddDialog(context);
        },
        label: Text('Add'),
        icon: Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Colors.blue,
        elevation: 2.0,
        tooltip: 'Add a new item',
        isExtended: true,
        splashColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required Widget content,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 20.0),
      ),
      children: [
        content,
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    String? _chosenValue = selectedCategory;

    // Clear text controllers
    _titleController.clear();
    _quantityController.clear();
    _weightController.clear();
    _limitController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _chosenValue,
                    onChanged: (String? value) {
                      setState(() {
                        _chosenValue = value;
                      });
                    },
                    items: <String>[
                      'fruits',
                      'vegetables',
                      'daily essentials',
                      'medicines',
                      'pulses'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Item Name'),
                  ),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight'),
                  ),
                  TextField(
                    controller: _limitController,
                    decoration: InputDecoration(labelText: 'Limit'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = _chosenValue;
                    });
                    _addItem();
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, String documentId,
      String quantity, String weight, String title, String limit) async {
    if (documentId.isEmpty) {
      // If documentId is empty, show an error message or handle the situation accordingly
      print('Error: Document ID is empty');
      return;
    }

    // Set initial values for the TextFields
    _titleController.text = title.isNotEmpty ? title : 'Untitled';
    _quantityController.text = quantity.isNotEmpty ? quantity : '0';
    _weightController.text = weight.isNotEmpty ? weight : '0';
    _limitController.text = limit.isNotEmpty ? limit : '2';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
              ),
              TextField(
                controller: _limitController,
                decoration: InputDecoration(labelText: 'Limit'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String newTitle = _titleController.text;
                String newQuantity = _quantityController.text.isNotEmpty ? _quantityController.text : 'N/A';
                String newWeight = _weightController.text.isNotEmpty ? _weightController.text : 'N/A';
                String newLimit = _limitController.text;
                _updateItem(documentId, newTitle, newQuantity, newWeight, newLimit); // Pass the limit parameter
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateItem(String documentId, String title, String quantity, String weight, String limit) async {
    if (documentId.isNotEmpty && title.isNotEmpty) { // Ensure both documentId and title are not empty
      if (selectedCategory != null && globalConnectCode != null) {
        firebaseTodo = FirebaseTodo(
          category: selectedCategory!,
          globalConnectCode: globalConnectCode!,
        );

        // Update the document with the new title and limit
        await firebaseTodo!.updateTodo(
          docId: documentId, // Use the original document ID
          title: title,
          quantity: quantity,
          weight: weight,
          limit: limit, // Pass the limit value
        );

        // Refresh the page by calling setState
        setState(() {});
      }
    } else {
      print('Error: Document ID or title is empty');
    }
  }
}
