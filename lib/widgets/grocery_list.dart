import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';

import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    // _loadItems()が一度だけ実行されるようにするため
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-233fb-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
    }

    if (response.body == 'null') {
      return [];
    }

    // decodeで、json形式のデータをmap形式のデータに変換する
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final cateogy = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: item.value['quantity'],
        category: cateogy,
      ));
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (context) => const NewItem()));
    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        // shopping-listの一部分だけ消したいので、後ろに/をつける
        'flutter-prep-233fb-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      // FutureBuilderウィジェットを使用すると、新しい項目を追加しても、画面が更新されないので追加した項目が表示されない....理想的ではないかも...
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items added yet.'),
            );
          }
          return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => Dismissible(
                    key: ValueKey(snapshot.data![index].id),
                    onDismissed: (direction) {
                      _removeItem(snapshot.data![index]);
                    },
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      color: const Color.fromARGB(190, 244, 67, 54),
                    ),
                    child: ListTile(
                      leading: Container(
                        height: 24,
                        width: 24,
                        color: snapshot.data![index].category.color,
                      ),
                      title: Text(
                        snapshot.data![index].name,
                      ),
                      trailing: Text(
                        snapshot.data![index].quantity.toString(),
                      ),
                    ),
                  ));
        },
      ),
    );
  }
}
