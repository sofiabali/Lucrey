extends CanvasLayer

@onready var label_dinheiro: Label = %ValorDinheiro
@onready var label_patrimonio: Label = %ValorPatrimonio
@onready var label_rentabilidade: Label = %ValorRentabilidade
@onready var label_dia: Label = %LabelDia
@onready var botao_avancar: Button = %BotaoAvancar


func _ready() -> void:
	botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	GameState.dinheiro_mudou.connect(_on_dinheiro_mudou)
	Market.dia_avancou.connect(_on_dia_avancou)
	_atualizar_tudo()
	
func _atualizar_tudo() -> void:

	label_dinheiro.text = "R$ %.2f" % GameState.dinheiro
	label_patrimonio.text = "R$ %.2f" % GameState.patrimonio()
	# Mudando tema a depender da rentabilidade
	var rent: float = GameState.rentabilidade()

	if rent < 0:
		label_rentabilidade.add_theme_color_override("font_color", Color.CRIMSON)
	elif rent > 0:
		label_rentabilidade.add_theme_color_override("font_color", Color("#2ECC71"))
	else:
		label_rentabilidade.remove_theme_color_override("font_color")

	label_rentabilidade.text = "%+.2f%%" % rent
	label_dia.text = "Dia %d" % Market.dia
	


func _on_botao_avancar_pressed() -> void:
	# TODO: fazer o dia avançar
	Market.avancar_dia()
	pass


func _on_dinheiro_mudou(_novo_valor: float) -> void:
	# TODO: atualizar a tela
	_atualizar_tudo()
	pass


func _on_dia_avancou(_dia: int) -> void:
	# TODO: atualizar a tela
	_atualizar_tudo()
	pass
