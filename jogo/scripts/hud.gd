extends CanvasLayer
## HUD: barra superior, painéis laterais, botão Investir, barra inferior
## e as telas cheias (carteira, notícias, missões, loja, conquistas, cotações).

const COR_POSITIVA := Color(0.18, 0.8, 0.44)
const COR_NEGATIVA := Color.CRIMSON

@onready var label_dinheiro: Label = %ValorDinheiro
@onready var label_patrimonio: Label = %ValorPatrimonio
@onready var label_rentabilidade: Label = %ValorRentabilidade
@onready var label_dia: Label = %LabelDia
@onready var label_nivel: Label = %LabelNivel
@onready var label_xp: Label = %LabelXp
@onready var barra_xp: ProgressBar = %BarraXp
@onready var label_moedas: Label = %ValorMoedas
@onready var label_gemas: Label = %ValorGemas
@onready var botao_avancar: Button = %BotaoAvancar
@onready var botao_notificacoes: Button = %Notificacoes
@onready var botao_config: Button = %BotaoConfig
@onready var botao_investir: Button = %BotaoInvestir
@onready var barra_inferior: BarraInferior = %BarraInferior

# Painéis laterais (cada um avisa o HUD por sinal quando o botão é clicado)
@onready var painel_carteira: PainelCarteira = %PainelCarteira
@onready var painel_missao: PainelMissao = %PainelMissao
@onready var painel_noticias: PainelNoticias = %PainelNoticias

# Telas cheias
@onready var tela_carteira: TelaCheia = %TelaCarteira
@onready var tela_noticias: TelaCheia = %TelaNoticias
@onready var tela_missoes: TelaCheia = %TelaMissoes
@onready var tela_loja: TelaCheia = %TelaLoja
@onready var tela_conquistas: TelaCheia = %TelaConquistas  # NOVO
@onready var tela_cotacoes: TelaCheia = %TelaCotacoes  # NOVO


func _ready() -> void:
	botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	botao_notificacoes.pressed.connect(_on_botao_notificacoes_pressed)
	botao_config.pressed.connect(_on_botao_config_pressed)
	botao_investir.pressed.connect(_on_botao_investir_pressed)
	barra_inferior.aba_selecionada.connect(_on_aba_selecionada)

	# .bind() entrega a tela escolhida para a função _abrir_tela
	painel_carteira.ver_carteira_pedido.connect(_abrir_tela.bind(tela_carteira))
	painel_missao.ver_missoes_pedido.connect(_abrir_tela.bind(tela_missoes))
	painel_noticias.ver_noticias_pedido.connect(_abrir_tela.bind(tela_noticias))

	for tela: TelaCheia in [tela_carteira, tela_noticias, tela_missoes, tela_loja, tela_conquistas, tela_cotacoes]:  # NOVO
		tela.fechada.connect(_on_tela_fechada)

	GameState.dinheiro_mudou.connect(_on_dinheiro_mudou)
	GameState.xp_mudou.connect(_atualizar_tudo)
	GameState.moedas_mudou.connect(_atualizar_tudo)
	GameState.gemas_mudou.connect(_atualizar_tudo)
	Market.dia_avancou.connect(_on_dia_avancou)

	_atualizar_tudo()


func _atualizar_tudo() -> void:
	# Dinheiro e patrimônio
	label_dinheiro.text = "R$ %.2f" % GameState.dinheiro
	label_patrimonio.text = "R$ %.2f" % GameState.patrimonio()

	# Rentabilidade (verde se positiva, vermelha se negativa)
	var rent: float = GameState.rentabilidade()
	label_rentabilidade.text = "%+.2f%%" % rent
	if rent < 0:
		label_rentabilidade.add_theme_color_override("font_color", COR_NEGATIVA)
	elif rent > 0:
		label_rentabilidade.add_theme_color_override("font_color", COR_POSITIVA)
	else:
		label_rentabilidade.remove_theme_color_override("font_color")

	# Cartão do investidor
	label_nivel.text = "NÍVEL %d" % GameState.nivel
	label_xp.text = "%d / %d XP" % [GameState.xp, GameState.xp_para_proximo_nivel()]
	barra_xp.max_value = GameState.xp_para_proximo_nivel()
	barra_xp.value = GameState.xp

	# Recursos e tempo
	label_moedas.text = "%d" % GameState.moedas
	label_gemas.text = "%d" % GameState.gemas
	label_dia.text = "Dia %d" % Market.dia


# --- Telas cheias -----------------------------------------------------

func _abrir_tela(tela: TelaCheia) -> void:
	_fechar_telas()
	tela.show()


func _fechar_telas() -> void:
	for tela: TelaCheia in [tela_carteira, tela_noticias, tela_missoes, tela_loja, tela_conquistas, tela_cotacoes]:  # NOVO
		tela.hide()


## Quando nenhuma tela cheia está aberta, a barra inferior volta para "Mapa".
func _on_tela_fechada() -> void:
	if not (tela_carteira.visible or tela_noticias.visible or tela_missoes.visible or tela_loja.visible or tela_conquistas.visible or tela_cotacoes.visible):  # NOVO
		barra_inferior.selecionar("Mapa")


func _on_aba_selecionada(nome: String) -> void:
	match nome:
		"Mapa":
			_fechar_telas()
		"Carteira":
			_abrir_tela(tela_carteira)
		"Cotações":  # NOVO
			_abrir_tela(tela_cotacoes)  # NOVO
		"Notícias":
			_abrir_tela(tela_noticias)
		"Missões":
			_abrir_tela(tela_missoes)
		"Conquistas":  # NOVO
			_abrir_tela(tela_conquistas)  # NOVO
		"Loja":
			_abrir_tela(tela_loja)
		_:
			print("Aba ainda sem tela: ", nome)


# --- Botões -----------------------------------------------------------

func _on_botao_avancar_pressed() -> void:
	Market.avancar_dia()


# Tela de notificações (pop-up ao lado do botão)
func _on_botao_notificacoes_pressed() -> void:
	var janela = $"TelaNotificações"
	var painel = janela.get_node("CenterContainer")

	painel.position = botao_notificacoes.global_position - janela.global_position + Vector2(
		botao_notificacoes.size.x - painel.size.x,
		botao_notificacoes.size.y + 8
	)

	janela.show()


# Tela de configurações (pop-up ao lado do botão)
func _on_botao_config_pressed() -> void:
	var janela = $"TelaConfigurações"
	var painel = janela.get_node("CenterContainer")

	painel.position = botao_config.global_position - janela.global_position + Vector2(
		botao_config.size.x - painel.size.x,
		botao_config.size.y + 8
	)

	janela.show()


func _on_botao_investir_pressed() -> void:
	print("Investir")


func _on_dinheiro_mudou(_novo_valor: float) -> void:
	_atualizar_tudo()


func _on_dia_avancou(_dia: int) -> void:
	_atualizar_tudo()
