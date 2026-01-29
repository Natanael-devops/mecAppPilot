import 'package:flutter/material.dart';
import 'package:mecapp/models/produto.dart';
import 'package:mecapp/repositories/produto.dart';
import 'package:mecapp/trocar_tema.dart';
import 'package:pdfrx/pdfrx.dart';

class PaginaDesenho extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String initialPdf;

  const PaginaDesenho({
    super.key,
    required this.onToggleTheme,
    required this.initialPdf,
  });

  @override
  State<PaginaDesenho> createState() => _PaginaDesenhoState();
}

class _PaginaDesenhoState extends State<PaginaDesenho> {
  Produto? selecionado;

  final ScrollController _listaController = ScrollController();
  final PdfViewerController _pdfController = PdfViewerController();

  late String currentPdf;

  // Mapa para guardar os rects de cada posição
  final Map<int, List<PdfRect>> _posicaoRects = {};

  @override
  void initState() {
    super.initState();
    currentPdf = widget.initialPdf;
  }

  Future<void> _zoomLeveNoLink(List<PdfRect> rects) async {
    if (rects.isEmpty) return;
    final rect = rects.first;
    final center = rect.center;
    final offset = Offset(center.x, center.y);
    await _pdfController.zoomOnLocalPosition(
      localPosition: offset,
      newZoom: 1.9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itensFiltrados = ProdutoRepository.tabela
        .where((p) => p.arquivo == currentPdf)
        .toList()
      ..sort((a, b) => a.posicao.compareTo(b.posicao));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('MecMap - LemanBR'),
        actions: [
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: PdfViewer.asset(
                currentPdf,
                key: ValueKey(currentPdf),
                controller: _pdfController,
                params: PdfViewerParams(
                  linkWidgetBuilder: (context, link, size) {
                    final uri = link.url;
                    if (uri != null &&
                        uri.scheme == 'app' &&
                        uri.host == 'posicao') {
                      final seg = uri.pathSegments.isNotEmpty
                          ? uri.pathSegments.first
                          : null;
                      final pos = int.tryParse(seg ?? '');
                      if (pos != null) {
                        // guarda os rects dessa posição
                        _posicaoRects[pos] = link.rects;

                        return Tooltip(
                          message: 'Posição $pos (clique)',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final tabela = ProdutoRepository.tabela;
                              final produto = tabela.firstWhere(
                                  (p) => p.posicao == pos,
                                  orElse: () => Produto.vazio());

                              setState(() {
                                selecionado = produto;
                              });

                              if (produto.unidade_medida == 'CJ') {
                                final abrir = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                        'Abrir desenho da posição ${produto.posicao}?'),
                                    content: Text(
                                        'Este item é um conjunto (CJ). Deseja abrir o arquivo ${produto.posicao}.pdf?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Não'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Sim'),
                                      ),
                                    ],
                                  ),
                                );

                                if (abrir == true) {
                                  setState(() {
                                    currentPdf = '${produto.posicao}.pdf';
                                  });
                                } else {
                                  await _zoomLeveNoLink(link.rects);
                                }
                              } else {
                                await _zoomLeveNoLink(link.rects);
                              }
                            },
                            child: const SizedBox.expand(),
                          ),
                        );
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),

          // COLUNA DIREITA: LISTA DE ITENS
          Expanded(
            flex: 3,
            child: ListView.separated(
              controller: _listaController,
              padding: const EdgeInsets.all(5),
              itemCount: itensFiltrados.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) {
                final item = itensFiltrados[i];
                final isSelected = selecionado == item;

                return ListTile(
                  title: Text(item.texto_breve),
                  subtitle: Text(
                    "Posição: ${item.posicao} | Qtde: ${item.quantidade_lista} | "
                    "Estoque: ${item.quantidadade_estoque} | Code Stock: ${item.code_stock} | "
                    "Unidade: ${item.unidade_medida} | Arquivo: ${item.arquivo}",
                  ),
                  trailing: const Icon(Icons.shopping_cart),
                  selected: isSelected,
                  selectedTileColor: Colors.indigo[50],
                  selectedColor: Colors.red,
                  onTap: () async {
                    setState(() {
                      selecionado = item;
                    });

                    if (item.unidade_medida == 'CJ') {
                      final abrir = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Abrir desenho da posição ${item.posicao}?'),
                          content: Text(
                              'Este item é um conjunto (CJ). Deseja abrir o arquivo ${item.posicao}.pdf?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Não'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sim'),
                            ),
                          ],
                        ),
                      );

                      if (abrir == true) {
                        setState(() {
                          currentPdf = '${item.posicao}.pdf';
                        });
                      } else {
                        // usa os rects guardados
                        final rects = _posicaoRects[item.posicao];
                        if (rects != null) {
                          await _zoomLeveNoLink(rects);
                        } else {
                          await _pdfController.zoomUp();
                        }
                      }
                    } else {
                      final rects = _posicaoRects[item.posicao];
                      if (rects != null) {
                        await _zoomLeveNoLink(rects);
                      } else {
                        await _pdfController.zoomUp();
                      }
                    }
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