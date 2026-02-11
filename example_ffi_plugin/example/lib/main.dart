import 'package:flutter/material.dart';

import 'package:native_example/native_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wasm FFI Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('universal_ffi tests')),
      body: const Column(
        children: [
          Expanded(child: AsyncRunnerWidget('emscripten/native_example.js')),
          Expanded(child: AsyncRunnerWidget('standalone/native_example.wasm')),
        ],
      ),
    );
  }
}

class AsyncRunnerWidget extends StatefulWidget {
  final String libPath;
  const AsyncRunnerWidget(this.libPath, {super.key});

  @override
  State<AsyncRunnerWidget> createState() => _AsyncRunnerWidgetState();
}

class _AsyncRunnerWidgetState extends State<AsyncRunnerWidget> {
  final Map<String, String> _data = {};

  // Simulated asynchronous runner.
  Future<Map<String, String>> fetchValues() async {
    await init(widget.libPath);
    return {
      'Library Name': getLibraryName(),
      'Hello String': hello(widget.libPath),
      'Size of Int': sizeOfInt().toString(),
      'Size of Bool': sizeOfBool().toString(),
      'Size of Pointer': sizeOfPointer().toString(),
      'Static Init Check': staticInitCheck().toString(),
    };
  }

  // Load data using the asynchronous runner
  Future<void> _loadData() async {
    final values = await fetchValues();
    setState(() {
      _data.clear();
      _data.addAll(values);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData(); // Automatically fetch data on initialization
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test ${widget.libPath}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (_data.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ..._data.entries.map(
                  (entry) => Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
