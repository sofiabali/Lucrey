extends Node
## Autoload "Conquistas": controla progresso, desbloqueio, recompensa de XP,
## salvamento em arquivo e o aviso que aparece na tela.
##
## IMPORTANTE: na lista de Autoload, este script precisa ficar DEPOIS de
## GameState e Market, porque ele se conecta aos sinais deles no _ready.

signal conquista_desbloqueada(id: String, dados: Dictionary)

const CAMINHO_SAVE := "user://conquistas.json"

## "meta" é o valor que o progresso precisa atingir. "xp" é a recompensa.
## A ordem aqui é a ordem em que aparecem na tela de conquistas.
const DEFINICOES := {
	"primeira_compra": {"nome": "Primeiro passo", "desc": "Faça sua primeira compra de ações.", "meta": 1, "xp": 50},
	"diversificado": {"nome": "Diversificado", "desc": "Tenha ações de 3 setores diferentes.", "meta": 3, "xp": 150},
	"investidor": {"nome": "Investidor", "desc": "Chegue a R$ 2000 de patrimônio.", "meta": 2000, "xp": 300},
	"paciencia": {"nome": "Paciência", "desc": "Avance 30 dias.", "meta": 30, "xp": 150},
	"primeira_venda": {"nome": "Saindo da posição", "desc": "Venda uma ação pela primeira vez.", "meta": 1, "xp": 50},
	"venda_lucro": {"nome": "Lucro no bolso", "desc": "Venda uma ação por mais do que pagou.", "meta": 1, "xp": 100},
	"grande_lucro": {"nome": "Tacada certeira", "desc": "Lucre 20% ou mais em uma única venda.", "meta": 1, "xp": 200},
	"aprendendo_com_erro": {"nome": "Faz parte do jogo", "desc": "Venda uma ação com prejuízo. Perder também ensina.", "meta": 1, "xp": 75},
	"trader_ativo": {"nome": "Trader ativo", "desc": "Faça 10 operações (compras ou vendas).", "meta": 10, "xp": 150},
	"trader_veterano": {"nome": "Trader veterano", "desc": "Faça 50 operações (compras ou vendas).", "meta": 50, "xp": 400},
	"rentab_10": {"nome": "No azul", "desc": "Alcance +10% de rentabilidade.", "meta": 10, "xp": 100},
	"rentab_50": {"nome": "Investidor sério", "desc": "Alcance +50% de rentabilidade.", "meta": 50, "xp": 300},
}

## id -> valor atual do progresso
var progresso: Dictionary = {}
## id -> true
var desbloqueadas: Dictionary = {}

# --- aviso na tela (criado por código, não precisa mexer em cena) ---
var _fila: Array = []
var _mostrando := false
var _painel: PanelContainer
var _label_titulo: Label
var _label_descricao: Label


func _ready() -> void:
	_carregar()
	_criar_aviso()
	GameState.operacao_realizada.connect(_on_operacao_realizada)
	Market.dia_avancou.connect(_on_dia_avancou)


# ---------------------------------------------------------------------------
# Eventos do jogo
# ---------------------------------------------------------------------------

func _on_operacao_realizada(tipo: String, _ticker: String, _quantidade: int, _preco: float, lucro_pct: float) -> void:
	_somar("trader_ativo")
	_somar("trader_veterano")

	if tipo == "compra":
		_somar("primeira_compra")
		_checar_diversificacao()
	elif tipo == "venda":
		_somar("primeira_venda")
		if lucro_pct > 0.0:
			_somar("venda_lucro")
		if lucro_pct >= 20.0:
			_somar("grande_lucro")
		if lucro_pct < 0.0:
			_somar("aprendendo_com_erro")


func _on_dia_avancou(dia: int) -> void:
	_definir("paciencia", dia)
	_definir("investidor", GameState.patrimonio())
	var rent := GameState.rentabilidade()
	_definir("rentab_10", rent)
	_definir("rentab_50", rent)


func _checar_diversificacao() -> void:
	var setores := {}
	for ticker in GameState.carteira:
		if GameState.carteira[ticker] > 0:
			var acao: Stock = Market.buscar(ticker)
			if acao != null:
				setores[acao.setor] = true
	_definir("diversificado", setores.size())


# ---------------------------------------------------------------------------
# Progresso
# ---------------------------------------------------------------------------

## Soma ao progresso (ex.: +1 operação).
func _somar(id: String, quantidade: float = 1.0) -> void:
	if desbloqueadas.has(id) or not DEFINICOES.has(id):
		return
	progresso[id] = progresso.get(id, 0.0) + quantidade
	_verificar(id)


## Define o progresso como um valor absoluto, guardando sempre o maior já visto
## (ex.: patrimônio atual, dia atual).
func _definir(id: String, valor: float) -> void:
	if desbloqueadas.has(id) or not DEFINICOES.has(id):
		return
	progresso[id] = maxf(progresso.get(id, 0.0), valor)
	_verificar(id)


func _verificar(id: String) -> void:
	var dados: Dictionary = DEFINICOES[id]
	if progresso[id] >= dados["meta"]:
		desbloqueadas[id] = true
		_salvar()
		GameState.ganhar_xp(dados["xp"])
		conquista_desbloqueada.emit(id, dados)
		_enfileirar_aviso(dados)
	else:
		_salvar()


## Usada pela tela de conquistas: devolve tudo pronto para listar.
## "atual" e "meta" já vêm como números inteiros, e "atual" nunca passa da meta.
func obter_lista() -> Array:
	var lista: Array = []
	for id in DEFINICOES:
		var dados: Dictionary = DEFINICOES[id]
		var meta: int = int(dados["meta"])
		var atual: int = meta if desbloqueadas.has(id) else mini(int(progresso.get(id, 0.0)), meta)
		lista.append({
			"id": id,
			"nome": dados["nome"],
			"desc": dados["desc"],
			"xp": dados["xp"],
			"atual": atual,
			"meta": meta,
		})
	return lista


## Apaga o progresso (útil para testar).
func resetar() -> void:
	progresso.clear()
	desbloqueadas.clear()
	_salvar()


# ---------------------------------------------------------------------------
# Salvar / carregar
# ---------------------------------------------------------------------------

func _salvar() -> void:
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Conquistas: não foi possível salvar em %s" % CAMINHO_SAVE)
		return
	arquivo.store_string(JSON.stringify({
		"progresso": progresso,
		"desbloqueadas": desbloqueadas,
	}))


func _carregar() -> void:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return
	var dados = JSON.parse_string(arquivo.get_as_text())
	if dados is Dictionary:
		progresso = dados.get("progresso", {})
		desbloqueadas = dados.get("desbloqueadas", {})


# ---------------------------------------------------------------------------
# Aviso na tela
# ---------------------------------------------------------------------------

func _criar_aviso() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100  # fica por cima do HUD
	add_child(camada)

	# Coluna que ocupa a tela toda e empurra o aviso para baixo, centralizado.
	var coluna := VBoxContainer.new()
	coluna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coluna.alignment = BoxContainer.ALIGNMENT_END
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(coluna)

	_painel = PanelContainer.new()
	_painel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.modulate.a = 0.0
	coluna.add_child(_painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 16)
	margem.add_theme_constant_override("margin_right", 16)
	margem.add_theme_constant_override("margin_top", 10)
	margem.add_theme_constant_override("margin_bottom", 10)
	_painel.add_child(margem)

	var textos := VBoxContainer.new()
	margem.add_child(textos)

	var topo := Label.new()
	topo.text = "CONQUISTA DESBLOQUEADA"
	topo.add_theme_font_size_override("font_size", 12)
	topo.add_theme_color_override("font_color", Color("#F1C40F"))
	topo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	textos.add_child(topo)

	_label_titulo = Label.new()
	_label_titulo.add_theme_font_size_override("font_size", 20)
	_label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	textos.add_child(_label_titulo)

	_label_descricao = Label.new()
	_label_descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	textos.add_child(_label_descricao)

	# Espaço entre o aviso e a borda de baixo da tela.
	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 100)
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(espaco)


func _enfileirar_aviso(dados: Dictionary) -> void:
	_fila.append(dados)
	if not _mostrando:
		_mostrar_proximo_aviso()


func _mostrar_proximo_aviso() -> void:
	if _fila.is_empty():
		_mostrando = false
		return
	_mostrando = true
	var dados: Dictionary = _fila.pop_front()
	_label_titulo.text = dados["nome"]
	_label_descricao.text = "%s  (+%d XP)" % [dados["desc"], dados["xp"]]

	var tween := create_tween()
	tween.tween_property(_painel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(_painel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_mostrar_proximo_aviso)
