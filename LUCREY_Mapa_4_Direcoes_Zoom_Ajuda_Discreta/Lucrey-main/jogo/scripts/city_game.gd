extends Control
## LUCREY: cidade original estática, arrastável em quatro direções com zoom, sem avatar.
## Resolução de referência: 1536 x 1024; UI dinâmica criada em tempo de execução.

const ChartScript = preload("res://scripts/price_chart.gd")
const BG = preload("res://assets/cidade_limpa.jpg")
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
	_build_header()
	_build_sides()
	_build_navigation()
	_build_notifications()
	GameState.estado_mudou.connect(_refresh)
	GameState.xp_mudou.connect(_refresh)
	GameState.mensagem.connect(_notify)
	Market.dia_avancou.connect(_on_day)
	_refresh()
	if not GameState.tutorial_visto:
		mostrar_pagina("TUTORIAL")

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

func _build_header() -> void:
	var p := _panel(Rect2(12, 8, 1512, 96), Color("061420", 0.98))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	p.add_child(row)
	var marca := _vbox(3)
	marca.custom_minimum_size.x = 200
	marca.add_child(_label("↗ LUCREY", 31, COR_VERDE))
	marca.add_child(_label("JOGO EDUCATIVO DE AÇÕES", 12))
	row.add_child(marca)
	var investidor := _vbox(4)
	investidor.custom_minimum_size.x = 230
	lbl_nivel = _label("INVESTIDOR • NÍVEL 1", 16)
	investidor.add_child(lbl_nivel)
	progresso_xp = ProgressBar.new()
	progresso_xp.custom_minimum_size = Vector2(200, 17)
	progresso_xp.show_percentage = false
	investidor.add_child(progresso_xp)
	row.add_child(investidor)
	var dinheiro_box := _vbox()
	dinheiro_box.custom_minimum_size.x = 210
	dinheiro_box.add_child(_label("DINHEIRO DISPONÍVEL", 12))
	lbl_dinheiro = _label("", 24)
	dinheiro_box.add_child(lbl_dinheiro)
	row.add_child(dinheiro_box)
	var patrimonio_box := _vbox()
	patrimonio_box.custom_minimum_size.x = 210
	patrimonio_box.add_child(_label("PATRIMÔNIO TOTAL", 12))
	lbl_patrimonio = _label("", 24)
	patrimonio_box.add_child(lbl_patrimonio)
	row.add_child(patrimonio_box)
	var rent_box := _vbox()
	rent_box.custom_minimum_size.x = 155
	rent_box.add_child(_label("RENTABILIDADE", 12))
	lbl_rentabilidade = _label("", 23)
	rent_box.add_child(lbl_rentabilidade)
	row.add_child(rent_box)
	var controles := _vbox(5)
	lbl_dia = _label("DIA 0", 15)
	controles.add_child(lbl_dia)
	controles.add_child(_button("AVANÇAR DIA ›", _advance_day, true))
	row.add_child(controles)

func _build_sides() -> void:
	# Um único painel sobre a lateral: elimina caixas duplicadas sobre a arte.
	barra_lateral = _panel(Rect2(1178, 115, 346, 780), Color("061420", 0.975))
	var estrutura := _vbox(6)
	barra_lateral.add_child(estrutura)
	var topo := HBoxContainer.new()
	estrutura.add_child(topo)
	var legenda := _label("PAINEL DE INFORMAÇÕES", 17, COR_VERDE)
	legenda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(legenda)
	topo.add_child(_button("◀", _toggle_sidebar))
	scroll_lateral = ScrollContainer.new()
	scroll_lateral.custom_minimum_size = Vector2(308, 690)
	scroll_lateral.size_flags_vertical = Control.SIZE_EXPAND_FILL
	estrutura.add_child(scroll_lateral)
	var seccoes := _vbox(6)
	seccoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_lateral.add_child(seccoes)
	_add_side_section(seccoes, "MISSÃO ATIVA", "MISSÕES", "Ver objetivo e recompensas", true)
	_add_side_section(seccoes, "MINHA CARTEIRA", "CARTEIRA", "Saldo, patrimônio e operações", false)
	_add_side_section(seccoes, "COTAÇÕES", "COTAÇÕES", "Veja preços e gráficos", false)
	_add_side_section(seccoes, "ÚLTIMAS NOTÍCIAS", "NOTÍCIAS", "Acompanhe todos os eventos", false)
	_add_side_section(seccoes, "CONQUISTAS", "CONQUISTAS", "Experiência, pontos e medalhas", false)
	botao_lateral = _button("◀ INFORMAÇÕES", _toggle_sidebar)
	botao_lateral.position = Vector2(1363, 119)
	botao_lateral.size = Vector2(160, 44)
	botao_lateral.visible = false
	add_child(botao_lateral)

func _add_side_section(pai: VBoxContainer, titulo: String, destino: String, resumo: String, abrir: bool) -> void:
	var p := PanelContainer.new()
	_style_panel(p, Color("152a39", 0.92), Color("335366"))
	pai.add_child(p)
	var coluna := _vbox(5)
	p.add_child(coluna)
	var cab := _button(("▼  " if abrir else "▶  ") + titulo, _toggle_section.bind(titulo))
	coluna.add_child(cab)
	var corpo := _vbox(6)
	coluna.add_child(corpo)
	corpo.visible = abrir
	corpo.add_child(_label(resumo, 14))
	if titulo == "MISSÃO ATIVA":
		lbl_missao = _label("", 14)
		corpo.add_child(lbl_missao)
	elif titulo == "MINHA CARTEIRA":
		lbl_pontos = _label("", 14, COR_VERDE)
		corpo.add_child(lbl_pontos)
	corpo.add_child(_button("VER " + ("TODAS" if destino == "NOTÍCIAS" else destino), mostrar_pagina.bind(destino), true))
	secoes_laterais[titulo] = {"botao": cab, "corpo": corpo}

func _toggle_section(titulo: String) -> void:
	var secao: Dictionary = secoes_laterais[titulo]
	var corpo: VBoxContainer = secao["corpo"]
	var botao: Button = secao["botao"]
	corpo.visible = not corpo.visible
	botao.text = ("▼  " if corpo.visible else "▶  ") + titulo

func _toggle_sidebar() -> void:
	lateral_aberta = not lateral_aberta
	barra_lateral.visible = lateral_aberta
	botao_lateral.visible = not lateral_aberta

func _build_navigation() -> void:
	var nav := _panel(Rect2(14, 922, 1508, 87), Color("061420", 0.98))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	nav.add_child(row)
	for entrada in ["INVESTIR", "CARTEIRA", "COTAÇÕES", "MISSÕES", "CONQUISTAS", "LOJA", "AJUSTES"]:
		var b := _button(entrada, _nav.bind(entrada), entrada == "INVESTIR")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)


func _build_notifications() -> void:
	# Instruções de navegação aparecem somente no tutorial ou ao clicar em ajuda.
	# Notificações de eventos são temporárias e não deixam uma faixa fixa no mapa.
	barra_notificacao = _panel(Rect2(252, 115, 820, 52), Color("092434", 0.93))
	barra_notificacao.visible = false
	lbl_notificacao = _label("", 16)
	barra_notificacao.add_child(lbl_notificacao)
	var ajuda := _button("?", mostrar_pagina.bind("CONTROLES"))
	ajuda.name = "AjudaControles"
	ajuda.tooltip_text = "Ajuda: como mover o mapa e utilizar o zoom"
	ajuda.position = Vector2(20, 118)
	ajuda.size = Vector2(49, 43)
	add_child(ajuda)

func _build_clickable_places() -> void:
	# Áreas transparentes diretamente sobre os prédios e suas placas da cidade original.
	# A posição é na resolução lógica da cena: 1536 x 1024.
	# As regiões não cobrem a navegação inferior nem a barra de informações.
	var locais := [
		["B4", Rect2(214, 102, 341, 253), "COTAÇÕES"],
		["CHANNEU", Rect2(709, 101, 250, 228), "INVESTIR"],
		["BRANCO DO BRASIL", Rect2(1139, 142, 254, 263), "CARTEIRA"],
		["FEIRA", Rect2(18, 419, 320, 237), "LOJA"],
		["PRAÇA DO INVESTIDOR", Rect2(574, 437, 327, 162), "MISSÕES"],
		["CENTRO DE NOTÍCIAS", Rect2(1055, 414, 238, 278), "NOTÍCIAS"],
		["TREINAMENTO", Rect2(19, 742, 258, 175), "TUTORIAL"],
		["MINHAS EMPRESAS", Rect2(435, 737, 318, 189), "CARTEIRA"],
		["RANKING", Rect2(1011, 735, 242, 193), "CONQUISTAS"]
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
	mostrar_pagina(destino)

func _nav(destino: String) -> void:
	if destino == "MAPA":
		_fechar()
	else:
		mostrar_pagina(destino)

func _refresh() -> void:
	if lbl_dinheiro == null:
		return
	lbl_dinheiro.text = _moeda(GameState.dinheiro)
	lbl_patrimonio.text = _moeda(GameState.patrimonio())
	lbl_rentabilidade.text = "%+.2f%%" % GameState.rentabilidade()
	lbl_rentabilidade.add_theme_color_override("font_color", COR_VERDE if GameState.rentabilidade() >= 0.0 else Color("ff7777"))
	lbl_dia.text = "DIA %d" % Market.dia
	lbl_nivel.text = "INVESTIDOR • NÍVEL %d" % GameState.nivel
	progresso_xp.max_value = float(GameState.xp_para_proximo_nivel())
	progresso_xp.value = float(GameState.xp)
	lbl_pontos.text = "⭐ %d PONTOS  •  %d CONQUISTAS" % [GameState.pontos, GameState.conquistas.size()]
	lbl_missao.text = "Todas as missões concluídas!"
	for m in GameState.MISSOES:
		if str(m["id"]) not in GameState.missoes_concluidas:
			lbl_missao.text = "%s\n\n%s" % [m["titulo"], m["texto"]]
			break

func _on_day(_dia: int) -> void:
	GameState.registrar_dia()
	_notify("Dia %d • %s" % [Market.dia, Market.ultima_noticia])
	if pagina_atual != "":
		mostrar_pagina(pagina_atual)

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

func mostrar_pagina(pagina: String) -> void:
	_fechar()
	pagina_atual = pagina
	painel_modal = _panel(Rect2(250, 177, 908, 710), Color("091723", 0.985))
	var v := _vbox(12)
	painel_modal.add_child(v)
	var titulo := HBoxContainer.new()
	v.add_child(titulo)
	var cabecalho := _label(pagina + "  •  LUCREY", 26, COR_VERDE)
	cabecalho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_child(cabecalho)
	titulo.add_child(_button("✕ FECHAR", _fechar))
	var barra := HSeparator.new()
	v.add_child(barra)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var conteudo := _vbox(14)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(conteudo)
	match pagina:
		"INVESTIR": _page_investir(conteudo)
		"CARTEIRA": _page_carteira(conteudo)
		"COTAÇÕES": _page_cotacoes(conteudo)
		"GRÁFICO": _page_grafico(conteudo)
		"NOTÍCIAS": _page_noticias(conteudo)
		"MISSÕES": _page_missoes(conteudo)
		"CONQUISTAS": _page_conquistas(conteudo)
		"LOJA": _page_loja(conteudo)
		"AJUSTES": _page_ajustes(conteudo)
		"TUTORIAL": _page_tutorial(conteudo)
		"CONTROLES": _page_controles(conteudo)
		_: conteudo.add_child(_label("Página em desenvolvimento."))

func _page_investir(v: VBoxContainer) -> void:
	v.add_child(_label("Corretora • negocie ações fictícias e observe os riscos de mercado.", 16))
	v.add_child(_label("SELECIONE UMA AÇÃO", 15, COR_VERDE))
	trading_select = OptionButton.new()
	trading_select.custom_minimum_size = Vector2(0, 44)
	trading_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Regras locais do OptionButton: não usar o fundo verde do tema global.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("1d394c")
	normal.border_color = Color("49728b")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	normal.set_content_margin_all(9)
	trading_select.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("2d5068")
	trading_select.add_theme_stylebox_override("hover", hover)
	trading_select.add_theme_stylebox_override("pressed", hover)
	trading_select.add_theme_color_override("font_color", COR_TEXTO)
	trading_select.add_theme_font_size_override("font_size", 17)
	var menu := trading_select.get_popup()
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color("122637")
	popup_style.border_color = Color("487189")
	popup_style.set_border_width_all(1)
	popup_style.set_corner_radius_all(6)
	menu.add_theme_stylebox_override("panel", popup_style)
	menu.add_theme_color_override("font_color", COR_TEXTO)
	menu.add_theme_color_override("font_hover_color", Color("8df1b2"))
	for acao in Market.acoes:
		trading_select.add_item("%s • %s" % [acao.ticker, acao.nome])
		if acao.ticker == ticker_ativo:
			trading_select.select(trading_select.item_count - 1)
	trading_select.item_selected.connect(_change_ticker)
	v.add_child(trading_select)
	compra_info = _label("", 18)
	v.add_child(compra_info)
	v.add_child(_label("QUANTIDADE DE AÇÕES", 16, COR_VERDE))
	quantidade_input = SpinBox.new()
	quantidade_input.min_value = 1
	quantidade_input.max_value = 100000
	quantidade_input.step = 1
	quantidade_input.value = 1
	quantidade_input.rounded = true
	quantidade_input.custom_minimum_size = Vector2(260, 45)
	quantidade_input.value_changed.connect(func(_n): _refresh_purchase_info())
	v.add_child(quantidade_input)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	v.add_child(buttons)
	buttons.add_child(_button("COMPRAR AÇÕES", _buy, true))
	buttons.add_child(_button("VENDER AÇÕES", _sell))
	v.add_child(_label("Preço médio e patrimônio são atualizados após cada negociação.", 14))
	v.add_child(_label("HISTÓRICO DE PREÇOS", 19, COR_VERDE))
	_add_chart(v, Market.buscar(ticker_ativo).historico)
	v.add_child(_label("A evolução começa com o preço inicial. Avance dias para visualizar oscilações.", 14))
	_refresh_purchase_info()

func _change_ticker(indice: int) -> void:
	ticker_ativo = Market.acoes[indice].ticker
	mostrar_pagina("INVESTIR")

func _refresh_purchase_info() -> void:
	if not is_instance_valid(compra_info) or not is_instance_valid(quantidade_input):
		return
	var acao := Market.buscar(ticker_ativo)
	if acao == null:
		return
	compra_info.text = "%s • %s\nCotação: %s  |  Você possui: %d ações\nValor da operação: %s  |  Saldo: %s" % [acao.nome, acao.setor, _moeda(acao.preco), int(GameState.carteira.get(ticker_ativo, 0)), _moeda(acao.preco * quantidade_input.value), _moeda(GameState.dinheiro)]

func _buy() -> void:
	if GameState.comprar(ticker_ativo, int(quantidade_input.value)):
		GameState.salvar()
		mostrar_pagina("INVESTIR")

func _sell() -> void:
	if GameState.vender(ticker_ativo, int(quantidade_input.value)):
		GameState.salvar()
		mostrar_pagina("INVESTIR")

func _page_carteira(v: VBoxContainer) -> void:
	v.add_child(_label("Patrimônio: %s  •  Disponível: %s  •  Investido: %s" % [_moeda(GameState.patrimonio()), _moeda(GameState.dinheiro), _moeda(GameState.valor_da_carteira())], 18, COR_VERDE))
	if GameState.carteira.is_empty():
		v.add_child(_label("Você ainda não tem ações. Acesse INVESTIR para montar sua carteira.", 17))
	else:
		for ticker in GameState.carteira:
			var qtd: int = int(GameState.carteira[ticker])
			var acao := Market.buscar(str(ticker))
			if acao == null:
				continue
			var custo: float = float(GameState.custos.get(ticker, 0.0))
			var valor: float = acao.preco * qtd
			var lucro: float = valor - custo
			v.add_child(_label("%s • %s (%s)\n%d ações  |  Preço médio: %s  |  Atual: %s\nPosição: %s  |  Resultado não realizado: %+.2f" % [ticker, acao.nome, acao.setor, qtd, _moeda(custo / maxi(1, qtd)), _moeda(acao.preco), _moeda(valor), lucro], 16))
			v.add_child(HSeparator.new())
	v.add_child(_label("OPERAÇÕES RECENTES", 21, COR_VERDE))
	if GameState.historico_operacoes.is_empty():
		v.add_child(_label("Nenhuma compra ou venda registrada.", 16))
	for op in GameState.historico_operacoes.slice(0, 20):
		v.add_child(_label("Dia %d • %s • %s • %d ações × %s" % [int(op["dia"]), op["tipo"], op["ticker"], int(op["quantidade"]), _moeda(float(op["preco"]))], 15))
	v.add_child(_label("EVOLUÇÃO DO PATRIMÔNIO", 19, COR_VERDE))
	_add_chart(v, GameState.historico_patrimonio)

func _page_cotacoes(v: VBoxContainer) -> void:
	v.add_child(_label("Preços gerados por simulação. Não representam cotações de mercado.", 16))
	for acao in Market.acoes:
		var anterior: float = acao.historico[acao.historico.size() - 2] if acao.historico.size() >= 2 else acao.preco
		var mudanca: float = (acao.preco / maxf(anterior, 0.01) - 1.0) * 100.0
		v.add_child(_label("%s • %s  |  %s  |  %+.2f%% no último dia" % [acao.ticker, acao.nome, _moeda(acao.preco), mudanca], 17))
		var b := _button("VER GRÁFICO / NEGOCIAR %s" % acao.ticker, _open_ticker.bind(acao.ticker))
		v.add_child(b)
		v.add_child(HSeparator.new())
	v.add_child(_label("Use AVANÇAR DIA na barra superior para observar os preços mudarem.", 15))

func _open_ticker(ticker: String) -> void:
	ticker_ativo = ticker
	mostrar_pagina("GRÁFICO")

func _page_grafico(v: VBoxContainer) -> void:
	var acao := Market.buscar(ticker_ativo)
	if acao == null:
		v.add_child(_label("Ação indisponível."))
		return
	v.add_child(_label("%s • %s  |  Cotação atual: %s" % [acao.ticker, acao.nome, _moeda(acao.preco)], 20, COR_VERDE))
	v.add_child(_label("HISTÓRICO DA COTAÇÃO (SIMULAÇÃO)", 17))
	_add_chart(v, acao.historico)
	v.add_child(_label("Dias registrados: %d. Avance um dia para ver novos preços." % maxi(0, acao.historico.size() - 1), 15))
	v.add_child(_button("NEGOCIAR %s" % ticker_ativo, func(): mostrar_pagina("INVESTIR"), true))

func _page_noticias(v: VBoxContainer) -> void:
	v.add_child(_label("Notícias simuladas: eventos influenciam preços conforme o setor da empresa.", 16))
	for noticia in Market.noticias:
		v.add_child(_label("📰 " + noticia, 17))
		v.add_child(HSeparator.new())
	v.add_child(_label("Lembre-se: o mercado real envolve riscos e fatores muito mais complexos.", 15))

func _page_missoes(v: VBoxContainer) -> void:
	v.add_child(_label("Conclua objetivos para ganhar XP, pontos e conquistas.", 17))
	for m in GameState.MISSOES:
		var concluida: bool = str(m["id"]) in GameState.missoes_concluidas
		v.add_child(_label("%s %s\n%s\nRecompensa: %d XP e %d pontos" % ["✅" if concluida else "◯", m["titulo"], m["texto"], m["xp"], m["pontos"]], 16, COR_VERDE if concluida else COR_TEXTO))
		v.add_child(HSeparator.new())

func _page_conquistas(v: VBoxContainer) -> void:
	v.add_child(_label("NÍVEL %d  •  %d XP  •  %d PONTOS" % [GameState.nivel, GameState.xp, GameState.pontos], 22, COR_VERDE))
	v.add_child(_label("Conquistas pessoais (sem ranking online ou outros jogadores fictícios).", 16))
	if GameState.conquistas.is_empty():
		v.add_child(_label("Nenhuma conquista obtida. Complete uma missão para começar!", 17))
	for titulo in GameState.conquistas:
		v.add_child(_label("🏆 " + titulo, 19))
	v.add_child(_label("RANKING PESSOAL • PROGRESSO", 20, COR_VERDE))
	v.add_child(_label("Missões: %d/%d  •  Operações: %d  •  Patrimônio: %s" % [GameState.missoes_concluidas.size(), GameState.MISSOES.size(), GameState.transacoes, _moeda(GameState.patrimonio())], 16))

func _page_loja(v: VBoxContainer) -> void:
	v.add_child(_label("LOJA DE RECOMPENSAS (FICTÍCIA)", 22, COR_VERDE))
	v.add_child(_label("Pontos disponíveis: %d" % GameState.pontos, 19))
	v.add_child(_label("Bônus de aprendizagem • 150 pontos\nReceba R$ 50 fictícios na carteira uma única vez.", 18))
	var b := _button("RESGATAR BÔNUS", _redeem_bonus, true)
	b.disabled = GameState.bonus_comprado or GameState.pontos < 150
	v.add_child(b)
	if GameState.bonus_comprado:
		v.add_child(_label("Bônus já resgatado nesta partida.", 16, COR_VERDE))

func _redeem_bonus() -> void:
	if GameState.comprar_bonus():
		GameState.salvar()
		mostrar_pagina("LOJA")

func _page_ajustes(v: VBoxContainer) -> void:
	v.add_child(_label("SALVAR / CARREGAR", 21, COR_VERDE))
	v.add_child(_button("SALVAR PARTIDA", func(): GameState.salvar(), true))
	v.add_child(_button("CARREGAR PARTIDA", _load))
	v.add_child(_button("VER TUTORIAL", func(): mostrar_pagina("TUTORIAL")))
	v.add_child(_label("REINICIAR JOGO", 21, Color("ffb4a7")))
	v.add_child(_label("Atenção: reiniciar apagará o progresso desta partida quando você salvar novamente.", 15))
	v.add_child(_button("COMEÇAR NOVA PARTIDA", _reset))
	v.add_child(_label("Todo o dinheiro, todas as operações e todas as notícias são fictícios.", 14))

func _load() -> void:
	if GameState.carregar():
		mostrar_pagina("AJUSTES")

func _reset() -> void:
	GameState.novo_jogo()
	mostrar_pagina("TUTORIAL")

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
	_fechar()

func _add_chart(v: VBoxContainer, valores: Array[float]) -> void:
	var grafico := Control.new()
	grafico.set_script(ChartScript)
	grafico.custom_minimum_size = Vector2(800, 205)
	grafico.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(grafico)
	grafico.call("definir_valores", valores)
