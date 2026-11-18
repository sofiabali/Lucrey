extends Node
## Mercado fictício: preços, histórico, dias e notícias/eventos de simulação.
signal dia_avancou(dia: int)
signal noticia_publicada(mensagem: String)

var dia: int = 0
var acoes: Array[Stock] = []
var ultima_noticia: String = "Bem-vindo ao LUCREY! O mercado está aberto."
var noticias: Array[String] = []
var ultimo_evento: Dictionary = {}

const EVENTOS: Array[Dictionary] = [
	{"texto": "Setor de energia recebe novos investimentos.", "setor": "Energia", "choque": 0.035},
	{"texto": "Queda de demanda pressiona mineradoras.", "setor": "Mineração", "choque": -0.04},
	{"texto": "Bancos divulgam resultados acima das expectativas.", "setor": "Bancos", "choque": 0.025},
	{"texto": "Incerteza econômica afeta o setor bancário.", "setor": "Bancos", "choque": -0.03},
	{"texto": "Mercado acompanha indicadores econômicos.", "setor": "Todos", "choque": 0.0},
	{"texto": "Empresas de energia anunciam novas operações.", "setor": "Energia", "choque": 0.025},
	{"texto": "Alta de custos preocupa o mercado financeiro.", "setor": "Todos", "choque": -0.015}
]

func _ready() -> void:
	criar_mercado()

func criar_mercado() -> void:
	ultima_noticia = "Bem-vindo ao LUCREY! O mercado está aberto."
	acoes.clear()
	dia = 0
	_adicionar("PETR4", "Petrobras", "Energia", 38.0, 0.025)
	_adicionar("VALE3", "Vale", "Mineração", 62.0, 0.020)
	_adicionar("ITUB4", "Itaú", "Bancos", 33.0, 0.015)
	_adicionar("BBDC4", "Bradesco", "Bancos", 14.0, 0.018)
	noticias = ["Dia 0: " + ultima_noticia]
	ultimo_evento = {}

func _adicionar(ticker: String, nome: String, setor: String, preco: float, vol: float) -> void:
	var s := Stock.new()
	s.ticker = ticker
	s.nome = nome
	s.setor = setor
	s.preco = preco
	s.volatilidade = vol
	s.historico = [preco]
	acoes.append(s)

func avancar_dia() -> void:
	dia += 1
	var evento: Dictionary = EVENTOS.pick_random()
	ultimo_evento = evento.duplicate()
	ultima_noticia = str(evento["texto"])
	for acao in acoes:
		var choque: float = float(evento["choque"]) if evento["setor"] == "Todos" or evento["setor"] == acao.setor else 0.0
		acao.avancar_dia(choque)
	noticias.push_front("Dia %d: %s" % [dia, ultima_noticia])
	if noticias.size() > 30:
		noticias.resize(30)
	noticia_publicada.emit(ultima_noticia)
	dia_avancou.emit(dia)

func buscar(ticker: String) -> Stock:
	for acao in acoes:
		if acao.ticker == ticker:
			return acao
	return null

func exportar() -> Dictionary:
	var dados: Array[Dictionary] = []
	for acao in acoes:
		dados.append({"ticker": acao.ticker, "preco": acao.preco, "historico": acao.historico.duplicate()})
	return {"dia": dia, "acoes": dados, "noticias": noticias.duplicate(), "ultima_noticia": ultima_noticia}

func importar(dados: Dictionary) -> void:
	criar_mercado()
	dia = maxi(0, int(dados.get("dia", 0)))
	for entrada in dados.get("acoes", []):
		if not (entrada is Dictionary):
			continue
		var acao := buscar(str(entrada.get("ticker", "")))
		if acao == null:
			continue
		acao.preco = maxf(0.01, float(entrada.get("preco", acao.preco)))
		acao.historico.clear()
		for valor in entrada.get("historico", []):
			acao.historico.append(maxf(0.01, float(valor)))
		if acao.historico.is_empty():
			acao.historico.append(acao.preco)
	ultima_noticia = str(dados.get("ultima_noticia", ultima_noticia))
	noticias.clear()
	for noticia in dados.get("noticias", []):
		noticias.append(str(noticia))
	dia_avancou.emit(dia)
