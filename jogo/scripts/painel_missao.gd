extends PanelContainer
## Painel "Missão ativa": título, descrição, progresso e recompensa.

@onready var label_titulo: Label = %LabelTituloMissao
@onready var label_descricao: Label = %LabelDescricao
@onready var label_progresso: Label = %LabelProgresso
@onready var barra: ProgressBar = %BarraMissao
@onready var label_recompensa: Label = %LabelRecompensa
@onready var botao_ver: Button = %BotaoVerMissoes


func _ready() -> void:
	GameState.missao_mudou.connect(_atualizar)
	GameState.dinheiro_mudou.connect(func(_v: float) -> void: _atualizar())
	botao_ver.pressed.connect(func() -> void: print("Ver missões"))
	_atualizar()


func _atualizar() -> void:
	var m: Dictionary = GameState.missao_atual()
	if m.is_empty():
		label_titulo.text = "Tudo concluído!"
		label_descricao.text = "Você completou todas as missões disponíveis."
		label_progresso.text = ""
		barra.value = 0
		label_recompensa.text = ""
		return

	var meta: int = m["meta"]
	var progresso: int = mini(GameState.progresso_missao(), meta)
	label_titulo.text = m["titulo"]
	label_descricao.text = m["descricao"]
	label_progresso.text = "%d / %d" % [progresso, meta]
	barra.max_value = meta
	barra.value = progresso
	label_recompensa.text = "Recompensa: %d moedas · %d XP" % [m["moedas"], m["xp"]]
