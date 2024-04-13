import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Inventory(),
    );
  }
}

class FirebaseTodo {
  final String? category;
  late CollectionReference _todosCollection;

  FirebaseTodo({required this.category}) {
    if (category != null) {
      _todosCollection = FirebaseFirestore.instance
          .collection('sharedCollection')
          .doc('405898')
          .collection(category!);
    }
  }

  Future<void> addTodo({
    required String title,
    required String quantity,
    required String weight,
  }) async {
    await _todosCollection.doc(title).set({
      'quantity': quantity,
      'weight': weight,
      'category': category,
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

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late FirebaseTodo firebaseTodo;
  String? selectedCategory;
  List<bool> _isOpenList = [false, false, false, false, false]; // Keeps track of expansion state
  List<int> _expandedIndices = [-1]; // Track currently expanded panel index

  @override
  void initState() {
    super.initState();
    selectedCategory = 'Fruits';
    firebaseTodo = FirebaseTodo(category: selectedCategory);
    _titleController = TextEditingController();
    _quantityController = TextEditingController();
    _weightController = TextEditingController();
  }

  void _addItem() {
    String title = _titleController.text;
    firebaseTodo.addTodo(
      title: title,
      quantity: _quantityController.text,
      weight: _weightController.text,
    );
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
              content: FirebaseTodoList(firebaseTodo: FirebaseTodo(category: 'Fruits')),
              index: 0,
            ),
            _buildExpandableSection(
              title: 'Vegetables',
              content: FirebaseTodoList(firebaseTodo: FirebaseTodo(category: 'Vegetables')),
              index: 1,
            ),
            _buildExpandableSection(
              title: 'Daily Essentials',
              content: FirebaseTodoList(firebaseTodo: FirebaseTodo(category: 'Daily Essentials')),
              index: 2,
            ),
            _buildExpandableSection(
              title: 'Medicines',
              content: FirebaseTodoList(firebaseTodo: FirebaseTodo(category: 'Medicines')),
              index: 3,
            ),
            _buildExpandableSection(
              title: 'Pulses',
              content: FirebaseTodoList(firebaseTodo: FirebaseTodo(category: 'Pulses')),
              index: 4,
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
    required int index,
  }) {
    return ExpansionPanelList.radio(
      elevation: 2,
      expandedHeaderPadding: EdgeInsets.all(10),
      children: [
        ExpansionPanelRadio(
          value: index,
          headerBuilder: (context, isExpanded) {
            return Container(
              color: Colors.blue, // Set the background color here
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          },
          body: content,
          canTapOnHeader: true,
        ),
      ],
      expansionCallback: (int item, bool isExpanded) {
        setState(() {
          _expandedIndices.clear(); // Clear previous expansion
          if (!isExpanded) {
            _expandedIndices.add(item);
          }
        });
      },
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
              DropDownDemo(
                onChanged: (String? value) {
                  _chosenValue = value;
                  setState(() {
                    selectedCategory = value ?? 'Fruits';
                    firebaseTodo = FirebaseTodo(category: selectedCategory);
                  });
                },
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

class DropDownDemo extends StatefulWidget {
  final Function(String?) onChanged;

  DropDownDemo({required this.onChanged});

  @override
  _DropDownDemoState createState() => _DropDownDemoState();
}

class _DropDownDemoState extends State<DropDownDemo> {
  String? _chosenValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        value: _chosenValue,
        items: <String?>[
          null,
          'Fruits',
          'Vegetables',
          'Daily Essentials',
          'Medicines',
          'Pulses',
        ].map<DropdownMenuItem<String>>((String? value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value ?? 'Select Category'),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() {
            _chosenValue = value;
            widget.onChanged(value);
          });
          },
        );
    }
}