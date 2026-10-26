extends Node
## Autoload "GameState": dinheiro, carteira, XP, recursos e missões do jogador.

signal dinheiro_mudou(novo_valor: float)
signal xp_mudou
signal moedas_mudou
signal gemas_mudou
signal missao_mudou

const DINHEIRO_INICIAL := 1000.0

## Missões em sequência. "tipo" define como o progresso é contado.
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
		"titulo": "Diversifique",
		"descricao": "Tenha ações de 3 setores diferentes.",
		"tipo": "setores",
		"meta": 3,
		"moedas": 200,
		"xp": 200,
	},
]

var dinheiro: float = DINHEIRO_INICIAL

## ticker -> quantidade de ações
var carteira: Dictionary = {}

var nivel: int = 1
var xp: int = 0
var moedas: int = 0
var gemas: int = 0
var missao_indice: int = 0


# --- Ações -----------------------------------------------------------

func comprar(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0:
		return false
	var custo := acao.preco * quantidade
	if custo > dinheiro:
		return false
	dinheiro -= custo
	carteira[ticker] = carteira.get(ticker, 0) + quantidade
	_verificar_missao()
	dinheiro_mudou.emit(dinheiro)
	return true


func vender(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0:
		return false
	if carteira.get(ticker, 0) < quantidade:
		return false
	carteira[ticker] -= quantidade
	dinheiro += acao.preco * quantidade
	dinheiro_mudou.emit(dinheiro)
	return true


func valor_da_carteira() -> float:
	var total := 0.0
	for ticker in carteira:
		total += Market.buscar(ticker).preco * carteira[ticker]
	return total


func patrimonio() -> float:
	return dinheiro + valor_da_carteira()


func rentabilidade() -> float:
	# Em %, em relação ao dinheiro inicial.
	return (patrimonio() / DINHEIRO_INICIAL - 1.0) * 100.0


# --- XP e nível ------------------------------------------------------

func xp_para_proximo_nivel() -> int:
	return nivel * 250


func ganhar_xp(quantidade: int) -> void:
	xp += quantidade
	while xp >= xp_para_proximo_nivel():
		xp -= xp_para_proximo_nivel()
		nivel += 1
	xp_mudou.emit()


# --- Moedas e gemas --------------------------------------------------

func ganhar_moedas(quantidade: int) -> void:
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


# --- Missões ---------------------------------------------------------

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
				var qtd: int = carteira[ticker]
				total += qtd
			return total
		"setores":
			var setores: Array[String] = []
			for ticker in carteira:
				var qtd: int = carteira[ticker]
				if qtd > 0:
					var setor: String = Market.buscar(ticker).setor
					if not setores.has(setor):
						setores.append(setor)
			return setores.size()
	return 0


func _verificar_missao() -> void:
	var m: Dictionary = missao_atual()
	if m.is_empty():
		return
	if progresso_missao() >= int(m["meta"]):
		missao_indice += 1
		ganhar_moedas(int(m["moedas"]))
		ganhar_xp(int(m["xp"]))
		missao_mudou.emit()
