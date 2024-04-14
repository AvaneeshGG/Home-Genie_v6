import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) async {
    await _todosCollection.doc(title).set({
      'title': title,
      'quantity': quantity,
      'weight': weight,
    });
  }

  Future<void> updateTodo({
    required String docId,
    required String title,
    required String quantity,
    required String weight,
  }) async {
    await _todosCollection.doc(docId).update({
      'title': title,
      'quantity': quantity,
      'weight': weight,
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

  FirebaseTodoList({required this.firebaseTodo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
              Map<String, dynamic> data =
              inventory.data() as Map<String, dynamic>;
              String weight = data['weight'] != null
                  ? data['weight'].toString()
                  : 'N/A';
              return ListTile(
                title: Text(documentName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight: $weight'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    firebaseTodo.deleteTodo(docId: inventory.id);
                  },
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
    if (selectedCategory != null && globalConnectCode != null) {
      firebaseTodo = FirebaseTodo(
        category: selectedCategory!,
        globalConnectCode: globalConnectCode!,
      );
      firebaseTodo!.addTodo(
        title: title,
        quantity: quantity,
        weight: weight,
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
              ),
            ),
            _buildExpandableSection(
              title: 'Vegetables',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'vegetables',
                  globalConnectCode: globalConnectCode ?? '',
                ),
              ),
            ),
            _buildExpandableSection(
              title: 'Daily Essentials',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'daily essentials',
                  globalConnectCode: globalConnectCode ?? '',
                ),
              ),
            ),
            _buildExpandableSection(
              title: 'Medicines',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'medicines',
                  globalConnectCode: globalConnectCode ?? '',
                ),
              ),
            ),
            _buildExpandableSection(
              title: 'Pulses',
              content: FirebaseTodoList(
                firebaseTodo: FirebaseTodo(
                  category: 'pulses',
                  globalConnectCode: globalConnectCode ?? '',
                ),
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
    String? _chosenValue;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? value) {
                  setState(() {
                    selectedCategory = value;
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
                _addItem();
                _titleController.clear();
                _quantityController.clear();
                _weightController.clear();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

