import 'package:flutter/material.dart';

class ThemeAction extends StatelessWidget {
  final VoidCallback tema;

  const ThemeAction({Key? key, required this.tema}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.brightness_6),
      onPressed: tema, // chama a função passada
    );
  }
}