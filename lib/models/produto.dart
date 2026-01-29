class Produto {
  String desenho;
  String arquivo;
  int pagina;
  int code_stock;
  double posicao;
  double quantidade_lista;
  String texto_breve;
  int quantidadade_estoque;
  String unidade_medida;

  Produto({
    required this.desenho,
    required this.arquivo,
    required this.pagina,
    required this.code_stock,
    required this.posicao,
    required this.quantidade_lista,
    required this.texto_breve,
    required this.quantidadade_estoque,
    required this.unidade_medida
  });


  factory Produto.vazio() {
    return Produto(
      posicao: -1,
      texto_breve: '',
      desenho: '',
      quantidade_lista: 0,
      quantidadade_estoque: 0,
      code_stock: 0,
      unidade_medida: '',
      arquivo: '',
      pagina: 0
    );
  }

}
