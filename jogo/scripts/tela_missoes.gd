extends TelaCheia
## Tela cheia de missões: concluídas, em andamento e bloqueadas.


func _titulo() -> String:
	return "Missões"


func _construir() -> void:
	GameState.missao_mudou.connect(_atualizar)
	GameState.dinheiro_mudou.connect(func(_v: float) -> void: _atualizar())


func _atualizar() -> void:
	limpar(conteudo)
	var missoes: Array = GameState.MISSOES
	for i in missoes.size():
		var m: Dictionary = missoes[i]
		conteudo.add_child(_criar_cartao(m, i))


func _criar_cartao(m: Dictionary, indice: int) -> Control:
	var concluida: bool = indice < GameState.missao_indice
	var ativa: bool = indice == GameState.missao_indice

	var cartao := criar_cartao(18)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 6)
	cartao.get_child(0).add_child(caixa)

	# Título à esquerda, situação à direita
	var topo := HBoxContainer.new()
	caixa.add_child(topo)
	var titulo := criar_label(m["titulo"], 22)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)

	if concluida:
		topo.add_child(criar_label("CONCLUÍDA", 14, COR_BOA))
		cartao.modulate = Color(1, 1, 1, 0.65)
	elif ativa:
		topo.add_child(criar_label("EM ANDAMENTO", 14, COR_ALERTA))
	else:
		topo.add_child(criar_label("BLOQUEADA", 14, COR_NEUTRA))
		cartao.modulate = Color(1, 1, 1, 0.5)

	caixa.add_child(criar_label(m["descricao"], 16, COR_NEUTRA))

	# Só a missão ativa mostra o progresso
	if ativa:
		var meta: int = m["meta"]
		var progresso: int = mini(GameState.progresso_missao(), meta)
		var barra := ProgressBar.new()
		barra.max_value = meta
		barra.value = progresso
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 12)
		caixa.add_child(barra)
		caixa.add_child(criar_label("Progresso: %d / %d" % [progresso, meta], 14, COR_NEUTRA))

	caixa.add_child(criar_label(
		"Recompensa: %d moedas · %d XP" % [m["moedas"], m["xp"]], 15))
	return cartao
