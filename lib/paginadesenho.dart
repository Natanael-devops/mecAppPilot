import 'package:flutter/material.dart';
import 'package:mecapp/bodypagina.dart';
import 'package:mecapp/models/produto.dart';
import 'package:mecapp/repositories/produto.dart';
import 'package:mecapp/trocar_tema.dart';
import 'package:pdfrx/pdfrx.dart';

class PaginaDesenho extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const PaginaDesenho({super.key, required this.onToggleTheme});
  

  @override
  State<PaginaDesenho> createState() => _PaginaDesenhoState();
}

class _PaginaDesenhoState extends State<PaginaDesenho> {
  Produto? selecionado;

  @override
  Widget build(BuildContext context) {
    final tabela = ProdutoRepository.tabela;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text('MecMap - LemanBR'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              
              onPressed: (){
                //preencher
              },
               icon: const Icon(Icons.search),
               ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ThemeAction(tema: widget.onToggleTheme,),
          ), // usa o widget externo

        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              
              children: [
                Expanded(
                  child: PdfViewer.asset(
                    'arquivo.pdf',
                    params: PdfViewerParams(),
                     ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.separated(
              padding: const EdgeInsets.all(5),
              itemCount: tabela.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (BuildContext context, int i) {
                final item = tabela[i];
                final isSelected = selecionado == item;
                return ListTile(
                  title: Text(item.texto_breve),
                  subtitle: Text(
                    "Posição: ${item.posicao} | Qtde: ${item.quantidade_lista} | "
                    "Estoque: ${item.quantidadade_estoque} | Code Stock: ${item.code_stock}",
                  ),
                  trailing: const Icon(Icons.shopping_cart),
                  selected: isSelected,
                  selectedTileColor: Colors.indigo[50],
                  selectedColor: Colors.red,
                  onTap: () {
                    setState(() {
                      selecionado = item;
                    });
                    debugPrint(selecionado?.texto_breve);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}