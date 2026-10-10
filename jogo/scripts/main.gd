extends Node2D
## Cena de teste: compra ações e avança 10 dias imprimindo no Output.

# Lista com os tickers das ações disponíveis
var acoes_disponiveis: Array[String] = ["PETR4", "VALE3", "ITUB4", "BBDC4"]

func _ready() -> void:
	GameState.dinheiro_mudou.connect(_on_dinheiro_mudou)
	Market.dia_avancou.connect(_on_dia_avancou)

	print("Dinheiro inicial: R$ %.2f" % GameState.dinheiro)
		
	var sorteio := acoes_disponiveis.duplicate()
	sorteio.shuffle()

	for n in 2:
		# 1. Pega a posição n da lista embaralhada
		var acao_sorteada: String = sorteio[n]
		
		# 2. Sorteia uma quantidade aleatória entre 0 e 10
		var qtd_aleatoria: int = randi_range(0, 10)
		
		# Se a quantidade for 0, pula para a próxima iteração do loop
		if qtd_aleatoria == 0:
			print("\n[Tentativa %d] Decidiu não comprar nenhuma ação desta vez (Qtd: 0)." % [n + 1])
			continue
			
		print("\n[Tentativa %d] Tentando comprar %d ações de %s..." % [n + 1, qtd_aleatoria, acao_sorteada])
		
		# 3. Executa a compra passando as variáveis como parâmetros
		if not GameState.comprar(acao_sorteada, qtd_aleatoria):
			print("-> Compra de %s recusada (Saldo insuficiente)" % acao_sorteada)
		else: 
			print("-> %d ações de %s compradas com sucesso!" % [qtd_aleatoria, acao_sorteada])
			
	# Avança os dias após as duas tentativas
	for i in 10:
		Market.avancar_dia()


func _on_dinheiro_mudou(novo_valor: float) -> void:
	print("  Dinheiro agora: R$ %.2f" % novo_valor)


func _on_dia_avancou(dia: int) -> void:
	var linha := "Dia %d" % dia
	for ticker in GameState.carteira:
		var preco: float = Market.buscar(ticker).preco
		linha += " | %s: R$ %.2f (x%d)" % [ticker, preco, GameState.carteira[ticker]]
	linha += " | Patrimônio: R$ %.2f (%+.2f%%)" % [GameState.patrimonio(), GameState.rentabilidade()]
	print(linha)
