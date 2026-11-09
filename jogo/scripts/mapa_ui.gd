extends Control

# Exemplo de referências aos painéis já existentes no seu projeto
@onready var painel_carteira = $"../PainelCarteira"
@onready var painel_missao = $"../PainelMissao"

func _ready() -> void:
	# Conectando os sinais de clique dos botões dos edifícios
	$EdificiosContainer/BotaoEdificio1.pressed.connect(_on_edificio_1_clicked)
	$EdificiosContainer/BotaoEdificio2.pressed.connect(_on_edificio_2_clicked)

func _on_edificio_1_clicked() -> void:
	print("Edifício 1 clicado! Abrindo painel correspondente...")
	if painel_carteira:
		painel_carteira.visible = not painel_carteira.visible

func _on_edificio_2_clicked() -> void:
	print("Edifício 2 clicado! Abrindo missões...")
	if painel_missao:
		painel_missao.visible = not painel_missao.visible
