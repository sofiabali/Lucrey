





extends Control
## Nível 2: Introdução à Estratégia.

const IMAGEM: Texture2D = preload("res://assets/mariane.png")
const FUNDO := Color(0.055, 0.09, 0.13, 0.97)
const VERDE := Color(0.23, 0.83, 0.48)
const TEXTO_CLARO := Color(0.78, 0.86, 0.89)

const QUESTOES := [
	{
		"titulo": "Valorização da ação",
		"enunciado": "Você comprou uma ação por R$ 200. Após alguns dias, ela valorizou 15%. Qual é o novo valor da ação?",
		"opcoes": [
			"A) R$ 215",
			"B) R$ 225",
			"C) R$ 230",
			"D) R$ 245"
		],
		"resposta": 2,
		"explicacao": "15% de 200 = 30. Portanto, 200 + 30 = R$ 230."
	},
	{
		"titulo": "Rendimento do investimento",
		"enunciado": "Você investiu R$ 500 em uma empresa. Após um período, o investimento teve um rendimento de 12%. Quanto você terá ao final desse período?",
		"opcoes": [
			"A) R$ 540",
			"B) R$ 550",
			"C) R$ 560",
			"D) R$ 600"
		],
		"resposta": 2,
		"explicacao": "12% de 500 = 60. Portanto, 500 + 60 = R$ 560."
	}
]

var hud: CanvasLayer

var retrato: TextureRect
var balao: PanelContainer
var fala: Label
var instrucao: Label

var painel_mercado: PanelContainer
var painel_questao: PanelContainer
var caixa_questao: VBoxContainer

var seletor: OptionButton
var quantidade: SpinBox

var label_saldo: Label
var label_preco: Label
var label_total: Label
var label_progresso: Label

var tickers: Array[String] = []

var questoes_resolvidas: int = 0
var erros_questao: int = 0
var bloqueado_ate_dia: int = 0

var compra_pendente: String = ""
var quantidade_pendente: int = 0

var aviso_dia_15: bool = false
var aviso_dia_16: bool = false
var aviso_dia_17: bool = false
var aviso_dia_20: bool = false

var concluido: bool = false
var acao_apos_fala: Callable = Callable()


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func iniciar(h: CanvasLayer) -> void:
	hud = h

	_montar_interface()

	Market.dia_avancou.connect(_dia_avancou)
	GameState.dinheiro_mudou.connect(_dinheiro_mudou)
	GameState.missao_mudou.connect(_missao_mudou)
	GameState.xp_mudou.connect(_xp_mudou)
	GameState.operacao_realizada.connect(_operacao_realizada)

	concluido = GameState.nivel_2_concluido

	_atualizar_mercado()

	if not concluido:
		_mostrar_fala(
			"Bem-vindo(a) ao nível 2! Agora suas decisões fazem a diferença.",
			"Explore o mapa, acompanhe as notícias e use INVESTIR quando quiser negociar ações."
		)


# ==================================================
# COMPONENTES VISUAIS
# ==================================================

func _criar_painel() -> PanelContainer:
	var p := PanelContainer.new()
	var estilo := StyleBoxFlat.new()

	estilo.bg_color = FUNDO
	estilo.set_corner_radius_all(18)
	estilo.set_content_margin_all(20)

	estilo.border_width_left = 1
	estilo.border_width_right = 1
	estilo.border_width_top = 1
	estilo.border_width_bottom = 1

	estilo.border_color = Color(0.22, 0.43, 0.45)

	p.add_theme_stylebox_override("panel", estilo)
	p.mouse_filter = Control.MOUSE_FILTER_STOP

	return p


func _texto(t: String, tamanho: int = 17) -> Label:
	var l := Label.new()

	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return l


func _botao(t: String, callback: Callable) -> Button:
	var b := Button.new()

	b.text = t
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(callback)

	return b


func _separador() -> HSeparator:
	return HSeparator.new()


func _montar_interface() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ----------------------------------------------
	# MARIANE NO CANTO
	# ----------------------------------------------

	retrato = TextureRect.new()
	retrato.texture = IMAGEM

	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	retrato.anchor_top = 1.0
	retrato.anchor_bottom = 1.0

	retrato.offset_left = 12
	retrato.offset_right = 150
	retrato.offset_top = -225
	retrato.offset_bottom = -45

	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(retrato)

	# ----------------------------------------------
	# BALÃO DA MARIANE
	# ----------------------------------------------

	balao = _criar_painel()

	balao.anchor_top = 1.0
	balao.anchor_bottom = 1.0

	balao.offset_left = 160
	balao.offset_right = 640
	balao.offset_top = -245
	balao.offset_bottom = -45

	add_child(balao)

	var caixa_fala := VBoxContainer.new()
	caixa_fala.add_theme_constant_override("separation", 8)
	balao.add_child(caixa_fala)

	var titulo := _texto("MARIANE • SUA GUIA", 16)
	titulo.add_theme_color_override("font_color", VERDE)
	caixa_fala.add_child(titulo)

	fala = _texto("", 16)
	fala.custom_minimum_size.y = 65
	caixa_fala.add_child(fala)

	instrucao = _texto("", 13)
	instrucao.add_theme_color_override(
		"font_color",
		TEXTO_CLARO
	)
	caixa_fala.add_child(instrucao)

	caixa_fala.add_child(
		_botao("ENTENDI", _fechar_fala)
	)

	balao.hide()

	# ----------------------------------------------
	# MERCADO DE AÇÕES
	# ----------------------------------------------

	painel_mercado = _criar_painel()

	painel_mercado.set_anchors_preset(
		Control.PRESET_CENTER
	)

	painel_mercado.offset_left = -360
	painel_mercado.offset_right = 360
	painel_mercado.offset_top = -285
	painel_mercado.offset_bottom = 285

	add_child(painel_mercado)

	var mercado := VBoxContainer.new()
	mercado.add_theme_constant_override("separation", 12)
	painel_mercado.add_child(mercado)

	var titulo_mercado := _texto(
		"MERCADO DE AÇÕES",
		25
	)

	titulo_mercado.add_theme_color_override(
		"font_color",
		VERDE
	)

	mercado.add_child(titulo_mercado)

	mercado.add_child(
		_texto(
			"Analise as empresas e escolha sua estratégia.",
			15
		)
	)

	mercado.add_child(_separador())

	label_saldo = _texto("", 18)
	mercado.add_child(label_saldo)

	label_progresso = _texto("", 14)
	mercado.add_child(label_progresso)

	mercado.add_child(_separador())

	mercado.add_child(
		_texto("ESCOLHA UMA EMPRESA", 16)
	)

	seletor = OptionButton.new()
	seletor.custom_minimum_size.y = 44
	seletor.item_selected.connect(_empresa_alterada)
	mercado.add_child(seletor)

	label_preco = _texto("", 15)
	mercado.add_child(label_preco)

	mercado.add_child(
		_texto("QUANTIDADE DE AÇÕES", 16)
	)

	quantidade = SpinBox.new()
	quantidade.min_value = 1
	quantidade.max_value = 1000
	quantidade.step = 1
	quantidade.value = 1
	quantidade.custom_minimum_size.y = 44

	quantidade.value_changed.connect(
		_quantidade_alterada
	)

	mercado.add_child(quantidade)

	label_total = _texto("", 19)
	label_total.add_theme_color_override(
		"font_color",
		VERDE
	)

	mercado.add_child(label_total)
	mercado.add_child(_separador())

	var linha_botoes := HBoxContainer.new()
	linha_botoes.add_theme_constant_override(
		"separation",
		12
	)

	mercado.add_child(linha_botoes)

	var comprar := _botao(
		"COMPRAR AÇÕES",
		_tentar_comprar
	)

	comprar.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	linha_botoes.add_child(comprar)

	var vender := _botao(
		"VENDER AÇÕES",
		_tentar_vender
	)

	vender.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	linha_botoes.add_child(vender)

	mercado.add_child(
		_botao(
			"FECHAR MERCADO",
			_fechar_mercado
		)
	)

	painel_mercado.hide()

	# ----------------------------------------------
	# QUESTÕES MATEMÁTICAS
	# ----------------------------------------------

	painel_questao = _criar_painel()

	painel_questao.set_anchors_preset(
		Control.PRESET_CENTER
	)

	painel_questao.offset_left = -340
	painel_questao.offset_right = 340
	painel_questao.offset_top = -250
	painel_questao.offset_bottom = 250

	add_child(painel_questao)

	caixa_questao = VBoxContainer.new()
	caixa_questao.add_theme_constant_override(
		"separation",
		12
	)

	painel_questao.add_child(caixa_questao)
	painel_questao.hide()


# ==================================================
# CONTROLE DAS JANELAS
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
		painel_mercado.hide()
		painel_questao.hide()
		balao.hide()


func _mostrar_fala(
	mensagem: String,
	orientacao: String = "",
	depois: Callable = Callable()
) -> void:
	painel_mercado.hide()
	painel_questao.hide()

	fala.text = mensagem
	instrucao.text = orientacao

	acao_apos_fala = depois

	balao.show()


func _fechar_fala() -> void:
	balao.hide()

	var proxima_acao := acao_apos_fala
	acao_apos_fala = Callable()

	if proxima_acao.is_valid():
		proxima_acao.call()


func _abrir_mercado() -> void:
	if hud == null:
		return

	if _tela_aberta():
		return

	balao.hide()
	painel_questao.hide()

	_atualizar_mercado()
	painel_mercado.show()


func _fechar_mercado() -> void:
	painel_mercado.hide()


# ==================================================
# INFORMAÇÕES DO MERCADO
# ==================================================

func _ticker_escolhido() -> String:
	if seletor.selected < 0:
		return ""

	if seletor.selected >= tickers.size():
		return ""

	return tickers[seletor.selected]


func _atualizar_mercado() -> void:
	if seletor == null:
		return

	var anterior := _ticker_escolhido()

	seletor.clear()
	tickers.clear()

	var indice_selecionado := 0

	for acao: Stock in Market.acoes:
		tickers.append(acao.ticker)

		var variacao: float = Market.variacao_diaria(
			acao.ticker
		)

		var sinal := "+"
		if variacao < 0.0:
			sinal = ""

		seletor.add_item(
			"%s • %s • R$ %.2f • %s%.2f%%" % [
				acao.ticker,
				acao.setor,
				acao.preco,
				sinal,
				variacao
			]
		)

		if acao.ticker == anterior:
			indice_selecionado = (
				tickers.size() - 1
			)

	if not tickers.is_empty():
		seletor.select(indice_selecionado)

	label_saldo.text = (
		"Dia %d | Saldo disponível: R$ %.2f"
		% [
			Market.dia,
			GameState.dinheiro
		]
	)

	var setores: Array[String] = []

	for ticker in GameState.carteira:
		if int(GameState.carteira[ticker]) <= 0:
			continue

		var acao: Stock = Market.buscar(str(ticker))

		if acao != null:
			if not setores.has(acao.setor):
				setores.append(acao.setor)

	var venda_texto := "Pendente"

	if GameState.venda_nivel_2_realizada:
		venda_texto = "Concluída"

	label_progresso.text = (
		"Diversificação: %d/3 setores | Missão de venda: %s"
		% [
			setores.size(),
			venda_texto
		]
	)

	_atualizar_previa()


func _empresa_alterada(_indice: int) -> void:
	_atualizar_previa()


func _quantidade_alterada(_valor: float) -> void:
	_atualizar_previa()


func _atualizar_previa() -> void:
	if label_total == null:
		return

	var ticker := _ticker_escolhido()
	var acao: Stock = Market.buscar(ticker)

	if acao == null:
		label_preco.text = "Nenhuma empresa disponível."
		label_total.text = ""
		return

	var qtd := int(quantidade.value)
	var custo: float = acao.preco * qtd

	var variacao: float = Market.variacao_diaria(
		ticker
	)

	label_preco.text = (
		"Preço por ação: R$ %.2f | Variação diária: %+.2f%%"
		% [
			acao.preco,
			variacao
		]
	)

	label_total.text = (
		"TOTAL DA OPERAÇÃO: R$ %.2f"
		% custo
	)


# ==================================================
# COMPRA
# ==================================================

func _tentar_comprar() -> void:
	var ticker := _ticker_escolhido()
	var qtd := int(quantidade.value)

	var acao: Stock = Market.buscar(ticker)

	if acao == null:
		return

	var custo: float = acao.preco * qtd

	if custo > GameState.dinheiro:
		_mostrar_fala(
			"Você não possui dinheiro suficiente.",
			"Escolha uma quantidade menor ou outra empresa."
		)
		return

	if Market.dia < bloqueado_ate_dia:
		_mostrar_fala(
			"Essa compra ainda está bloqueada.",
			"Você poderá tentar novamente no dia %d."
			% bloqueado_ate_dia
		)
		return

	var desafio_disponivel := false

	if questoes_resolvidas == 0:
		desafio_disponivel = true

	elif questoes_resolvidas == 1:
		if Market.dia >= 15:
			desafio_disponivel = true

	if desafio_disponivel:
		compra_pendente = ticker
		quantidade_pendente = qtd
		erros_questao = 0

		_mostrar_questao()
		return

	_realizar_compra(ticker, qtd)


func _realizar_compra(
	ticker: String,
	qtd: int
) -> void:
	var sucesso := GameState.comprar(
		ticker,
		qtd
	)

	_atualizar_mercado()
	painel_mercado.hide()

	if sucesso:
		_verificar_conclusao()
	else:
		_mostrar_fala(
			"Não foi possível concluir essa compra.",
			"Confira seu saldo e tente novamente."
		)


# ==================================================
# VENDA
# ==================================================

func _tentar_vender() -> void:
	var ticker := _ticker_escolhido()
	var qtd := int(quantidade.value)

	var sucesso := GameState.vender(
		ticker,
		qtd
	)

	_atualizar_mercado()
	painel_mercado.hide()

	if not sucesso:
		_mostrar_fala(
			"Não foi possível vender essas ações.",
			"Confira a quantidade disponível na sua carteira."
		)


# ==================================================
# QUESTÕES MATEMÁTICAS
# ==================================================

func _mostrar_questao() -> void:
	painel_mercado.hide()
	balao.hide()

	if questoes_resolvidas >= QUESTOES.size():
		return

	for filho in caixa_questao.get_children():
		caixa_questao.remove_child(filho)
		filho.queue_free()

	var q: Dictionary = QUESTOES[
		questoes_resolvidas
	]

	var titulo := _texto(
		"DESAFIO MATEMÁTICO %d/2"
		% (questoes_resolvidas + 1),
		23
	)

	titulo.add_theme_color_override(
		"font_color",
		VERDE
	)

	caixa_questao.add_child(titulo)

	caixa_questao.add_child(
		_texto(str(q["titulo"]), 18)
	)

	caixa_questao.add_child(_separador())

	caixa_questao.add_child(
		_texto(str(q["enunciado"]), 18)
	)

	for i in range(4):
		var alternativa := _botao(
			str(q["opcoes"][i]),
			_responder_questao.bind(i)
		)

		caixa_questao.add_child(alternativa)

	caixa_questao.add_child(
		_texto(
			"Tentativas restantes: %d"
			% (2 - erros_questao),
			14
		)
	)

	caixa_questao.add_child(
		_botao(
			"CANCELAR E VOLTAR AO MAPA",
			_cancelar_questao
		)
	)

	painel_questao.show()


func _cancelar_questao() -> void:
	painel_questao.hide()

	compra_pendente = ""
	quantidade_pendente = 0
	erros_questao = 0


func _responder_questao(indice: int) -> void:
	if questoes_resolvidas >= QUESTOES.size():
		return

	var q: Dictionary = QUESTOES[
		questoes_resolvidas
	]

	if indice == int(q["resposta"]):
		_resposta_correta(q)
	else:
		_resposta_errada()


func _resposta_correta(q: Dictionary) -> void:
	questoes_resolvidas += 1
	erros_questao = 0
	bloqueado_ate_dia = 0

	var ticker := compra_pendente
	var qtd := quantidade_pendente

	compra_pendente = ""
	quantidade_pendente = 0

	_mostrar_fala(
		"Parabéns! Resposta correta!",
		str(q["explicacao"]),
		func() -> void:
			_realizar_compra(ticker, qtd)
	)


func _resposta_errada() -> void:
	erros_questao += 1

	if erros_questao == 1:
		_mostrar_fala(
			"Essa não é a resposta correta!",
			"Calcule a porcentagem sobre o valor inicial e depois some o rendimento.",
			func() -> void:
				_mostrar_questao()
		)
		return

	if questoes_resolvidas == 0:
		bloqueado_ate_dia = maxi(
			15,
			Market.dia + 1
		)
	else:
		bloqueado_ate_dia = Market.dia + 1

	compra_pendente = ""
	quantidade_pendente = 0
	erros_questao = 0

	_mostrar_fala(
		"Você utilizou suas duas tentativas!",
		"A compra não foi desbloqueada. Continue acompanhando o mercado e tente novamente no dia %d."
		% bloqueado_ate_dia
	)


# ==================================================
# PASSAGEM DOS DIAS
# ==================================================

func _dia_avancou(_dia: int) -> void:
	_atualizar_mercado()
	painel_mercado.hide()

	if concluido:
		return

	var tentativa_liberada := false

	if bloqueado_ate_dia > 0:
		if Market.dia >= bloqueado_ate_dia:
			bloqueado_ate_dia = 0
			tentativa_liberada = true

	# DIA 15
	if Market.dia >= 15 and not aviso_dia_15:
		aviso_dia_15 = true

		_mostrar_fala(
			"Chegamos ao dia 15!",
			"O segundo desafio matemático está disponível! Para concluir o nível 2, termine todas as missões e alcance %d XP acumulados. Confira as CONQUISTAS para ganhar XP e use o boost da LOJA para dobrar a próxima recompensa. Faltam %d XP." % [GameState.META_XP_NIVEL_2, GameState.xp_faltante_nivel_2()]
		)
		return

	# DIA 16
	if Market.dia >= 16 and not aviso_dia_16:
		aviso_dia_16 = true

		_mostrar_fala(
			"NOVA MISSÃO: APRENDA A VENDER!",
			"Venda pelo menos uma ação da sua carteira. Não importa se houve lucro ou prejuízo. O importante é aprender a realizar uma venda!"
		)
		return

	# DIA 17
	if Market.dia >= 17 and not aviso_dia_17:
		aviso_dia_17 = true

		_mostrar_fala(
			"Hora de observar suas escolhas!",
			"Para avançar ao nível 3, a partir do dia 20 tenha uma ação com variação diária positiva, faça uma venda, resolva as duas questões, conclua as missões e alcance %d XP. Você tem %d XP." % [GameState.META_XP_NIVEL_2, GameState.xp]
		)
		return

	# DIA 20
	if Market.dia >= 20 and not aviso_dia_20:
		aviso_dia_20 = true

		_verificar_conclusao()

		if not concluido:
			_mostrar_fala(
				"Chegamos ao dia 20!",
				"Você chegou ao dia 20! " + _pendencias_nivel_2()
			)

		return

	# DIAS SEGUINTES
	_verificar_conclusao()

	if concluido:
		return

	if tentativa_liberada:
		_mostrar_fala(
			"Uma nova oportunidade chegou!",
			"Seu desafio matemático foi desbloqueado. Você pode tentar novamente quando quiser."
		)


# ==================================================
# SINAIS DO GAMESTATE
# ==================================================

func _dinheiro_mudou(_valor: float) -> void:
	_atualizar_mercado()


func _xp_mudou() -> void:
	if concluido:
		return
	# Verifica depois da atualizacao de XP e conquistas.
	call_deferred("_verificar_conclusao")


func _pendencias_nivel_2() -> String:
	var pendencias: Array[String] = []
	if GameState.xp_faltante_nivel_2() > 0:
		pendencias.append("Faltam %d XP. Faça conquistas ou use o boost da loja." % GameState.xp_faltante_nivel_2())
	if not GameState.todas_missoes_concluidas():
		pendencias.append("Conclua todas as missões.")
	if questoes_resolvidas < 2:
		pendencias.append("Resolva as duas questões matemáticas.")
	if not GameState.venda_nivel_2_realizada:
		pendencias.append("Venda pelo menos uma ação a partir do dia 16.")
	if not Market.carteira_tem_acao_positiva():
		pendencias.append("Mantenha uma ação com variação diária positiva.")
	if pendencias.is_empty():
		return "Todos os objetivos foram concluídos!"
	var resultado := ""
	for i in range(pendencias.size()):
		if i > 0:
			resultado += " "
		resultado += pendencias[i]
	return resultado


func _missao_mudou() -> void:
	_atualizar_mercado()
	_verificar_conclusao()


func _operacao_realizada(
	tipo: String,
	_ticker: String,
	_quantidade_operacao: int,
	_preco: float,
	_lucro: float
) -> void:
	_atualizar_mercado()

	if tipo == "venda":
		if GameState.venda_nivel_2_realizada:
			_mostrar_fala(
				"MISSÃO DE VENDA CONCLUÍDA!",
				"Ótimo! Você realizou uma venda. Agora continue observando as variações do mercado para tomar suas próximas decisões."
			)

	_verificar_conclusao()


# ==================================================
# CONCLUSÃO DO NÍVEL 2
# ==================================================

func _verificar_conclusao() -> void:
	if concluido:
		return

	# Requisito 1: chegar ao dia 20.
	if Market.dia < 20:
		return

	# Requisito 2: resolver as duas questões.
	if questoes_resolvidas < 2:
		return

	# Requisito 3: vender pelo menos uma ação
	# a partir do dia 16.
	if not GameState.venda_nivel_2_realizada:
		return

	# Requisito 4: possuir pelo menos uma ação
	# com variação diária positiva.
	if not Market.carteira_tem_acao_positiva():
		return

	# Requisito 5: completar todas as missões.
	if not GameState.todas_missoes_concluidas():
		return

	# Requisito 6: atingir o XP acumulado.
	if GameState.xp < GameState.META_XP_NIVEL_2:
		return

	# Guarda o XP conquistado antes de reiniciar no nivel 3.
	var xp_conquistado: int = GameState.xp
	concluido = true
	GameState.nivel_2_concluido = true
	GameState.fase_jogo = 3
	if is_instance_valid(hud):
		hud.call_deferred("_atualizar_tudo")

	_mostrar_fala(
		"PARABÉNS! VOCÊ CONCLUIU O NÍVEL 2!",
		"Você conquistou %d XP, concluiu os desafios e desbloqueou o nível 3! Agora começa com 0 XP." % xp_conquistado
	)
