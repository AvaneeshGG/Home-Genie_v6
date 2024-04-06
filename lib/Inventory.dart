import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

late String? selectedCategory = null;

class Inventory extends StatefulWidget {
  const Inventory({Key? key}) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  bool _isExpanded2 = false;
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late FirebaseTodo firebaseTodo;

  @override
  void initState() {
    super.initState();
    selectedCategory = 'Fruits'; // Initialize with a default category
    firebaseTodo = FirebaseTodo(category: selectedCategory);
    _titleController = TextEditingController();
    _quantityController = TextEditingController();
    _weightController = TextEditingController();
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
                    selectedCategory = value ?? 'Fruits'; // Handle null value
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

  void _addItem() {
    String title = _titleController.text; // Get the title from the text field
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
            _buildSection(
              title: 'Fruits',
              content: FirebaseTodoList(firebaseTodo: firebaseTodo),
              isExpanded: _isExpanded2,
              onTap: () {
                setState(() {
                  _isExpanded2 = !_isExpanded2;
                });
              },
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

  Widget _buildSection({
    required String title,
    required Widget content,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.blue,
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: isExpanded,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: content,
          ),
        ),
      ],
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
          .collection(category!); // Use the null assertion operator (!) to access the non-nullable string
    }
  }

  Future<void> addTodo({
    required String title,
    required String quantity,
    required String weight,
  }) async {
    await _todosCollection.doc(title).set({ // Use title as the document ID
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
      //elevation: 5,
      style: TextStyle(color: Colors.black),
      items: <String?>[
        null, // Add a null value to represent the hint
        'Fruits',
        'Vegetables',
        'Daily Essentials',
        'Medicines',
        'Pulses',
      ].map<DropdownMenuItem<String>>((String? value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value ?? 'Select Category'), // Use value ?? 'Select Category' to display the hint text
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _chosenValue = value;
          selectedCategory=_chosenValue;
          widget.onChanged(value);
        });
      },
    );
  }
}
