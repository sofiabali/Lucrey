extends Control
## LUCREY: cidade original estática, arrastável em quatro direções com zoom, sem avatar.
## Resolução de referência: 1536 x 1024; UI dinâmica criada em tempo de execução.

const BG = preload("res://assets/sprites/cidade.png")
const MAPA_LARGURA := 1536.0
const MAPA_ALTURA := 1024.0
const ZOOM_INICIAL := 1.0
const ZOOM_PASSO := 0.08
const ZOOM_MAXIMO := 1.90
const DISTANCIA_MIN_ARRASTO := 9.0
const COR_FUNDO := Color("091521")
const COR_CARTAO := Color("101f2e")
const COR_VERDE := Color("45b86e")
const COR_TEXTO := Color("e9f2f4")

var lbl_dinheiro: Label
var lbl_patrimonio: Label
var lbl_rentabilidade: Label
var lbl_dia: Label
var lbl_nivel: Label
var lbl_missao: Label
var lbl_pontos: Label
var lbl_notificacao: Label
var barra_notificacao: PanelContainer
var id_notificacao: int = 0
var progresso_xp: ProgressBar
var painel_modal: PanelContainer
var pagina_atual: String = ""
var ticker_ativo: String = "PETR4"
var quantidade_input: SpinBox
var compra_info: Label
var trading_select: OptionButton
var grafico_ativo: Control
var barra_lateral: PanelContainer
var botao_lateral: Button
var lateral_aberta: bool = true
var secoes_laterais: Dictionary = {}
var scroll_lateral: ScrollContainer
# O cenário e as áreas clicáveis pertencem à mesma camada para manter alinhamento.
var area_visivel_mapa: Control
var camada_mapa: Control
var deslocamento_mapa: Vector2 = Vector2.ZERO
var zoom_mapa: float = ZOOM_INICIAL
var arrastando_mapa: bool = false
var arrasto_foi_movimento: bool = false
var posicao_ultimo_arrasto: Vector2 = Vector2.ZERO
var posicao_inicio_arrasto: Vector2 = Vector2.ZERO

func _ready() -> void:
	_build_city()
	_build_clickable_places()
	_build_notifications()
	

func _build_city() -> void:
	# A cidade original é uma imagem estática: sem NPCs ou veículos animados.
	# Zoom discreto cria sobra horizontal para deslocamento, sem deixar faixas vazias.
	area_visivel_mapa = Control.new()
	area_visivel_mapa.name = "AreaVisivelCidade"
	area_visivel_mapa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area_visivel_mapa.clip_contents = true
	area_visivel_mapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area_visivel_mapa)

	camada_mapa = Control.new()
	camada_mapa.name = "MapaArrastavel"
	camada_mapa.size = Vector2(MAPA_LARGURA, MAPA_ALTURA)
	camada_mapa.scale = Vector2(ZOOM_INICIAL, ZOOM_INICIAL)
	camada_mapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_visivel_mapa.add_child(camada_mapa)

	var fundo := TextureRect.new()
	fundo.name = "ImagemDaCidade"
	fundo.texture = BG
	fundo.size = Vector2(MAPA_LARGURA, MAPA_ALTURA)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada_mapa.add_child(fundo)

	zoom_mapa = _zoom_minimo()
	if zoom_mapa < ZOOM_INICIAL:
		zoom_mapa = ZOOM_INICIAL
	camada_mapa.scale = Vector2.ONE * zoom_mapa
	_centralizar_mapa()
	_atualizar_posicao_mapa()

func _zoom_minimo() -> float:
	if area_visivel_mapa == null or area_visivel_mapa.size == Vector2.ZERO:
		return 1.0
	var base_x := area_visivel_mapa.size.x / MAPA_LARGURA
	var base_y := area_visivel_mapa.size.y / MAPA_ALTURA
	return maxf(1.0, maxf(base_x, base_y))

func _centralizar_mapa() -> void:
	if area_visivel_mapa == null:
		return
	var tam := Vector2(MAPA_LARGURA, MAPA_ALTURA) * zoom_mapa
	deslocamento_mapa = (area_visivel_mapa.size - tam) / 2.0

func _atualizar_posicao_mapa() -> void:
	if camada_mapa == null or area_visivel_mapa == null:
		return
	camada_mapa.scale = Vector2.ONE * zoom_mapa
	var tam := Vector2(MAPA_LARGURA, MAPA_ALTURA) * zoom_mapa
	var minimo_x := minf(0.0, area_visivel_mapa.size.x - tam.x)
	var minimo_y := minf(0.0, area_visivel_mapa.size.y - tam.y)
	var maximo_x := maxf(0.0, area_visivel_mapa.size.x - tam.x)
	var maximo_y := maxf(0.0, area_visivel_mapa.size.y - tam.y)
	if tam.x <= area_visivel_mapa.size.x:
		deslocamento_mapa.x = (area_visivel_mapa.size.x - tam.x) / 2.0
	else:
		deslocamento_mapa.x = clampf(deslocamento_mapa.x, minimo_x, 0.0)
	if tam.y <= area_visivel_mapa.size.y:
		deslocamento_mapa.y = (area_visivel_mapa.size.y - tam.y) / 2.0
	else:
		deslocamento_mapa.y = clampf(deslocamento_mapa.y, minimo_y, 0.0)
	camada_mapa.position = deslocamento_mapa

func _aplicar_zoom(delta: float, foco_tela: Vector2) -> void:
	if camada_mapa == null or area_visivel_mapa == null:
		return
	if is_instance_valid(painel_modal):
		return
	var antigo := zoom_mapa
	var novo := clampf(zoom_mapa + delta, _zoom_minimo(), ZOOM_MAXIMO)
	if is_equal_approx(antigo, novo):
		return
	var foco_local := (foco_tela - deslocamento_mapa) / maxf(antigo, 0.001)
	zoom_mapa = novo
	deslocamento_mapa = foco_tela - foco_local * zoom_mapa
	_atualizar_posicao_mapa()

func _pode_iniciar_arrasto(pos: Vector2) -> bool:
	# Interface, menus e janelas não devem provocar movimentos do cenário.
	if is_instance_valid(painel_modal):
		return false
	if pos.y < 172.0 or pos.y > 915.0:
		return false
	if lateral_aberta and pos.x >= 1170.0:
		return false
	return true

func _iniciar_arrasto(pos: Vector2) -> void:
	arrastando_mapa = _pode_iniciar_arrasto(pos)
	arrasto_foi_movimento = false
	posicao_inicio_arrasto = pos
	posicao_ultimo_arrasto = pos

func _mover_arrasto(pos: Vector2) -> void:
	if not arrastando_mapa:
		return
	if pos.distance_to(posicao_inicio_arrasto) >= DISTANCIA_MIN_ARRASTO:
		arrasto_foi_movimento = true
	if arrasto_foi_movimento:
		deslocamento_mapa += pos - posicao_ultimo_arrasto
		_atualizar_posicao_mapa()
	posicao_ultimo_arrasto = pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_iniciar_arrasto(event.position)
			else:
				arrastando_mapa = false
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_aplicar_zoom(ZOOM_PASSO, event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_aplicar_zoom(-ZOOM_PASSO, event.position)
	elif event is InputEventMouseMotion and arrastando_mapa:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_mover_arrasto(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_iniciar_arrasto(event.position)
		else:
			arrastando_mapa = false
	elif event is InputEventScreenDrag:
		_mover_arrasto(event.position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_atualizar_posicao_mapa()

func _style_panel(p: PanelContainer, background: Color = COR_FUNDO, border: Color = Color("345365")) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(13)
	box.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", box)

func _panel(rect: Rect2, background: Color = COR_FUNDO) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position
	p.size = rect.size
	_style_panel(p, background)
	add_child(p)
	return p

func _label(texto: String, tamanho: int = 16, cor: Color = COR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", cor)
	l.add_theme_font_size_override("font_size", tamanho)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(texto: String, callback: Callable, destaque: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 39)
	b.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = COR_VERDE if destaque else Color("193448")
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2d8450") if destaque else Color("305671")
	b.add_theme_stylebox_override("hover", hover)
	b.pressed.connect(callback)
	return b

func _vbox(separacao: int = 9) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separacao)
	return v

func _toggle_section(titulo: String) -> void:
	var secao: Dictionary = secoes_laterais[titulo]
	var corpo: VBoxContainer = secao["corpo"]
	var botao: Button = secao["botao"]
	corpo.visible = not corpo.visible
	botao.text = ("▼  " if corpo.visible else "▶  ") + titulo


func _build_notifications() -> void:
	# Instruções de navegação aparecem somente no tutorial ou ao clicar em ajuda.
	# Notificações de eventos são temporárias e não deixam uma faixa fixa no mapa.
	barra_notificacao = _panel(Rect2(252, 115, 820, 52), Color("092434", 0.93))
	barra_notificacao.visible = false
	lbl_notificacao = _label("", 16)
	barra_notificacao.add_child(lbl_notificacao)

func _build_clickable_places() -> void:
	# Áreas transparentes diretamente sobre os prédios e suas placas da cidade original.
	# A posição é na resolução lógica da cena: 1536 x 1024.
	# As regiões não cobrem a navegação inferior nem a barra de informações.
	var locais := [
		["B4", Rect2(310, 130, 340, 255), "COTAÇÕES"],
		["CHANNEU", Rect2(690, 100, 200, 230), "INVESTIR"],
		["BRANCO DO BRASIL", Rect2(970, 140, 255, 265), "CARTEIRA"],
		["FEIRA", Rect2(120, 410, 320, 240), "LOJA"],
		["PRAÇA DO INVESTIDOR", Rect2(625, 410, 250, 160), "MISSÕES"],
		["CENTRO DE NOTÍCIAS", Rect2(925, 425, 225, 245), "NOTÍCIAS"],
		["TREINAMENTO", Rect2(140, 675, 270, 205), "TUTORIAL"],
		["MINHAS EMPRESAS", Rect2(485, 645, 285, 235), "CARTEIRA"],
		["RANKING", Rect2(900, 660, 245, 225), "CONQUISTAS"]
	]
	for local in locais:
		var zona := Button.new()
		zona.text = ""
		zona.position = local[1].position
		zona.size = local[1].size
		zona.tooltip_text = "%s — abrir %s" % [local[0], local[2]]
		zona.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		zona.focus_mode = Control.FOCUS_NONE
		var transparente := StyleBoxEmpty.new()
		zona.add_theme_stylebox_override("normal", transparente)
		zona.add_theme_stylebox_override("pressed", transparente)
		zona.add_theme_stylebox_override("disabled", transparente)
		var sobre := StyleBoxFlat.new()
		sobre.bg_color = Color(0.22, 0.74, 0.44, 0.11)
		sobre.border_color = Color(0.38, 0.93, 0.62, 0.58)
		sobre.set_border_width_all(2)
		sobre.set_corner_radius_all(12)
		zona.add_theme_stylebox_override("hover", sobre)
		zona.pressed.connect(_open_place.bind(str(local[2])))
		camada_mapa.add_child(zona)

func _open_place(destino: String) -> void:
	# Um gesto de arrasto nunca deve abrir um prédio por acidente.
	if arrasto_foi_movimento:
		return

func _nav(destino: String) -> void:
	if destino == "MAPA":
		_fechar()

func _advance_day() -> void:
	Market.avancar_dia()
	GameState.salvar()

func _notify(texto: String) -> void:
	if lbl_notificacao == null or barra_notificacao == null:
		return
	id_notificacao += 1
	var aviso_atual := id_notificacao
	lbl_notificacao.text = texto
	barra_notificacao.visible = true
	_ocultar_notificacao_apos_tempo(aviso_atual)

func _ocultar_notificacao_apos_tempo(aviso_atual: int) -> void:
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(barra_notificacao) and aviso_atual == id_notificacao:
		barra_notificacao.visible = false

func _moeda(valor: float) -> String:
	return "R$ %.2f" % valor

func _fechar() -> void:
	if is_instance_valid(painel_modal):
		painel_modal.queue_free()
	painel_modal = null
	pagina_atual = ""



func _refresh_purchase_info() -> void:
	if not is_instance_valid(compra_info) or not is_instance_valid(quantidade_input):
		return
	var acao := Market.buscar(ticker_ativo)
	if acao == null:
		return
	compra_info.text = "%s • %s\nCotação: %s  |  Você possui: %d ações\nValor da operação: %s  |  Saldo: %s" % [acao.nome, acao.setor, _moeda(acao.preco), int(GameState.carteira.get(ticker_ativo, 0)), _moeda(acao.preco * quantidade_input.value), _moeda(GameState.dinheiro)]

func _page_controles(v: VBoxContainer) -> void:
	v.add_child(_label("COMO NAVEGAR PELA CIDADE", 24, COR_VERDE))
	v.add_child(_label("Clique e segure o botão esquerdo do mouse sobre a cidade e arraste para a direita, esquerda, cima ou baixo.", 18))
	v.add_child(_label("Gire a roda do mouse para cima para aproximar (zoom +) ou para baixo para afastar (zoom -).", 18))
	v.add_child(_label("Clique em um prédio para acessar sua atividade. Os menus e os painéis informativos permanecem fixos.", 18))
	v.add_child(_label("O mapa tem limites de movimento para não mostrar áreas vazias. Os carros e pedestres do cenário são apenas ilustrativos.", 16))
	v.add_child(_button("VOLTAR À CIDADE", _fechar, true))

func _page_tutorial(v: VBoxContainer) -> void:
	v.add_child(_label("BEM-VINDO AO LUCREY!", 25, COR_VERDE))
	v.add_child(_label("O LUCREY é um jogo de educação financeira. Não envolve dinheiro real nem aconselhamento financeiro.", 18))
	v.add_child(_label("1 • Comece com R$ 1.000 fictícios. Clique em INVESTIR para comprar ações.", 17))
	v.add_child(_label("2 • Clique em AVANÇAR DIA para gerar mudanças nos preços e notícias fictícias.", 17))
	v.add_child(_label("3 • Em CARTEIRA acompanhe os ativos, o preço médio e seu resultado.", 17))
	v.add_child(_label("4 • Em MISSÕES, complete objetivos para ganhar experiência e subir de nível.", 17))
	v.add_child(_label("5 • Arraste a cidade para direita, esquerda, cima e baixo com o mouse ou toque. Use a roda do mouse para controlar o zoom e clique nos prédios para abrir as funções. Não há avatar ou veículos animados.", 17))
	v.add_child(_label("6 • Use AJUSTES para salvar e carregar seu progresso.", 17))
	v.add_child(_label("DICA: utilize os menus inferiores e as seções recolhíveis na lateral direita.", 16, COR_VERDE))
	v.add_child(_button("ENTENDI • COMEÇAR", _finish_tutorial, true))

func _finish_tutorial() -> void:
	GameState.tutorial_visto = true
	GameState.salvar()
