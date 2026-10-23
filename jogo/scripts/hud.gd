extends CanvasLayer

@onready var label_dinheiro: Label = %LabelDinheiro
@onready var label_patrimonio: Label = %LabelPatrimonio
@onready var label_rentabilidade: Label = %LabelRentabilidade
@onready var label_dia: Label = %LabelDia
@onready var botao_avancar: Button = %BotaoAvancar


func _ready() -> void:
	botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	GameState.dinheiro_mudou.connect(_on_dinheiro_mudou)
	Market.dia_avancou.connect(_on_dia_avancou)
	_atualizar_tudo()
	
func _atualizar_tudo() -> void:
	# TODO: preencher o .text de cada Label (formato igual aos prints do main.gd)
	label_dinheiro.text = "Dinheiro: R$ %.2f" % GameState.dinheiro
	label_patrimonio.text = "Patrimônio: R$ %.2f" % GameState.patrimonio()
	label_rentabilidade.text = "Rentabilidade: R$ %+.2f%%" % GameState.rentabilidade()
	label_dia.text = "Dia R$ %d" % Market.dia
	pass


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
