extends CanvasLayer
## HUD: barra superior (dinheiro, patrimônio, rentabilidade, XP, recursos).

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


func _ready() -> void:
	botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	botao_notificacoes.pressed.connect(_on_botao_notificacoes_pressed)
	botao_config.pressed.connect(_on_botao_config_pressed)

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


func _on_botao_avancar_pressed() -> void:
	Market.avancar_dia()


func _on_botao_notificacoes_pressed() -> void:
	print("Notificações abertas")


func _on_botao_config_pressed() -> void:
	print("Configurações abertas")


func _on_dinheiro_mudou(_novo_valor: float) -> void:
	_atualizar_tudo()


func _on_dia_avancou(_dia: int) -> void:
	_atualizar_tudo()
