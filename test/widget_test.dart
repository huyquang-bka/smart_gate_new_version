import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MaterialApp(home: HistoryList()));
}

class HistoryItem {
  final String id;
  final String imagePath;
  final String text;

  HistoryItem({required this.id, required this.imagePath, required this.text});
}

class HistoryList extends StatefulWidget {
  const HistoryList({Key? key}) : super(key: key);

  @override
  _HistoryListState createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  List<HistoryItem> history = [];
  final ImagePicker _picker = ImagePicker();
  XFile? capturedImage;
  final TextEditingController _textController = TextEditingController();

  void _showItemDialog(HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.text),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(item.imagePath)),
            SizedBox(height: 16),
            Text(item.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        capturedImage = image;
      });
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (capturedImage != null)
                  Stack(
                    children: [
                      Image.file(File(capturedImage!.path)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => setState(() => capturedImage = null),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      await _captureImage();
                      setState(() {});
                    },
                    child: Text('Take Picture'),
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(hintText: 'Enter description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                capturedImage = null;
                _textController.clear();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (capturedImage != null && _textController.text.isNotEmpty) {
                  setState(() {
                    history.add(HistoryItem(
                      id: DateTime.now().toString(),
                      imagePath: capturedImage!.path,
                      text: _textController.text,
                    ));
                  });
                  Navigator.of(context).pop();
                  capturedImage = null;
                  _textController.clear();
                }
              },
              child: Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History List')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...history.map((item) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _showItemDialog(item),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Image.file(File(item.imagePath), fit: BoxFit.cover),
                    ),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _showAddDialog,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
