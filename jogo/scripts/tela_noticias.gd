extends TelaCheia
## Tela cheia de notícias: histórico completo das notícias do mercado.


func _titulo() -> String:
	return "Notícias do mercado"


func _construir() -> void:
	Market.noticias_mudou.connect(_atualizar)


func _atualizar() -> void:
	limpar(conteudo)

	if Market.noticias.is_empty():
		conteudo.add_child(criar_label(
			"Nenhuma notícia ainda. Avance o dia para acompanhar o mercado!", 18, COR_NEUTRA))
		return

	for n: Dictionary in Market.noticias:
		conteudo.add_child(_criar_linha(n))


func _criar_linha(n: Dictionary) -> Control:
	var positiva: bool = n["positiva"]
	var ticker: String = n["ticker"]
	var acao: Stock = Market.buscar(ticker)
	var impacto: float = Market.IMPACTO_NOTICIA * 100.0
	if not positiva:
		impacto = -impacto

	var cartao := criar_cartao()
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 20)
	cartao.get_child(0).add_child(linha)

	var dia := criar_label("Dia %d" % n["dia"], 15, COR_NEUTRA)
	dia.custom_minimum_size = Vector2(70, 0)
	linha.add_child(dia)

	var texto := criar_label(n["texto"], 18)
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_child(texto)

	linha.add_child(criar_label(ticker, 16, COR_NEUTRA))
	linha.add_child(criar_label("%+.0f%%" % impacto, 16, COR_BOA if positiva else COR_RUIM))
	if acao != null:
		linha.add_child(criar_label("R$ %.2f" % acao.preco, 16))
	return cartao
