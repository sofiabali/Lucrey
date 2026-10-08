extends Node
## Autoload "Market": mantém as ações e avança o tempo do jogo.

signal dia_avancou(dia: int)

var dia: int = 0
var acoes: Array[Stock] = []


func _ready() -> void:
	# Valores fictícios, só para testar a simulação.
	_adicionar("PETR4", "Petrobras", "Energia", 38.0, 0.025)
	_adicionar("VALE3", "Vale", "Mineração", 62.0, 0.020)
	_adicionar("ITUB4", "Itaú", "Bancos", 33.0, 0.015)
	_adicionar("BBDC4", "Bradesco", "Bancos", 14.0, 0.018)


func _adicionar(ticker: String, nome: String, setor: String, preco: float, vol: float) -> void:
	var s := Stock.new()
	s.ticker = ticker
	s.nome = nome
	s.setor = setor
	s.preco = preco
	s.volatilidade = vol
	acoes.append(s)


func avancar_dia() -> void:
	dia += 1
	for a in acoes:
		a.avancar_dia()
	dia_avancou.emit(dia)


func buscar(ticker: String) -> Stock:
	for a in acoes:
		if a.ticker == ticker:
			return a
	return null
