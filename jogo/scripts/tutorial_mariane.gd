
extends Control

## Tutorial interativo da Mariane
## Inclui notícias, cotações, missões, loja,
## compra de ações, carteira, matemática e avanço dos dias.

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
var tela_do_tutorial_aberta: bool = false

var dia_anterior: int = 0
var patrimonio_anterior: float = 0.0
var carteira_anterior: float = 0.0


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func iniciar(h: CanvasLayer) -> void:
	hud = h
	_montar()

	if GameState.missao_indice >= 2:
		respondeu = true
		etapa = 9

	hud.barra_inferior.aba_selecionada.connect(_aba_clicada)
	GameState.dinheiro_mudou.connect(_dinheiro_mudou)
	Market.dia_avancou.connect(_dia_avancou)

	_mostrar_etapa()


# ==================================================
# COMPONENTES VISUAIS
# ==================================================

func _painel() -> PanelContainer:
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()

	estilo.bg_color = FUNDO
	estilo.set_corner_radius_all(16)
	estilo.set_content_margin_all(18)

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
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Retrato da Mariane
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

	# Balão da Mariane
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

	var titulo := _texto("MARIANE • SUA GUIA", 16)
	titulo.add_theme_color_override("font_color", VERDE)
	caixa.add_child(titulo)

	fala = _texto("")
	fala.custom_minimum_size.y = 74
	caixa.add_child(fala)

	instrucao = _texto("", 14)
	instrucao.add_theme_color_override("font_color", VERDE)
	caixa.add_child(instrucao)

	proximo = _botao("Continuar", _continuar)
	caixa.add_child(proximo)

	# Painel de compra
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

	# Painel de matemática
	pergunta_panel = _painel()
	pergunta_panel.set_anchors_preset(Control.PRESET_CENTER)
	pergunta_panel.offset_left = -285
	pergunta_panel.offset_top = -170
	pergunta_panel.offset_right = 285
	pergunta_panel.offset_bottom = 170

	add_child(pergunta_panel)

	var pergunta_caixa := VBoxContainer.new()
	pergunta_caixa.add_theme_constant_override("separation", 12)
	pergunta_panel.add_child(pergunta_caixa)

	pergunta_caixa.add_child(
		_texto("QUESTÃO DE MATEMÁTICA", 22)
	)

	pergunta_opcoes = VBoxContainer.new()
	pergunta_opcoes.add_theme_constant_override("separation", 10)
	pergunta_caixa.add_child(pergunta_opcoes)

	pergunta_panel.hide()


# ==================================================
# CONTROLE DAS TELAS
# ==================================================

func _tela_aberta() -> bool:
	if hud == null or not is_instance_valid(hud):
		return false

	return (
		hud.tela_carteira.visible
		or hud.tela_noticias.visible
		or hud.tela_missoes.visible
		or hud.tela_loja.visible
		or hud.tela_conquistas.visible
		or hud.tela_cotacoes.visible
	)


func _process(_delta: float) -> void:
	if hud == null or not is_instance_valid(hud):
		return

	if _tela_aberta():
		acao_panel.hide()
		pergunta_panel.hide()

	if aguardando_fechar == "":
		return

	if _tela_aberta():
		return

	if not tela_do_tutorial_aberta:
		return

	var tela_fechada := aguardando_fechar
	aguardando_fechar = ""
	tela_do_tutorial_aberta = false

	match tela_fechada:
		"Notícias":
			etapa = 3
		"Cotações":
			etapa = 4
		"Missões":
			etapa = 5
		"Loja":
			etapa = 6
		"Carteira":
			etapa = 8

	_mostrar_etapa()


# ==================================================
# ETAPAS DO TUTORIAL
# ==================================================

func _mostrar_etapa() -> void:
	acao_panel.hide()
	pergunta_panel.hide()

	proximo.text = "Continuar"
	proximo.show()

	match etapa:
		0:
			fala.text = (
				"Olá, investidor(a)! Eu sou a Mariane, "
				+ "sua guia no Lucrey! Aqui você vai "
				+ "aprender sobre o mercado de ações, "
				+ "educação financeira e estratégias "
				+ "de investimento."
			)

			instrucao.text = (
				"Você começa com R$ 1.000 fictícios. "
				+ "Vamos conhecer o jogo!"
			)

		1:
			fala.text = (
				"Na parte superior da tela você encontra "
				+ "seu dinheiro, patrimônio, rentabilidade, "
				+ "fase atual e nível de experiência."
			)

			instrucao.text = (
				"O patrimônio é o dinheiro disponível "
				+ "mais o valor das ações da sua carteira. "
				+ "O XP ajuda você a subir de nível!"
			)

		2:
			fala.text = (
				"Primeiro, vamos conhecer as notícias! "
				+ "No mercado financeiro, acontecimentos "
				+ "podem influenciar os preços das ações."
			)

			instrucao.text = (
				"Clique em NOTÍCIAS na barra inferior, "
				+ "explore as informações e depois feche "
				+ "a tela para continuar."
			)

			proximo.hide()

		3:
			fala.text = (
				"Agora vamos conhecer as COTAÇÕES! "
				+ "É aqui que você acompanha o preço "
				+ "das ações das empresas e observa "
				+ "como esses valores mudam."
			)

			instrucao.text = (
				"Uma variação positiva indica que o preço "
				+ "subiu no período analisado. Uma negativa "
				+ "indica que caiu. Clique em COTAÇÕES, "
				+ "observe os valores e feche a tela."
			)

			proximo.hide()

		4:
			fala.text = (
				"Muito bem! Agora vamos conhecer "
				+ "as MISSÕES. Elas são objetivos "
				+ "que você pode completar durante "
				+ "sua jornada como investidor."
			)

			instrucao.text = (
				"Ao concluir missões, você pode ganhar "
				+ "moedas e XP. Clique em MISSÕES, "
				+ "observe os objetivos e feche a tela."
			)

			proximo.hide()

		5:
			fala.text = (
				"Você sabia que pode utilizar suas "
				+ "moedas na LOJA? Conforme completa "
				+ "missões, você ganha moedas para "
				+ "adquirir benefícios dentro do jogo!"
			)

			instrucao.text = (
				"Na loja existe o Boost de XP, que dobra "
				+ "sua próxima recompensa de experiência. "
				+ "Clique em LOJA, explore os itens e "
				+ "feche a tela. Não precisa comprar nada!"
			)

			proximo.hide()

		6:
			fala.text = (
				"Agora que você conhece as principais "
				+ "ferramentas, chegou a hora de investir! "
				+ "Uma ação representa uma pequena "
				+ "participação em uma empresa."
			)

			instrucao.text = (
				"Escolha uma empresa no painel central "
				+ "e clique para COMPRAR 1 AÇÃO."
			)

			proximo.hide()
			_mostrar_acoes()

		7:
			fala.text = (
				"Parabéns pela primeira compra! "
				+ "Agora você possui uma ação. "
				+ "Ela ficará registrada na sua CARTEIRA."
			)

			instrucao.text = (
				"Clique em CARTEIRA na barra inferior "
				+ "para conferir seu investimento. "
				+ "Depois, feche a tela."
			)

			proximo.hide()

		8:
			fala.text = (
				"Excelente! Sua primeira compra "
				+ "já conta como missão! Agora vamos "
				+ "usar a matemática para entender "
				+ "melhor os investimentos."
			)

			instrucao.text = (
				"Resolva uma questão para receber "
				+ "uma recompensa fictícia e atingir "
				+ "R$ 2.000 de patrimônio."
			)

			proximo.text = "Responder questão"

		9:
			fala.text = (
				"Agora vamos descobrir como o mercado "
				+ "muda com o tempo! A cada novo dia, "
				+ "os preços das ações podem subir "
				+ "ou cair."
			)

			instrucao.text = (
				"Observe as cotações e as notícias. "
				+ "Elas ajudam você a acompanhar "
				+ "o mercado, mas não garantem "
				+ "que uma ação vai valorizar."
			)

			proximo.text = "Entendi!"

		10:
			fala.text = (
				"Vamos testar! Observe seu patrimônio "
				+ "e o valor da sua carteira. Depois, "
				+ "avance os dias para acompanhar "
				+ "as mudanças no mercado."
			)

			instrucao.text = (
				"Clique em AVANÇAR DIA até chegar "
				+ "ao dia 10 para finalizar o tutorial. "
				+ "Dia atual: %d/10" % Market.dia
			)

			proximo.hide()

			dia_anterior = Market.dia
			patrimonio_anterior = GameState.patrimonio()
			carteira_anterior = GameState.valor_da_carteira()

			if Market.dia >= 10:
				call_deferred("_concluir_avanco_dias")

		11:
			var variacao: float = (
				GameState.valor_da_carteira()
				- carteira_anterior
			)

			fala.text = (
				"Muito bem! Você chegou ao dia %d. "
				% Market.dia
			)

			if variacao > 0.01:
				fala.text += (
					"O valor das suas ações aumentou "
					+ "desde nossa última observação!"
				)

			elif variacao < -0.01:
				fala.text += (
					"O valor das suas ações diminuiu. "
					+ "Isso mostra que os investimentos "
					+ "também apresentam riscos."
				)

			else:
				fala.text += (
					"O valor da sua carteira permaneceu "
					+ "praticamente igual."
				)

			instrucao.text = (
				"Patrimônio antes: R$ %.2f | Agora: R$ %.2f"
				% [
					patrimonio_anterior,
					GameState.patrimonio()
				]
			)

			proximo.text = "Finalizar tutorial"

		12:
			concluido = true

			fala.text = (
				"PARABÉNS! Você concluiu o primeiro "
				+ "nível do Lucrey! Aprendeu sobre "
				+ "notícias, cotações, missões, loja, "
				+ "compra de ações e matemática!"
			)

			instrucao.text = (
				"Agora você está pronto para o nível 2, "
				+ "onde poderá tomar suas próprias "
				+ "decisões de investimento!"
			)

			proximo.text = "Começar nível 2"


# ==================================================
# BOTÃO CONTINUAR
# ==================================================

func _continuar() -> void:
	if etapa == 8:
		_mostrar_pergunta()
		return

	if etapa == 12:
		_finalizar_tutorial()
		return

	etapa += 1
	_mostrar_etapa()


# ==================================================
# NAVEGAÇÃO NAS ABAS
# ==================================================

func _aba_clicada(nome: String) -> void:
	if etapa == 2 and nome == "Notícias":
		aguardando_fechar = "Notícias"
		tela_do_tutorial_aberta = true

	elif etapa == 3 and nome == "Cotações":
		aguardando_fechar = "Cotações"
		tela_do_tutorial_aberta = true

	elif etapa == 4 and nome == "Missões":
		aguardando_fechar = "Missões"
		tela_do_tutorial_aberta = true

	elif etapa == 5 and nome == "Loja":
		aguardando_fechar = "Loja"
		tela_do_tutorial_aberta = true

	elif etapa == 7 and nome == "Carteira":
		aguardando_fechar = "Carteira"
		tela_do_tutorial_aberta = true

	if _tela_aberta():
		acao_panel.hide()


# ==================================================
# PRIMEIRA COMPRA
# ==================================================

func _mostrar_acoes() -> void:
	if _tela_aberta():
		return

	acao_panel.show()

	for filho in opcoes.get_children():
		opcoes.remove_child(filho)
		filho.queue_free()

	saldo.text = (
		"Disponível: R$ %.2f"
		% GameState.dinheiro
	)

	for stock: Stock in Market.acoes:
		var ticker: String = stock.ticker
		var preco: float = stock.preco

		var b := _botao(
			"%s • R$ %.2f | COMPRAR 1 AÇÃO"
			% [ticker, preco],
			_comprar.bind(ticker)
		)

		b.disabled = preco > GameState.dinheiro
		opcoes.add_child(b)


func _comprar(ticker: String) -> void:
	if etapa != 6:
		return

	if GameState.comprar(ticker, 1):
		etapa = 7
		_mostrar_etapa()
	else:
		instrucao.text = (
			"Saldo insuficiente. "
			+ "Escolha outra ação."
		)


func _dinheiro_mudou(_valor: float) -> void:
	if etapa == 6:
		_mostrar_acoes()


# ==================================================
# QUESTÃO MATEMÁTICA
# ==================================================

func _mostrar_pergunta() -> void:
	acao_panel.hide()
	pergunta_panel.show()

	for filho in pergunta_opcoes.get_children():
		pergunta_opcoes.remove_child(filho)
		filho.queue_free()

	fala.text = (
		"Resolva a questão para ganhar "
		+ "uma recompensa fictícia!"
	)

	instrucao.text = "Escolha a alternativa correta."
	proximo.hide()

	pergunta_opcoes.add_child(
		_texto(
			"Uma ação custa R$ 40. Quanto custam 5 ações?",
			18
		)
	)

	var alternativas := [
		"A) R$ 160",
		"B) R$ 180",
		"C) R$ 200",
		"D) R$ 240"
	]

	# Correção: sem função anônima.
	# Evita o erro de indentação das linhas 706/707.
	for i in range(alternativas.size()):
		var botao := _botao(
			alternativas[i],
			_responder_alternativa.bind(i)
		)
		pergunta_opcoes.add_child(botao)


func _responder_alternativa(indice: int) -> void:
	_responder(indice == 2)


func _responder(correta: bool) -> void:
	if respondeu:
		return

	if not correta:
		instrucao.text = (
			"Ainda não! Multiplique 40 por 5 "
			+ "e tente novamente."
		)
		return

	respondeu = true

	GameState.receber_bonus_tutorial(
		maxf(
			0.0,
			2000.0 - GameState.patrimonio()
		)
	)

	if is_instance_valid(hud):
		hud._atualizar_tudo()

	etapa = 9
	_mostrar_etapa()

	instrucao.text = (
		"Resposta correta! Patrimônio: R$ %.2f. "
		+ "Vamos conhecer o avanço dos dias!"
	) % GameState.patrimonio()


# ==================================================
# AVANÇO DOS DIAS
# ==================================================

func _dia_avancou(_dia: int) -> void:
	if etapa != 10:
		return

	if Market.dia >= 10:
		_concluir_avanco_dias()
	else:
		instrucao.text = (
			"Dia %d/10. Continue avançando!"
			% Market.dia
		)


func _concluir_avanco_dias() -> void:
	if etapa != 10:
		return

	etapa = 11
	_mostrar_etapa()


# ==================================================
# FINALIZAÇÃO
# ==================================================

func _finalizar_tutorial() -> void:
	GameState.fase_jogo = 2

	if is_instance_valid(hud):
		hud.call_deferred("_atualizar_tudo")
		hud.call_deferred("_iniciar_nivel_2")

	queue_free()
