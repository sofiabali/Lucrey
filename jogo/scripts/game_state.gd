extends Node2D
## Autoload "GameState": dinheiro e carteira do jogador.

signal dinheiro_mudou(novo_valor: float)

const DINHEIRO_INICIAL := 1000.0

var dinheiro: float = DINHEIRO_INICIAL:
	set(valor):
		dinheiro = valor
		dinheiro_mudou.emit(dinheiro)

## ticker -> quantidade de ações
var carteira: Dictionary = {}


func comprar(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0:
		return false
	var custo := acao.preco * quantidade
	if custo > dinheiro:
		return false
	dinheiro -= custo
	carteira[ticker] = carteira.get(ticker, 0) + quantidade
	return true


func vender(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0:
		return false
	if carteira.get(ticker, 0) < quantidade:
		return false
	carteira[ticker] -= quantidade
	dinheiro += acao.preco * quantidade
	return true


func valor_da_carteira() -> float:
	var total := 0.0
	for ticker in carteira:
		total += Market.buscar(ticker).preco * carteira[ticker]
	return total


func patrimonio() -> float:
	return dinheiro + valor_da_carteira()


func rentabilidade() -> float:
	# Em %, em relação ao dinheiro inicial (o "+24,35%" do seu protótipo).
	return (patrimonio() / DINHEIRO_INICIAL - 1.0) * 100.0
