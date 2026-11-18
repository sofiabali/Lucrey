
extends "res://scripts/tela_cheia.gd"

const VERDE := Color(0.18, 0.80, 0.44)
const VERMELHO := Color(0.95, 0.30, 0.35)
const AZUL := Color(0.20, 0.75, 0.95)
const CINZA_LINHA := Color(0.35, 0.42, 0.50, 0.40)

var ticker_selecionado: String = "PETR4"
var grafico_atual: Control


func _titulo() -> String:
	return "Cotações"


func _construir() -> void:
	Market.dia_avancou.connect(_ao_avancar_dia)


func _ao_avancar_dia(_dia: int) -> void:
	_atualizar()


func _atualizar() -> void:
	if conteudo == null:
		return

	limpar(conteudo)

	conteudo.add_child(
		criar_label(
			"Acompanhe os preços das ações e suas variações.",
			17,
			COR_NEUTRA
		)
	)

	conteudo.add_child(
		criar_label(
			"Dia atual: %d" % Market.dia,
			18,
			COR_ALERTA
		)
	)

	conteudo.add_child(
		criar_label("Ações disponíveis", 23, COR_BOA)
	)

	for acao in Market.acoes:
		conteudo.add_child(_criar_linha_acao(acao))

	conteudo.add_child(HSeparator.new())

	conteudo.add_child(
		criar_label("Histórico das cotações", 24, COR_BOA)
	)

	# Botoes para selecionar a empresa
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 10)
	conteudo.add_child(botoes)

	for acao in Market.acoes:
		var botao := Button.new()
		botao.text = acao.ticker
		botao.custom_minimum_size = Vector2(120, 42)

		if acao.ticker == ticker_selecionado:
			botao.disabled = true

		botao.pressed.connect(
			_selecionar_acao.bind(acao.ticker)
		)

		botoes.add_child(botao)

	var selecionada: Stock = Market.buscar(ticker_selecionado)

	if selecionada == null:
		return

	conteudo.add_child(
		criar_label(
			selecionada.nome + " (" + selecionada.ticker + ")",
			22,
			COR_TEXTO
		)
	)

	conteudo.add_child(
		criar_label(
			"Preço atual: R$ %.2f" % selecionada.preco,
			20,
			COR_TEXTO
		)
	)

	var precos: Array[float] = []

	for valor in selecionada.historico:
		precos.append(float(valor))

	if precos.is_empty():
		precos.append(selecionada.preco)

	var variacao_total := 0.0

	if precos[0] > 0.0:
		variacao_total = (
			selecionada.preco / precos[0] - 1.0
		) * 100.0

	var cor: Color = VERDE if variacao_total >= 0 else VERMELHO

	conteudo.add_child(
		criar_label(
			"Variação desde o início: %+.2f%%" % variacao_total,
			18,
			cor
		)
	)

	conteudo.add_child(_criar_grafico(precos))

	conteudo.add_child(
		criar_label(
			"Passe o mouse sobre os pontos para ver o dia e o preço.",
			15,
			COR_NEUTRA
		)
	)


func _criar_linha_acao(acao: Stock) -> PanelContainer:
	var cartao := criar_cartao(10)
	var linha := HBoxContainer.new()
	cartao.get_child(0).add_child(linha)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	textos.add_child(
		criar_label(
			acao.ticker + " - " + acao.nome,
			19
		)
	)

	textos.add_child(
		criar_label(
			"Cotação: R$ %.2f" % acao.preco,
			16,
			COR_NEUTRA
		)
	)

	linha.add_child(textos)

	var variacao: float = Market.variacao_diaria(acao.ticker)
	var cor: Color = VERDE if variacao >= 0 else VERMELHO

	linha.add_child(
		criar_label("%+.2f%%" % variacao, 18, cor)
	)

	var botao := Button.new()
	botao.text = "VER GRÁFICO"
	botao.custom_minimum_size = Vector2(145, 38)
	botao.disabled = acao.ticker == ticker_selecionado

	botao.pressed.connect(
		_selecionar_acao.bind(acao.ticker)
	)

	linha.add_child(botao)
	return cartao


func _selecionar_acao(ticker: String) -> void:
	ticker_selecionado = ticker
	_atualizar()


func _criar_grafico(precos: Array[float]) -> Control:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(0, 340)

	var grafico := Control.new()
	grafico.custom_minimum_size = Vector2(0, 320)
	grafico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grafico.mouse_filter = Control.MOUSE_FILTER_STOP

	painel.add_child(grafico)
	grafico_atual = grafico

	var dados := precos.duplicate()

	grafico.draw.connect(
		_desenhar_grafico.bind(grafico, dados)
	)

	grafico.gui_input.connect(
		_entrada_mouse_grafico.bind(grafico, dados)
	)

	grafico.mouse_exited.connect(
		func():
			if is_instance_valid(grafico):
				grafico.set_meta("ponto_mouse", -1)
				grafico.queue_redraw()
	)

	return painel


func _entrada_mouse_grafico(
	event: InputEvent,
	grafico: Control,
	precos: Array[float]
) -> void:
	if not event is InputEventMouseMotion:
		return

	if precos.is_empty():
		return

	var esquerda := 75.0
	var direita := 30.0
	var largura_util: float = grafico.size.x - esquerda - direita

	if largura_util <= 0:
		return

	var x: float = clampf(
		event.position.x,
		esquerda,
		esquerda + largura_util
	)

	var indice := 0

	if precos.size() > 1:
		indice = roundi(
			(x - esquerda) / largura_util
			* float(precos.size() - 1)
		)

	indice = clampi(indice, 0, precos.size() - 1)

	grafico.set_meta("ponto_mouse", indice)
	grafico.queue_redraw()


func _desenhar_grafico(
	grafico: Control,
	precos: Array[float]
) -> void:
	if precos.is_empty():
		return

	var largura: float = grafico.size.x
	var altura: float = grafico.size.y

	var esquerda := 75.0
	var direita := 30.0
	var topo := 55.0
	var baixo := 55.0

	var area_largura: float = largura - esquerda - direita
	var area_altura: float = altura - topo - baixo

	if area_largura <= 0 or area_altura <= 0:
		return

	var menor: float = precos.min()
	var maior: float = precos.max()

	if is_equal_approx(menor, maior):
		menor -= 1.0
		maior += 1.0

	var intervalo: float = maior - menor

	# Linhas horizontais
	for i in range(5):
		var proporcao: float = float(i) / 4.0
		var y: float = topo + proporcao * area_altura

		grafico.draw_line(
			Vector2(esquerda, y),
			Vector2(esquerda + area_largura, y),
			CINZA_LINHA,
			1.0
		)

		var valor: float = maior - proporcao * intervalo

		grafico.draw_string(
			ThemeDB.fallback_font,
			Vector2(5, y + 5),
			"%.2f" % valor,
			HORIZONTAL_ALIGNMENT_LEFT,
			65,
			13,
			COR_NEUTRA
		)

	var pontos := PackedVector2Array()

	for i in range(precos.size()):
		var px := esquerda

		if precos.size() > 1:
			px += (
				float(i) / float(precos.size() - 1)
			) * area_largura

		var py := (
			topo + area_altura
			- (precos[i] - menor) / intervalo * area_altura
		)

		pontos.append(Vector2(px, py))

	# Linha principal
	if pontos.size() >= 2:
		grafico.draw_polyline(
			pontos,
			AZUL,
			3.0,
			true
		)

	# Pontos
	for ponto in pontos:
		grafico.draw_circle(ponto, 4.0, VERDE)

	# Dias no eixo horizontal
	var quantidade: int = precos.size()
	var primeiro_dia: int = max(
		0,
		Market.dia - quantidade + 1
	)

	var intervalo_dias: int = maxi(
		1,
		ceili(float(quantidade) / 10.0)
	)

	for i in range(quantidade):
		if i % intervalo_dias != 0 and i != quantidade - 1:
			continue

		var ponto: Vector2 = pontos[i]
		var dia_real: int = primeiro_dia + i

		grafico.draw_string(
			ThemeDB.fallback_font,
			Vector2(ponto.x - 15, altura - 20),
			str(dia_real),
			HORIZONTAL_ALIGNMENT_LEFT,
			35,
			12,
			COR_NEUTRA
		)

	# Ponto selecionado pelo mouse
	var indice_mouse: int = int(
		grafico.get_meta("ponto_mouse", -1)
	)

	if indice_mouse >= 0 and indice_mouse < pontos.size():
		var ponto: Vector2 = pontos[indice_mouse]
		var dia_mouse: int = primeiro_dia + indice_mouse

		grafico.draw_line(
			Vector2(ponto.x, topo),
			Vector2(ponto.x, topo + area_altura),
			Color(1, 1, 1, 0.35),
			1.0
		)

		grafico.draw_circle(ponto, 7.0, AZUL)

		var texto := "Dia %d | R$ %.2f" % [
			dia_mouse,
			precos[indice_mouse]
		]

		var fonte := ThemeDB.fallback_font
		var tamanho := fonte.get_string_size(
			texto,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			15
		)

		var caixa_largura: float = tamanho.x + 22.0
		var caixa_x: float = clampf(
			ponto.x - caixa_largura / 2.0,
			5.0,
			largura - caixa_largura - 5.0
		)

		var caixa_y: float = maxf(5.0, ponto.y - 48.0)

		grafico.draw_rect(
			Rect2(
				caixa_x,
				caixa_y,
				caixa_largura,
				32
			),
			Color(0.05, 0.09, 0.14, 0.97),
			true
		)

		grafico.draw_string(
			fonte,
			Vector2(caixa_x + 11, caixa_y + 21),
			texto,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			15,
			Color.WHITE
		)
