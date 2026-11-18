extends Node

signal dia_avancou(dia: int)
signal noticias_mudou

const CHANCE_NOTICIA := 0.35
const MAX_NOTICIAS := 20
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
var noticias: Array[Dictionary] = []

# Noticia reservada para o proximo dia
var proxima_noticia: Dictionary = {}



func _ready() -> void:
	_adicionar("PETR4", "Petrolinho Energia", "Energia", 38.0, 0.025)
	_adicionar("VALE3", "MontVale Mineração", "Mineração", 62.0, 0.020)
	_adicionar("ITUB4", "Banco Aurora", "Bancos", 33.0, 0.015)
	_adicionar("BBDC4", "Banco Horizonte", "Bancos", 14.0, 0.018)



func _adicionar(
	ticker: String,
	nome: String,
	setor: String,
	preco: float,
	vol: float
) -> void:
	var s := Stock.new()

	s.ticker = ticker
	s.nome = nome
	s.setor = setor
	s.preco = preco
	s.volatilidade = vol

	acoes.append(s)


func avancar_dia() -> void:
	dia += 1

	var choques: Dictionary = {}

	if not proxima_noticia.is_empty():
		choques = _aplicar_noticia(proxima_noticia)
		proxima_noticia.clear()
	else:
		choques = _sortear_noticia()

	for a in acoes:
		a.avancar_dia(
			choques.get(a.ticker, 0.0)
		)

	dia_avancou.emit(dia)

	if not choques.is_empty():
		noticias_mudou.emit()


func _sortear_noticia() -> Dictionary:
	var choques := {}

	if randf() > CHANCE_NOTICIA:
		return choques

	var noticia := _gerar_noticia()
	return _aplicar_noticia(noticia)


func _gerar_noticia() -> Dictionary:
	var acao: Stock = acoes.pick_random()
	var positiva := randf() < 0.5

	var modelo: String = (
		MODELOS_BOAS if positiva else MODELOS_RUINS
	).pick_random()

	return {
		"texto": modelo % acao.nome,
		"ticker": acao.ticker,
		"positiva": positiva
	}


func _aplicar_noticia(noticia: Dictionary) -> Dictionary:
	var impacto: float = (
		IMPACTO_NOTICIA
		if noticia["positiva"]
		else -IMPACTO_NOTICIA
	)

	noticias.push_front({
		"dia": dia,
		"texto": noticia["texto"],
		"ticker": noticia["ticker"],
		"positiva": noticia["positiva"]
	})

	if noticias.size() > MAX_NOTICIAS:
		noticias.pop_back()

	return {noticia["ticker"]: impacto}


func consultar_dica() -> String:
	if not GameState.dica_mercado_disponivel:
		return "Voce nao possui uma dica disponivel."

	if proxima_noticia.is_empty():
		proxima_noticia = _gerar_noticia()

	GameState.dica_mercado_disponivel = false

	return (
		"PREVISAO DO DIA %d:\n%s\nEmpresa: %s"
		% [
			dia + 1,
			proxima_noticia["texto"],
			proxima_noticia["ticker"]
		]
	)


func buscar(ticker: String) -> Stock:
	for a in acoes:
		if a.ticker == ticker:
			return a

	return null


func variacao_diaria(ticker: String) -> float:
	var acao: Stock = buscar(ticker)

	if acao == null:
		return 0.0

	var quantidade_registros := acao.historico.size()

	if quantidade_registros >= 2:
		var anterior: float = acao.historico[
			quantidade_registros - 2
		]

		var atual: float = acao.historico[
			quantidade_registros - 1
		]

		if anterior > 0.0:
			return (atual / anterior - 1.0) * 100.0

	return 0.0


func carteira_tem_acao_positiva() -> bool:
	for ticker in GameState.carteira:
		var quantidade: int = int(
			GameState.carteira[ticker]
		)

		if quantidade <= 0:
			continue

		if variacao_diaria(str(ticker)) > 0.0:
			return true

	return false
