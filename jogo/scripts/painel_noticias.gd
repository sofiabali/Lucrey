extends PanelContainer
## Painel "Notícias": mostra as últimas notícias geradas pelo mercado.

const QTD_VISIVEL := 3
const COR_BOA := Color(0.18, 0.8, 0.443)
const COR_RUIM := Color.CRIMSON
const COR_NEUTRA := Color(0.561, 0.631, 0.702)

@onready var lista: VBoxContainer = %Lista
@onready var botao_ver: Button = %BotaoVerNoticias


func _ready() -> void:
	Market.noticias_mudou.connect(_atualizar)
	botao_ver.pressed.connect(func() -> void: print("Ver todas as notícias"))
	_atualizar()


func _atualizar() -> void:
	for filho in lista.get_children():
		filho.queue_free()

	if Market.noticias.is_empty():
		_adicionar_texto("Sem notícias por enquanto. Avance o dia!", COR_NEUTRA)
		return

	for i in mini(QTD_VISIVEL, Market.noticias.size()):
		var n: Dictionary = Market.noticias[i]
		var cor := COR_BOA if n["positiva"] else COR_RUIM
		_adicionar_texto("Dia %d · %s" % [n["dia"], n["texto"]], cor)


func _adicionar_texto(texto: String, cor: Color) -> void:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(240, 0)
	l.add_theme_color_override("font_color", cor)
	lista.add_child(l)
