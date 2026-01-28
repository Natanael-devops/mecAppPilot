import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BodyPagina extends StatelessWidget {
  const BodyPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            InteractiveViewer(
              maxScale: 8,
              child: SvgPicture.asset(
                'teste.svg',
                width: 240,
                fit: BoxFit.contain,

                ),
              
              )
          ],
        ),
        Column(
          children: [
            Text('coluna da lista')
          ],
        )
      ],
    );
  }
}