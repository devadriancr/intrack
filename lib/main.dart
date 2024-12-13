import 'package:flutter/material.dart';
import 'views/container_list_view.dart';

void main() {
  runApp(MaterialApp(
    title: 'Material Scanning',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: ContainerListView(),
  ));
}
