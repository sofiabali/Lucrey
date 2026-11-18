extends Node2D
## Cena de teste: compra ações e avança 10 dias imprimindo no Output.


func _ready() -> void:
	GameState.dinheiro_mudou.connect(_on_dinheiro_mudou)
	Market.dia_avancou.connect(_on_dia_avancou)

	print("Dinheiro inicial: R$ %.2f" % GameState.dinheiro)
	GameState.comprar("PETR4", 100)
	GameState.comprar("VALE3", 20)

	for i in 10:
		Market.avancar_dia()


func _on_dinheiro_mudou(novo_valor: float) -> void:
	print("  Dinheiro agora: R$ %.2f" % novo_valor)


func _on_dia_avancou(dia: int) -> void:
	print("Dia %d | PETR4: R$ %.2f | Patrimônio: R$ %.2f (%+.2f%%)" % [
		dia,
		Market.buscar("PETR4").preco,
		GameState.patrimonio(),
		GameState.rentabilidade(),
	])
