class_name TelaCheia
extends Control
## Base das telas de tela cheia (notícias, missões, carteira...).
##
## Monta a moldura (fundo escurecido, painel central, título, botão VOLTAR e
## uma área rolável) e deixa três "ganchos" para as telas filhas preencherem:
##   _titulo()    -> texto do título
##   _construir() -> roda uma vez; ligue aqui os sinais do jogo
##   _atualizar() -> redesenha o conteúdo (roda ao abrir e quando você chamar)

signal fechada

const COR_TEXTO := Color(0.95, 0.96, 0.97)
const COR_NEUTRA := Color(0.561, 0.631, 0.702)
const COR_BOA := Color(0.18, 0.8, 0.443)
const COR_RUIM := Color.CRIMSON
const COR_ALERTA := Color(0.96, 0.77, 0.26)

## Área onde as telas filhas colocam o conteúdo.
var conteudo: VBoxContainer


func _ready() -> void:
	hide()
	_montar()
	_construir()
	visibility_changed.connect(_ao_mudar_visibilidade)
	_atualizar()


# --- Ganchos (as telas filhas sobrescrevem) ---------------------------

func _titulo() -> String:
	return "Tela"


func _construir() -> void:
	pass


func _atualizar() -> void:
	pass


# --- Moldura ----------------------------------------------------------

## Monta a moldura padrão. A tela da carteira sobrescreve isto com "pass",
## porque a moldura dela já foi desenhada no editor.
func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.04, 0.07, 0.88)
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(1100, 650)
	centro.add_child(painel)

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	painel.add_child(margem)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	margem.add_child(caixa)

	# Cabeçalho: título à esquerda, VOLTAR à direita
	var cabecalho := HBoxContainer.new()
	caixa.add_child(cabecalho)

	var l_titulo := criar_label(_titulo(), 32)
	l_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(l_titulo)

	var voltar := Button.new()
	voltar.text = "VOLTAR"
	voltar.custom_minimum_size = Vector2(110, 40)
	voltar.pressed.connect(hide)
	cabecalho.add_child(voltar)

	caixa.add_child(HSeparator.new())

	# Área rolável, para listas maiores que a janela
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa.add_child(rolagem)

	conteudo = VBoxContainer.new()
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 10)
	rolagem.add_child(conteudo)


func _ao_mudar_visibilidade() -> void:
	if visible:
		_atualizar()
	else:
		fechada.emit()


## ESC fecha a tela.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


# --- Ferramentas para as telas filhas ---------------------------------

## Remove todos os filhos de um container (para redesenhar do zero).
func limpar(caixa: Control) -> void:
	for filho in caixa.get_children():
		caixa.remove_child(filho)
		filho.queue_free()


func criar_label(texto: String, tamanho: int = 16, cor: Color = COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


## Cartão com margem interna; devolve o container onde colocar o conteúdo.
func criar_cartao(margem_px: int = 14) -> PanelContainer:
	var cartao := PanelContainer.new()
	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, margem_px)
	cartao.add_child(margem)
	return cartao
