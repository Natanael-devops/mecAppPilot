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

  // ===== CORREÇÃO: cache de rects por PDF =====
  final Map<String, Map<int, List<PdfRect>>> _rectsPorPdf = {};
  Map<int, List<PdfRect>> _rectsAtuais() =>
      _rectsPorPdf[currentPdf] ??= <int, List<PdfRect>>{};

  // ===== NOVO: histórico de PDFs para voltar ao desenho anterior =====
  final List<String> _pdfHistory = [];

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
              // ===== ALTERAÇÃO: empacotar o PdfViewer.asset em um Stack para incluir o botão "Voltar" =====
              child: Stack(
                children: [
                  PdfViewer.asset(
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
                            // ===== CORREÇÃO: guardar rects por PDF atual =====
                            _rectsAtuais()[pos] = List<PdfRect>.from(link.rects);

                            return Tooltip(
                              message: 'Posição $pos (clique)',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  // ===== NOVO: checar se existe item com essa posição no currentPdf =====
                                  final possiveis = ProdutoRepository.tabela
                                      .where((p) =>
                                          p.arquivo == currentPdf &&
                                          p.posicao == pos)
                                      .toList();

                                  if (possiveis.isEmpty) {
                                    // Mensagem padrão solicitada
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Não há na lista técnica um item com a posição $pos nesse desenho.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ===== CORREÇÃO: buscar produto filtrando pelo currentPdf =====
                                  final produto = possiveis.first;

                                  setState(() {
                                    selecionado = produto;
                                  });

                                  if (produto.unidade_medida == 'CJ') {
                                    final abrir = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                            'Abrir desenho do item ${produto.texto_breve}?'),
                                        content: Text(
                                            'Este item é um conjunto (CJ). Deseja abrir o Desenho ${produto.desenho} para ver os detalhes do conjunto?'),
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
                                        // ===== NOVO: empilhar o PDF atual antes de navegar =====
                                        _pdfHistory.add(currentPdf);
                                        currentPdf = '${produto.desenho}.pdf';
                                        // Zera seleção ao trocar de PDF (evita estado antigo)
                                        selecionado = null;
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

                  // ===== NOVO: Botão "Voltar" ao desenho anterior =====
                  if (_pdfHistory.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: Tooltip(
                          message: 'Voltar ao desenho anterior',
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              elevation: 2,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar'),
                            onPressed: () {
                              if (_pdfHistory.isNotEmpty) {
                                setState(() {
                                  currentPdf = _pdfHistory.removeLast();
                                  selecionado = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                ],
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
                          title: Text('Abrir desenho da posição ${item.arquivo}?'),
                          content: Text(
                              'Este item é um conjunto (CJ). Deseja abrir o Desenho ${item.desenho} para ver os detalhes do conjunto?'),
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
                          // ===== NOVO: empilhar o PDF atual antes de navegar =====
                          _pdfHistory.add(currentPdf);
                          currentPdf = '${item.desenho}.pdf';
                          // Zera seleção ao trocar de PDF (evita estado antigo)
                          selecionado = null;
                        });
                      } else {
                        // ===== CORREÇÃO: usar rects do PDF atual =====
                        final rects = _rectsAtuais()[item.posicao];
                        if (rects != null) {
                          await _zoomLeveNoLink(rects);
                        } else {
                          await _pdfController.zoomUp();
                        }
                      }
                    } else {
                      // ===== CORREÇÃO: usar rects do PDF atual =====
                      final rects = _rectsAtuais()[item.posicao];
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