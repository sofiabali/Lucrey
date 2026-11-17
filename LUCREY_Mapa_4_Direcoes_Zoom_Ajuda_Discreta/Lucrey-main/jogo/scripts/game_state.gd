extends Node
## Estado do jogador, regras de negociação, missões e persistência local.
signal dinheiro_mudou(novo_valor: float)
signal xp_mudou
signal estado_mudou
signal mensagem(texto: String)

const DINHEIRO_INICIAL: float = 1000.0
const SAVE_PATH: String = "user://lucrey_save.json"

var dinheiro: float = DINHEIRO_INICIAL
var carteira: Dictionary = {} # ticker -> quantidade
var custos: Dictionary = {} # ticker -> custo acumulado da posição
var historico_operacoes: Array[Dictionary] = []
var historico_patrimonio: Array[float] = [DINHEIRO_INICIAL]
var nivel: int = 1
var xp: int = 0
var pontos: int = 0
var conquistas: Array[String] = []
var missoes_concluidas: Array[String] = []
var bonus_comprado: bool = false
var tutorial_visto: bool = false
var trafego_ativo: bool = true
var transacoes: int = 0

const MISSOES: Array[Dictionary] = [
	{"id": "primeira_compra", "titulo": "Primeiro investimento", "texto": "Compre sua primeira ação.", "xp": 100, "pontos": 50},
	{"id": "diversificar", "titulo": "Diversificação", "texto": "Tenha ações de três setores diferentes. No protótipo existem apenas três setores.", "xp": 200, "pontos": 100},
	{"id": "primeira_venda", "titulo": "Aprenda a vender", "texto": "Venda ao menos uma ação.", "xp": 100, "pontos": 50},
	{"id": "cinco_dias", "titulo": "Observe o mercado", "texto": "Avance cinco dias de mercado.", "xp": 125, "pontos": 50},
	{"id": "dez_dias", "titulo": "Planejamento", "texto": "Acompanhe dez dias de mercado.", "xp": 200, "pontos": 75},
	{"id": "lucro", "titulo": "Patrimônio em crescimento", "texto": "Alcance patrimônio de R$ 1.025,00 ou mais.", "xp": 250, "pontos": 100}
]

func comprar(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0:
		mensagem.emit("Selecione uma ação e uma quantidade válida.")
		return false
	var custo: float = acao.preco * quantidade
	if custo > dinheiro + 0.00001:
		mensagem.emit("Saldo insuficiente para esta compra.")
		return false
	dinheiro -= custo
	carteira[ticker] = int(carteira.get(ticker, 0)) + quantidade
	custos[ticker] = float(custos.get(ticker, 0.0)) + custo
	_registrar("COMPRA", ticker, quantidade, acao.preco)
	_atualizar()
	return true

func vender(ticker: String, quantidade: int) -> bool:
	var acao: Stock = Market.buscar(ticker)
	if acao == null or quantidade <= 0 or quantidade > int(carteira.get(ticker, 0)):
		mensagem.emit("Você não possui essa quantidade de ações.")
		return false
	var qtd_anterior: int = int(carteira[ticker])
	var custo_total: float = float(custos.get(ticker, 0.0))
	dinheiro += acao.preco * quantidade
	carteira[ticker] = qtd_anterior - quantidade
	custos[ticker] = custo_total * float(qtd_anterior - quantidade) / float(qtd_anterior)
	if int(carteira[ticker]) == 0:
		carteira.erase(ticker)
		custos.erase(ticker)
	_registrar("VENDA", ticker, quantidade, acao.preco)
	_atualizar()
	return true

func _registrar(tipo: String, ticker: String, quantidade: int, preco: float) -> void:
	transacoes += 1
	historico_operacoes.push_front({"dia": Market.dia, "tipo": tipo, "ticker": ticker, "quantidade": quantidade, "preco": preco})
	if historico_operacoes.size() > 200:
		historico_operacoes.resize(200)
	mensagem.emit("%s realizada: %d × %s por R$ %.2f" % [tipo.capitalize(), quantidade, ticker, preco])

func valor_da_carteira() -> float:
	var total: float = 0.0
	for ticker in carteira:
		var acao := Market.buscar(str(ticker))
		if acao != null:
			total += acao.preco * int(carteira[ticker])
	return total

func patrimonio() -> float:
	return dinheiro + valor_da_carteira()

func rentabilidade() -> float:
	return (patrimonio() / DINHEIRO_INICIAL - 1.0) * 100.0

func xp_para_proximo_nivel() -> int:
	return nivel * 250

func ganhar_xp(quantidade: int) -> void:
	xp += maxi(0, quantidade)
	while xp >= xp_para_proximo_nivel():
		xp -= xp_para_proximo_nivel()
		nivel += 1
		mensagem.emit("Parabéns! Você alcançou o nível %d." % nivel)
	xp_mudou.emit()

func registrar_dia() -> void:
	historico_patrimonio.append(patrimonio())
	if historico_patrimonio.size() > 500:
		historico_patrimonio.pop_front()
	_atualizar()

func _atualizar() -> void:
	_verificar_missoes()
	dinheiro_mudou.emit(dinheiro)
	estado_mudou.emit()

func _verificar_missoes() -> void:
	var setores: Dictionary = {}
	for ticker in carteira:
		if int(carteira[ticker]) > 0:
			var acao := Market.buscar(str(ticker))
			if acao != null:
				setores[acao.setor] = true
	for missao in MISSOES:
		var id: String = str(missao["id"])
		if id in missoes_concluidas:
			continue
		var completou: bool = false
		match id:
			"primeira_compra":
				for op in historico_operacoes:
					if op["tipo"] == "COMPRA":
						completou = true
						break
			"diversificar": completou = setores.size() >= 3
			"primeira_venda":
				for op in historico_operacoes:
					if op["tipo"] == "VENDA":
						completou = true
						break
			"cinco_dias": completou = Market.dia >= 5
			"dez_dias": completou = Market.dia >= 10
			"lucro": completou = patrimonio() >= 1025.0
		if completou:
			missoes_concluidas.append(id)
			pontos += int(missao["pontos"])
			ganhar_xp(int(missao["xp"]))
			conquistas.append(str(missao["titulo"]))
			mensagem.emit("Missão concluída: %s (+%d XP)" % [missao["titulo"], missao["xp"]])

func comprar_bonus() -> bool:
	if bonus_comprado or pontos < 150:
		mensagem.emit("Bônus já adquirido ou pontos insuficientes.")
		return false
	pontos -= 150
	bonus_comprado = true
	dinheiro += 50.0
	mensagem.emit("Bônus fictício da loja: +R$ 50 em saldo.")
	_atualizar()
	return true

func novo_jogo() -> void:
	Market.criar_mercado()
	dinheiro = DINHEIRO_INICIAL
	carteira.clear()
	custos.clear()
	historico_operacoes.clear()
	historico_patrimonio = [DINHEIRO_INICIAL]
	nivel = 1
	xp = 0
	pontos = 0
	conquistas.clear()
	missoes_concluidas.clear()
	bonus_comprado = false
	tutorial_visto = false
	transacoes = 0
	_atualizar()

func salvar() -> bool:
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo == null:
		mensagem.emit("Erro ao salvar o progresso.")
		return false
	var dados: Dictionary = {
		"versao": 1, "dinheiro": dinheiro, "carteira": carteira, "custos": custos,
		"historico_operacoes": historico_operacoes, "historico_patrimonio": historico_patrimonio,
		"nivel": nivel, "xp": xp, "pontos": pontos, "conquistas": conquistas,
		"missoes": missoes_concluidas, "bonus": bonus_comprado, "tutorial": tutorial_visto,
		"trafego": trafego_ativo, "transacoes": transacoes, "market": Market.exportar()
	}
	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()
	mensagem.emit("Progresso salvo neste dispositivo.")
	return true

func carregar() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		mensagem.emit("Nenhuma partida salva encontrada.")
		return false
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if arquivo == null:
		return false
	var dados = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	if (not (dados is Dictionary)) or int(dados.get("versao", -1)) != 1:
		mensagem.emit("Arquivo de salvamento inválido.")
		return false
	Market.importar(dados.get("market", {}))
	dinheiro = maxf(0.0, float(dados.get("dinheiro", DINHEIRO_INICIAL)))
	carteira = dados.get("carteira", {}).duplicate()
	custos = dados.get("custos", {}).duplicate()
	historico_operacoes.clear()
	for op in dados.get("historico_operacoes", []):
		if op is Dictionary:
			historico_operacoes.append(op)
	historico_patrimonio.clear()
	for valor in dados.get("historico_patrimonio", []):
		historico_patrimonio.append(float(valor))
	if historico_patrimonio.is_empty():
		historico_patrimonio.append(patrimonio())
	nivel = maxi(1, int(dados.get("nivel", 1)))
	xp = maxi(0, int(dados.get("xp", 0)))
	pontos = maxi(0, int(dados.get("pontos", 0)))
	conquistas.clear()
	for titulo in dados.get("conquistas", []):
		conquistas.append(str(titulo))
	missoes_concluidas.clear()
	for id in dados.get("missoes", []):
		missoes_concluidas.append(str(id))
	bonus_comprado = bool(dados.get("bonus", false))
	tutorial_visto = bool(dados.get("tutorial", false))
	trafego_ativo = bool(dados.get("trafego", true))
	transacoes = int(dados.get("transacoes", historico_operacoes.size()))
	_atualizar()
	xp_mudou.emit()
	mensagem.emit("Partida recuperada com sucesso.")
	return true
