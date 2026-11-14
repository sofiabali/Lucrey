
extends Control
## Tutorial interativo da Mariane.
## As telas do jogo são abertas pelo jogador, sem sobreposição do mercado.

const IMAGEM: Texture2D = preload("res://assets/mariane.png")
const FUNDO := Color(0.055, 0.09, 0.13, 0.97)
const VERDE := Color(0.23, 0.83, 0.48)

var hud: CanvasLayer
var etapa: int = 0
var concluido: bool = false
var respondeu: bool = false

var baliza: PanelContainer
var fala: Label
var instrucao: Label
var proximo: Button
var acao_panel: PanelContainer
var opcoes: VBoxContainer
var saldo: Label

var pergunta_panel: PanelContainer
var pergunta_opcoes: VBoxContainer

var aguardando_fechar: String = ""


func iniciar(h: CanvasLayer) -> void:
	hud = h
	_montar()

	if GameState.missao_indice >= 2:
		etapa = 7
		concluido = true

	hud.barra_inferior.aba_selecionada.connect(_aba_clicada)
	GameState.dinheiro_mudou.connect(_dinheiro_mudou)

	_mostrar_etapa()


func _painel() -> PanelContainer:
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()

	estilo.bg_color = FUNDO
	estilo.corner_radius_top_left = 16
	estilo.corner_radius_top_right = 16
	estilo.corner_radius_bottom_left = 16
	estilo.corner_radius_bottom_right = 16
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 14

	painel.add_theme_stylebox_override("panel", estilo)
	return painel


func _texto(t: String, tam: int = 18) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _botao(t: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 42)
	b.pressed.connect(callback)
	return b


func _montar() -> void:
	# Mariane no canto inferior esquerdo.
	var retrato := TextureRect.new()
	retrato.texture = IMAGEM
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.anchor_top = 1.0
	retrato.anchor_bottom = 1.0
	retrato.offset_left = 18
	retrato.offset_top = -340
	retrato.offset_right = 205
	retrato.offset_bottom = -95
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(retrato)

	# Balão de fala da Mariane.
	baliza = _painel()
	baliza.anchor_top = 1.0
	baliza.anchor_bottom = 1.0
	baliza.offset_left = 214
	baliza.offset_right = 715
	baliza.offset_top = -305
	baliza.offset_bottom = -98
	add_child(baliza)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	baliza.add_child(caixa)

	caixa.add_child(_texto("MARIANE  •  SUA GUIA", 16))

	fala = _texto("")
	fala.custom_minimum_size.y = 74
	caixa.add_child(fala)

	instrucao = _texto("", 14)
	instrucao.add_theme_color_override("font_color", VERDE)
	caixa.add_child(instrucao)

	proximo = _botao("Continuar", _continuar)
	caixa.add_child(proximo)

	# Mercado de ações: aparece somente na etapa de compra.

	# Mercado de ações centralizado na tela
	acao_panel = _painel()
	acao_panel.set_anchors_preset(Control.PRESET_CENTER)
	acao_panel.offset_left = -250
	acao_panel.offset_top = -230
	acao_panel.offset_right = 250
	acao_panel.offset_bottom = 180
	add_child(acao_panel)


	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	acao_panel.add_child(v)

	v.add_child(_texto("MERCADO DE AÇÕES", 20))

	saldo = _texto("", 16)
	v.add_child(saldo)

	opcoes = VBoxContainer.new()
	opcoes.add_theme_constant_override("separation", 8)
	v.add_child(opcoes)

	acao_panel.hide()

	# Janela exclusiva para a questão de matemática.
	pergunta_panel = _painel()
	pergunta_panel.set_anchors_preset(Control.PRESET_CENTER)
	pergunta_panel.custom_minimum_size = Vector2(570, 340)
	pergunta_panel.position = Vector2(-285, -170)
	add_child(pergunta_panel)

	var pergunta_caixa := VBoxContainer.new()
	pergunta_caixa.add_theme_constant_override("separation", 12)
	pergunta_panel.add_child(pergunta_caixa)

	pergunta_caixa.add_child(_texto("QUESTÃO DE MATEMÁTICA", 22))

	pergunta_opcoes = VBoxContainer.new()
	pergunta_opcoes.add_theme_constant_override("separation", 10)
	pergunta_caixa.add_child(pergunta_opcoes)

	pergunta_panel.hide()


func _tela_aberta() -> bool:
	return (
		hud.tela_carteira.visible
		or hud.tela_noticias.visible
		or hud.tela_missoes.visible
		or hud.tela_loja.visible
		or hud.tela_conquistas.visible
		or hud.tela_cotacoes.visible
	)


func _process(_delta: float) -> void:
	if aguardando_fechar == "":
		return

	if _tela_aberta():
		return

	var tela_fechada := aguardando_fechar
	aguardando_fechar = ""

	match tela_fechada:
		"Notícias":
			etapa = 3
		"Missões":
			etapa = 4
		"Carteira":
			etapa = 6

	_mostrar_etapa()


func _mostrar_etapa() -> void:
	acao_panel.hide()
	pergunta_panel.hide()

	proximo.text = "Continuar"
	proximo.show()

	match etapa:
		0:
			fala.text = "Olá, investidor(a)! Eu sou a Mariane. Bem-vindo(a) ao Lucrey! Aqui você vai aprender a investir e tomar decisões usando matemática."
			instrucao.text = "Você começa com R$ 1.000 de capital fictício."

		1:
			fala.text = "No alto da tela ficam seu dinheiro, seu patrimônio e sua rentabilidade. Patrimônio é o dinheiro disponível mais o valor das ações que você possui."
			instrucao.text = "Observe os valores na barra superior."

		2:
			fala.text = "As notícias podem influenciar os preços das ações. Vamos conhecer essa parte do jogo?"
			instrucao.text = "Clique em NOTÍCIAS na barra inferior."
			proximo.hide()

		3:
			fala.text = "Muito bem! Agora veja suas missões. Cada objetivo concluído rende recompensas."
			instrucao.text = "Clique em MISSÕES na barra inferior."
			proximo.hide()

		4:
			fala.text = "Hora da sua primeira compra! Uma ação representa uma pequena parte de uma empresa. Escolha uma opção no painel do mercado."
			instrucao.text = "Escolha uma empresa no painel à direita e clique em COMPRAR 1 AÇÃO."
			proximo.hide()
			_mostrar_acoes()

		5:
			fala.text = "Você comprou sua primeira ação! Agora ela pertence à sua carteira. Vamos conferir?"
			instrucao.text = "Clique em CARTEIRA na barra inferior e veja sua ação."
			proximo.hide()

		6:
			fala.text = "Excelente! Sua primeira compra já conta como missão! Agora vamos resolver uma questão de matemática para atingir R$ 2.000 de patrimônio."
			instrucao.text = "Clique em RESPONDER QUESTÃO."
			proximo.text = "Responder questão"

		7:
			fala.text = "Parabéns! Você concluiu o tutorial. Confira suas conquistas e suas missões! A próxima questão ficará para o nível 2."
			instrucao.text = "Tutorial concluído!"
			proximo.text = "Fechar Mariane"


func _continuar() -> void:
	if etapa == 6:
		_mostrar_pergunta()
	elif etapa == 7:
		queue_free()
	else:
		etapa += 1
		_mostrar_etapa()


func _aba_clicada(nome: String) -> void:
	# O tutorial só avança depois que o jogador fecha a tela.
	if etapa == 2 and nome == "Notícias":
		aguardando_fechar = "Notícias"
		instrucao.text = "Explore as notícias e feche a tela para continuar."

	elif etapa == 3 and nome == "Missões":
		aguardando_fechar = "Missões"
		instrucao.text = "Observe suas missões e feche a tela para continuar."

	elif etapa == 5 and nome == "Carteira":
		aguardando_fechar = "Carteira"
		instrucao.text = "Confira sua ação na carteira e feche a tela para continuar."

	# Esconde o mercado quando qualquer tela cheia é aberta.
	if _tela_aberta():
		acao_panel.hide()


func _mostrar_acoes() -> void:
	if _tela_aberta():
		return

	acao_panel.show()

	for filho in opcoes.get_children():
		filho.queue_free()

	saldo.text = "Disponível: R$ %.2f" % GameState.dinheiro

	for stock: Stock in Market.acoes:
		var ticker: String = stock.ticker
		var preco: float = stock.preco

		var b := _botao(
			"%s • R$ %.2f | COMPRAR 1 AÇÃO" % [ticker, preco],
			func() -> void: _comprar(ticker)
		)

		b.disabled = preco > GameState.dinheiro
		opcoes.add_child(b)


func _comprar(ticker: String) -> void:
	if etapa != 4:
		return

	if GameState.comprar(ticker, 1):
		etapa = 5
		_mostrar_etapa()
	else:
		instrucao.text = "Saldo insuficiente. Escolha outra ação."


func _dinheiro_mudou(_valor: float) -> void:
	if etapa == 4:
		_mostrar_acoes()


func _mostrar_pergunta() -> void:
	acao_panel.hide()
	pergunta_panel.show()

	for filho in pergunta_opcoes.get_children():
		filho.queue_free()

	fala.text = "Resolva a questão para ganhar uma recompensa fictícia de R$ 1.000!"
	instrucao.text = "Escolha a alternativa correta."
	proximo.hide()

	pergunta_opcoes.add_child(
		_texto("Uma ação custa R$ 40. Quanto custam 5 ações?", 18)
	)

	for alternativa in [
		"A) R$ 160",
		"B) R$ 180",
		"C) R$ 200",
		"D) R$ 240"
	]:
		var correta: bool = alternativa.begins_with("C)")

		pergunta_opcoes.add_child(
			_botao(alternativa, func() -> void: _responder(correta))
		)


func _responder(correta: bool) -> void:
	if respondeu:
		return

	if not correta:
		instrucao.text = "Ainda não! Multiplique 40 por 5 e tente novamente."
		return

	respondeu = true

	# Completa o patrimônio de R$ 2.000 com dinheiro fictício.
	GameState.receber_bonus_tutorial(
		maxf(0.0, 2000.0 - GameState.patrimonio())
	)

	hud._atualizar_tudo()

	concluido = true
	etapa = 7
	_mostrar_etapa()

	instrucao.text = "Resposta correta! Patrimônio: R$ %.2f • missão concluída." % GameState.patrimonio()
