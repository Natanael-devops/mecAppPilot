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

  // Controlador para rolar a lista até o item selecionado
  final ScrollController _listaController = ScrollController();

  // Controlador do PdfViewer (pode ser útil depois para zoom/ir até área)
  final PdfViewerController _pdfController = PdfViewerController();

  void onSelectPos(int? pos) {
    if (pos == null) return;

    final tabela = ProdutoRepository.tabela;
    final index = tabela.indexWhere((p) => p.posicao == pos);

    if (index >= 0) {
      setState(() {
        selecionado = tabela[index];
      });

      // Rola a lista para o item
      _listaController.animateTo(
        (index * 72.0).clamp(0, _listaController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );

      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posição $pos selecionada: ${selecionado!.texto_breve}'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posição $pos não encontrada na lista.'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabela = ProdutoRepository.tabela;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('MecMap - LemanBR'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                // TODO: implementar busca (opcional)
              },
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ThemeAction(tema: widget.onToggleTheme),
          ),
        ],
      ),
      body: Row(
        children: [
          // COLUNA ESQUERDA: PDF
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Expanded(
                  child: PdfViewer.asset(
                    // Se o seu PDF de teste com hyperlink tiver outro nome, ajuste aqui:
                    'arquivo.pdf',
                    controller: _pdfController,
                    params: PdfViewerParams(
                      // Intercepta cada área de link e injeta um GestureDetector
                      linkWidgetBuilder: (context, link, size) {
                        final uri = link.url;
                        if (uri != null && uri.scheme == 'app' && uri.host == 'posicao') {
                          final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
                          final pos = int.tryParse(seg ?? '');
                          if (pos != null) {
                            return Tooltip(
                              message: 'Posição $pos (clique)',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onSelectPos(pos),
                                child: const SizedBox.expand(),
                              ),
                            );
                          }
                        }
                        // Retorne null para manter o comportamento padrão de links http/https etc.
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // COLUNA DIREITA: LISTA DE ITENS (BOM)
          Expanded(
            flex: 3,
            child: ListView.separated(
              controller: _listaController,
              padding: const EdgeInsets.all(5),
              itemCount: tabela.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
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
                    // Se você quiser ir do item -> posição no PDF no futuro,
                    // aqui você poderá chamar algo como:
                    // irParaPosicaoNoPdf(item.posicao)
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
