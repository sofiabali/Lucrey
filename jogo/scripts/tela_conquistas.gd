extends "res://scripts/tela_cheia.gd"

## Conquistas de exemplo. Depois ligamos ao progresso real do jogo.
const CONQUISTAS := [
	{"nome": "Primeiro passo", "desc": "Faça sua primeira compra de ações.", "atual": 1, "meta": 1},
	{"nome": "Diversificado", "desc": "Tenha ações de 3 setores diferentes.", "atual": 1, "meta": 3},
	{"nome": "Investidor", "desc": "Chegue a R$ 2000 de patrimônio.", "atual": 1000, "meta": 2000},
	{"nome": "Paciência", "desc": "Avance 30 dias.", "atual": 0, "meta": 30},
]


func _titulo() -> String:
	return "Conquistas"


func _construir() -> void:
	pass


func _atualizar() -> void:
	limpar(conteudo)

	var conquistas: Array = Conquistas.obter_lista()

	var feitas := 0
	for c in conquistas:
		if c["atual"] >= c["meta"]:
			feitas += 1
	conteudo.add_child(criar_label("Concluídas: %d / %d" % [feitas, conquistas.size()], 20, COR_ALERTA))

	for c in conquistas:
		conteudo.add_child(_criar_cartao_conquista(c))


func _criar_cartao_conquista(c: Dictionary) -> PanelContainer:
	var feita: bool = c["atual"] >= c["meta"]
	var cartao := criar_cartao()
	var caixa := VBoxContainer.new()
	cartao.get_child(0).add_child(caixa)

	# Linha de cima: nome à esquerda, status à direita
	var topo := HBoxContainer.new()
	caixa.add_child(topo)
	var titulo := criar_label(c["nome"], 22, COR_TEXTO if feita else COR_NEUTRA)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	var status := "CONCLUÍDA" if feita else "EM ANDAMENTO"
	topo.add_child(criar_label(status, 14, COR_BOA if feita else COR_ALERTA))

	caixa.add_child(criar_label(c["desc"], 16, COR_NEUTRA))

	# Barra de progresso
	var barra := ProgressBar.new()
	barra.max_value = c["meta"]
	barra.value = mini(c["atual"], c["meta"])
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 14)
	caixa.add_child(barra)

	caixa.add_child(criar_label("Progresso: %d / %d" % [mini(c["atual"], c["meta"]), c["meta"]], 14, COR_NEUTRA))
	return cartao
