

extends Control
## Tutorial interativo da Mariane.
## Inclui compra, carteira, matemática e avanço do dia.

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

# NOVO: valores usados na explicação do avanço do dia.
var dia_anterior: int = 0
var patrimonio_anterior: float = 0.0
var carteira_anterior: float = 0.0


func iniciar(h: CanvasLayer) -> void:
	hud = h
	_montar()

	# Se a missão de patrimônio já foi concluída,
	# o tutorial começa pela explicação do avanço do dia.
	if GameState.missao_indice >= 2:
		respondeu = true
		etapa = 7

	hud.barra_inferior.aba_selecionada.connect(_aba_clicada)
	GameState.dinheiro_mudou.connect(_dinheiro_mudou)

	# NOVO: detecta quando o jogador avança o dia.
	Market.dia_avancou.connect(_dia_avancou)

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

	# Balão de fala.
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

	# Mercado de ações centralizado.
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

	# Questão de matemática centralizada.
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
			fala.text = "Hora da sua primeira compra! Uma ação representa uma pequena parte de uma empresa. Escolha uma opção no mercado."
			instrucao.text = "Escolha uma empresa no painel central e clique em COMPRAR 1 AÇÃO."
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

		# NOVO: introdução ao avanço do dia.
		7:
			fala.text = "Agora vamos descobrir como o mercado muda! Ao clicar em Avançar Dia, um novo dia começa e os preços das ações podem subir ou cair."
			instrucao.text = "As notícias podem influenciar os preços, mas não garantem que uma ação vai subir ou cair."
			proximo.text = "Entendi!"

		# NOVO: jogador precisa clicar no botão real.
		8:
			fala.text = "Vamos testar! Observe seu patrimônio e o valor da sua carteira. Depois, clique em AVANÇAR DIA, no canto superior direito."
			instrucao.text = "Clique no botão verde AVANÇAR DIA para continuar."
			proximo.hide()

			dia_anterior = Market.dia
			patrimonio_anterior = GameState.patrimonio()
			carteira_anterior = GameState.valor_da_carteira()

		# NOVO: explica o resultado do avanço.
		9:
			var variacao: float = GameState.valor_da_carteira() - carteira_anterior

			fala.text = "Muito bem! Você avançou do dia %d para o dia %d. " % [
				dia_anterior, Market.dia
			]

			if variacao > 0.01:
				fala.text += "O valor das suas ações aumentou! Isso significa que sua carteira se valorizou."
			elif variacao < -0.01:
				fala.text += "O valor das suas ações diminuiu. Isso mostra que os investimentos também apresentam riscos."
			else:
				fala.text += "O valor da sua carteira permaneceu praticamente igual. Nem todo dia apresenta grandes mudanças."

			instrucao.text = "Patrimônio antes: R$ %.2f | Agora: R$ %.2f" % [
				patrimonio_anterior,
				GameState.patrimonio()
			]

			proximo.text = "Finalizar tutorial"

		# Despedida da Mariane.
		10:
			concluido = true
			fala.text = "Parabéns! Você concluiu o nível 1 do Lucrey! Aprendeu sobre ações, carteira, missões, matemática e como o mercado muda com o tempo."
			instrucao.text = "Continue explorando o jogo! A próxima questão ficará para o nível 2."
			proximo.text = "Fechar Mariane"


func _continuar() -> void:
	if etapa == 6:
		_mostrar_pergunta()
	elif etapa == 10:
		queue_free()
	else:
		etapa += 1
		_mostrar_etapa()


func _aba_clicada(nome: String) -> void:
	if etapa == 2 and nome == "Notícias":
		aguardando_fechar = "Notícias"
		instrucao.text = "Explore as notícias e feche a tela para continuar."

	elif etapa == 3 and nome == "Missões":
		aguardando_fechar = "Missões"
		instrucao.text = "Observe suas missões e feche a tela para continuar."

	elif etapa == 5 and nome == "Carteira":
		aguardando_fechar = "Carteira"
		instrucao.text = "Confira sua ação na carteira e feche a tela para continuar."

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

	fala.text = "Resolva a questão para ganhar uma recompensa fictícia!"
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

	# Agora o tutorial continua com a explicação de Avançar Dia.
	etapa = 7
	_mostrar_etapa()

	instrucao.text = "Resposta correta! Patrimônio: R$ %.2f. Vamos conhecer o avanço dos dias!" % GameState.patrimonio()


# NOVO: chamado quando o jogador realmente avança o dia.
func _dia_avancou(_dia: int) -> void:
	if etapa != 8:
		return

	etapa = 9
	_mostrar_etapa()
