import 'package:flutter/material.dart';

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: selectedIndex == index ? Colors.green : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
            color: selectedIndex == index ? Colors.green : Colors.black),
      ),
      onTap: () {
        onTap(index);
        Navigator.pop(context);
      },
    );
  }
}
