class_name BarraInferior
extends PanelContainer
## Barra de navegação inferior. Emite o nome da aba escolhida.

signal aba_selecionada(nome: String)

const ABAS := ["Mapa", "Carteira", "Cotações", "Notícias", "Missões", "Conquistas", "Loja"]

@onready var abas: HBoxContainer = %Abas


func _ready() -> void:
	var grupo := ButtonGroup.new()  # só um botão do grupo fica marcado por vez
	for nome: String in ABAS:
		var botao := Button.new()
		botao.text = nome
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.theme_type_variation = &"BotaoAba"
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.pressed.connect(func() -> void: aba_selecionada.emit(nome))
		abas.add_child(botao)
		if nome == "Mapa":
			botao.button_pressed = true
