





extends Node

signal dinheiro_mudou(novo_valor: float)
signal xp_mudou
signal moedas_mudou
signal gemas_mudou
signal missao_mudou
signal loja_mudou

signal operacao_realizada(
	tipo: String,
	ticker: String,
	quantidade: int,
	preco: float,
	lucro_pct: float
)

const DINHEIRO_INICIAL := 1000.0
# Meta acumulada para concluir o nivel 2.
const META_XP_NIVEL_2 := 900

const MISSOES: Array = [
	{
		"titulo": "Primeira compra",
		"descricao": "Compre ações de qualquer empresa.",
		"tipo": "acoes",
		"meta": 1,
		"moedas": 50,
		"xp": 100,
	},
	{
		"titulo": "Patrimônio de R$ 2.000",
		"descricao": "Alcance R$ 2.000 de patrimônio no jogo.",
		"tipo": "patrimonio",
		"meta": 2000,
		"moedas": 100,
		"xp": 100,
	},
	{
		"titulo": "Diversifique",
		"descricao": "Tenha ações de 3 setores diferentes.",
		"tipo": "setores",
		"meta": 3,
		"moedas": 200,
		"xp": 200,
	},
]

var dinheiro: float = DINHEIRO_INICIAL
var carteira: Dictionary = {}
var custo_total: Dictionary = {}

var nivel: int = 1
var xp: int = 0
var moedas: int = 0
var gemas: int = 0
var missao_indice: int = 0

# A fase e o nivel representam a mesma coisa.
# Mantemos fase_jogo por compatibilidade com os outros scripts.
var fase_jogo: int = 1:
	set(valor):
		if valor == fase_jogo:
			return
		var nivel_anterior: int = fase_jogo
		fase_jogo = valor
		nivel = valor
		if valor > nivel_anterior:
			xp = 0
		xp_mudou.emit()
var venda_nivel_2_realizada: bool = false
var nivel_2_concluido: bool = false

# SISTEMA DA LOJA
var itens_comprados: Dictionary = {}
var total_moedas_gastas: int = 0
var historico_compras: Array[Dictionary] = []

var boost_xp_ate_dia: int = -1
var dica_mercado_disponivel: bool = false


# ==================================================
# ACOES
# ==================================================

func comprar(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)

	if acao == null or quantidade <= 0:
		return false

	var custo := acao.preco * quantidade

	if custo > dinheiro:
		return false

	dinheiro -= custo

	carteira[ticker] = (
		carteira.get(ticker, 0) + quantidade
	)

	custo_total[ticker] = (
		custo_total.get(ticker, 0.0) + custo
	)

	_verificar_missao()
	dinheiro_mudou.emit(dinheiro)

	operacao_realizada.emit(
		"compra",
		ticker,
		quantidade,
		acao.preco,
		0.0
	)

	return true


func vender(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)

	if acao == null or quantidade <= 0:
		return false

	if carteira.get(ticker, 0) < quantidade:
		return false

	var qtd_antes: int = carteira[ticker]
	var custo_atual: float = custo_total.get(ticker, 0.0)
	var custo_medio: float = custo_atual / qtd_antes
	var lucro_pct := 0.0

	if custo_medio > 0.0:
		lucro_pct = (
			acao.preco / custo_medio - 1.0
		) * 100.0

	custo_total[ticker] = (
		custo_atual
		- custo_atual * quantidade / qtd_antes
	)

	carteira[ticker] -= quantidade

	if carteira[ticker] == 0:
		custo_total.erase(ticker)

	dinheiro += acao.preco * quantidade

	if fase_jogo == 2 and Market.dia >= 16:
		venda_nivel_2_realizada = true

	dinheiro_mudou.emit(dinheiro)

	operacao_realizada.emit(
		"venda",
		ticker,
		quantidade,
		acao.preco,
		lucro_pct
	)

	return true


func valor_da_carteira() -> float:
	var total := 0.0

	for ticker in carteira:
		var acao: Stock = Market.buscar(str(ticker))

		if acao != null:
			total += acao.preco * int(carteira[ticker])

	return total


func custo_da_posicao(ticker: String) -> float:
	return custo_total.get(ticker, 0.0)


func lucro_da_posicao(ticker: String) -> float:
	var acao: Stock = Market.buscar(ticker)
	var qtd: int = carteira.get(ticker, 0)

	if acao == null:
		return 0.0

	return (
		acao.preco * qtd
		- custo_da_posicao(ticker)
	)


func patrimonio() -> float:
	return dinheiro + valor_da_carteira()


func rentabilidade() -> float:
	return (
		patrimonio() / DINHEIRO_INICIAL - 1.0
	) * 100.0


# ==================================================
# XP E NIVEL
# ==================================================

func xp_para_proximo_nivel() -> int:
	# A barra do nivel 2 mostra a meta, nao sobe de nivel sozinha.
	return META_XP_NIVEL_2


func xp_faltante_nivel_2() -> int:
	return maxi(0, META_XP_NIVEL_2 - xp)


func todas_missoes_concluidas() -> bool:
	return missao_indice >= MISSOES.size()


func boost_xp_ativo() -> bool:
	return boost_xp_ate_dia >= 0


func ganhar_xp(quantidade: int) -> void:
	if quantidade <= 0:
		return

	var recebido := quantidade

	if boost_xp_ativo():
		recebido *= 2
		# O bônus vale para a próxima recompensa de XP,
		# mesmo que o jogador avance o dia antes de recebê-la.
		boost_xp_ate_dia = -1
		itens_comprados.erase("boost_xp")
		loja_mudou.emit()

	xp += recebido

	# XP acumulado nunca e consumido. O nivel muda apenas
	# quando os objetivos da historia sao cumpridos.
	xp_mudou.emit()


# ==================================================
# MOEDAS E GEMAS
# ==================================================

func ganhar_moedas(quantidade: int) -> void:
	if quantidade <= 0:
		return

	moedas += quantidade
	moedas_mudou.emit()


func gastar_moedas(quantidade: int) -> bool:
	if quantidade <= 0 or quantidade > moedas:
		return false

	moedas -= quantidade
	moedas_mudou.emit()

	return true


func ganhar_gemas(quantidade: int) -> void:
	gemas += quantidade
	gemas_mudou.emit()


# ==================================================
# LOJA
# ==================================================

func comprar_item_loja(item: Dictionary) -> bool:
	var id: String = str(item["id"])
	var preco: int = int(item["preco"])

	if itens_comprados.has(id):
		return false

	if preco <= 0 or moedas < preco:
		return false

	# Somente os beneficios implementados
	if id != "boost_xp" and id != "dica":
		return false

	if not gastar_moedas(preco):
		return false

	itens_comprados[id] = true
	total_moedas_gastas += preco

	historico_compras.append({
		"nome": str(item["nome"]),
		"preco": preco,
		"dia": Market.dia
	})

	match id:
		"boost_xp":
			boost_xp_ate_dia = Market.dia

		"dica":
			dica_mercado_disponivel = true

	loja_mudou.emit()
	return true


# ==================================================
# MISSOES ORIGINAIS
# ==================================================

func missao_atual() -> Dictionary:
	if missao_indice >= MISSOES.size():
		return {}

	return MISSOES[missao_indice]


func progresso_missao() -> int:
	var m: Dictionary = missao_atual()

	if m.is_empty():
		return 0

	match m["tipo"]:
		"acoes":
			var total := 0

			for ticker in carteira:
				total += int(carteira[ticker])

			return total

		"patrimonio":
			return int(patrimonio())

		"setores":
			var setores: Array[String] = []

			for ticker in carteira:
				var qtd: int = carteira[ticker]

				if qtd > 0:
					var acao: Stock = Market.buscar(str(ticker))

					if acao != null:
						if not setores.has(acao.setor):
							setores.append(acao.setor)

			return setores.size()

	return 0


func receber_bonus_tutorial(valor: float) -> void:
	if valor <= 0.0:
		return

	dinheiro += valor
	_verificar_missao()
	dinheiro_mudou.emit(dinheiro)


func _verificar_missao() -> void:
	var m: Dictionary = missao_atual()

	if m.is_empty():
		return

	if progresso_missao() >= int(m["meta"]):
		missao_indice += 1

		ganhar_moedas(int(m["moedas"]))
		ganhar_xp(int(m["xp"]))

		missao_mudou.emit()
