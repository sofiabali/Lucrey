extends Node
## Autoload "Market": mantém as ações, o relógio do jogo e as notícias.

signal dia_avancou(dia: int)
signal noticias_mudou

## Chance de sair uma notícia a cada dia (0.0 desliga as notícias).
const CHANCE_NOTICIA := 0.35
const MAX_NOTICIAS := 20
## Quanto a notícia mexe no preço do dia (0.05 = 5%).
const IMPACTO_NOTICIA := 0.05

const MODELOS_BOAS := [
	"%s anuncia lucro acima do esperado",
	"%s fecha contrato importante",
	"%s eleva a previsão de resultados",
]
const MODELOS_RUINS := [
	"%s tem queda nas vendas",
	"%s enfrenta problemas na produção",
	"%s corta a previsão de resultados",
]

var dia: int = 0
var acoes: Array[Stock] = []
## Mais recente primeiro: {"dia", "texto", "ticker", "positiva"}
var noticias: Array[Dictionary] = []


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
	var choques: Dictionary = _sortear_noticia()
	for a in acoes:
		a.avancar_dia(choques.get(a.ticker, 0.0))
	dia_avancou.emit(dia)
	if not choques.is_empty():
		noticias_mudou.emit()


## Talvez publique uma notícia. Devolve ticker -> choque de preço do dia.
func _sortear_noticia() -> Dictionary:
	var choques := {}
	if randf() > CHANCE_NOTICIA:
		return choques
	var acao: Stock = acoes.pick_random()
	var positiva := randf() < 0.5
	var modelo: String = (MODELOS_BOAS if positiva else MODELOS_RUINS).pick_random()
	choques[acao.ticker] = IMPACTO_NOTICIA if positiva else -IMPACTO_NOTICIA
	noticias.push_front({
		"dia": dia,
		"texto": modelo % acao.nome,
		"ticker": acao.ticker,
		"positiva": positiva,
	})
	if noticias.size() > MAX_NOTICIAS:
		noticias.pop_back()
	return choques


func buscar(ticker: String) -> Stock:
	for a in acoes:
		if a.ticker == ticker:
			return a
	return null
