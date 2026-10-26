extends PanelContainer
## Painel "Minha Carteira": rosca com a divisão do patrimônio + legenda.

const CORES := [
	Color("#3B82F6"), Color("#22C55E"), Color("#F97316"),
	Color("#EAB308"), Color("#14B8A6"), Color("#A855F7"),
]
const COR_CAIXA := Color("#64748B")

@onready var grafico: GraficoPizza = %Grafico
@onready var label_total: Label = %LabelTotal
@onready var legenda: VBoxContainer = %Legenda
@onready var botao_ver: Button = %BotaoVerCarteira


func _ready() -> void:
	# Estes dois sinais carregam um valor que não nos interessa,
	# então usamos uma função anônima (lambda) que o descarta.
	GameState.dinheiro_mudou.connect(func(_v: float) -> void: _atualizar())
	Market.dia_avancou.connect(func(_d: int) -> void: _atualizar())
	botao_ver.pressed.connect(func() -> void: print("Ver carteira"))
	_atualizar()


func _atualizar() -> void:
	for filho in legenda.get_children():
		filho.queue_free()

	var itens: Array = []
	var i := 0
	for ticker in GameState.carteira:
		var qtd: int = GameState.carteira[ticker]
		if qtd <= 0:
			continue
		var acao: Stock = Market.buscar(ticker)
		itens.append({"nome": ticker, "valor": acao.preco * qtd, "cor": CORES[i % CORES.size()]})
		i += 1
	if GameState.dinheiro > 0.0:
		itens.append({"nome": "CAIXA", "valor": GameState.dinheiro, "cor": COR_CAIXA})

	var total: float = GameState.patrimonio()
	label_total.text = "TOTAL\nR$ %.2f" % total

	var fatias: Array = []
	for item in itens:
		fatias.append({"valor": item["valor"], "cor": item["cor"]})
		var pct: float = 0.0
		if total > 0.0:
			pct = float(item["valor"]) / total * 100.0
		_criar_linha(item["nome"], pct, item["cor"])
	grafico.definir_fatias(fatias)


func _criar_linha(nome: String, pct: float, cor: Color) -> void:
	var linha := HBoxContainer.new()

	var quadrado := ColorRect.new()
	quadrado.color = cor
	quadrado.custom_minimum_size = Vector2(12, 12)
	quadrado.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var l_nome := Label.new()
	l_nome.text = nome
	l_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var l_pct := Label.new()
	l_pct.text = "%.1f%%" % pct

	linha.add_child(quadrado)
	linha.add_child(l_nome)
	linha.add_child(l_pct)
	legenda.add_child(linha)
