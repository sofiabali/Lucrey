extends Node
## Autoload "GameState": dinheiro e carteira do jogador.

signal dinheiro_mudou(novo_valor: float)

const DINHEIRO_INICIAL := 1000.0

var dinheiro: float = DINHEIRO_INICIAL

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
	# Em %, em relação ao dinheiro inicial (o "+24,35%" do seu protótipo).
	return (patrimonio() / DINHEIRO_INICIAL - 1.0) * 100.0

signal xp_mudou

var nivel: int = 1
var xp: int = 0


func xp_para_proximo_nivel() -> int:
	return nivel * 250

func ganhar_xp(quantidade: int) -> void:
	xp += quantidade
	
	while xp >= xp_para_proximo_nivel():
		xp -= xp_para_proximo_nivel()
		nivel += 1
		
	xp_mudou.emit()	
	pass

signal moedas_mudou
signal gemas_mudou

var moedas: int = 0
var gemas: int = 0

func ganhar_moedas(quantidade: int) -> void:
	moedas += quantidade
	moedas_mudou.emit()
	
func gastar_moedas(quantidade: int) -> bool:
	var acao: Stock
	if acao == null or quantidade <= 0:
		return false
	var custo := acao.preco * quantidade
	if custo > moedas:
		return false
	moedas -= custo
	moedas_mudou.emit()
	return true
	
func ganhar_gemas(quantidade: int) -> void:
	gemas += quantidade
	gemas_mudou.emit()
	
func gastar_gemas(quantidade: int) -> bool:
	var acao: Stock
	if acao == null or quantidade <= 0:
		return false
	var custo := acao.preco * quantidade
	if custo > gemas:
		return false
	gemas -= custo
	gemas_mudou.emit()
	return true
