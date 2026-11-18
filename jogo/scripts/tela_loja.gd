
extends "res://scripts/tela_cheia.gd"

const ITENS := [
	{
		"id": "boost_xp",
		"categoria": "Boosts",
		"nome": "Boost de XP",
		"desc": "Dobre a próxima recompensa de XP, mesmo após avançar o dia.",
		"preco": 100,
		"disponivel": true
	},
	{
		"id": "dica",
		"categoria": "Boosts",
		"nome": "Dica de mercado",
		"desc": "Descubra uma noticia do proximo dia.",
		"preco": 150,
		"disponivel": true
	},
	{
		"id": "avatar",
		"categoria": "Visuais",
		"nome": "Avatar novo",
		"desc": "Desbloqueie um visual para seu perfil.",
		"preco": 300,
		"disponivel": false
	},
	{
		"id": "tema",
		"categoria": "Visuais",
		"nome": "Tema escuro dourado",
		"desc": "Personalize as cores da interface.",
		"preco": 250,
		"disponivel": false
	}
]

var mensagem: String = ""


func _titulo() -> String:
	return "Loja"


func _construir() -> void:
	GameState.moedas_mudou.connect(_atualizar)
	GameState.loja_mudou.connect(_atualizar)


func _atualizar() -> void:
	limpar(conteudo)

	conteudo.add_child(
		criar_label(
			"Suas moedas: %d" % GameState.moedas,
			20,
			COR_ALERTA
		)
	)

	conteudo.add_child(
		criar_label(
			"Total gasto: %d moedas"
			% GameState.total_moedas_gastas,
			16,
			COR_NEUTRA
		)
	)

	if mensagem != "":
		conteudo.add_child(
			criar_label(mensagem, 17, COR_BOA)
		)

	if GameState.boost_xp_ativo():
		conteudo.add_child(
			criar_label(
				"XP EM DOBRO ATIVO - PRÓXIMA RECOMPENSA",
				17,
				COR_BOA
			)
		)

	if GameState.dica_mercado_disponivel:
		var consultar := Button.new()
		consultar.text = "CONSULTAR DICA DE MERCADO"
		consultar.pressed.connect(_consultar_dica)
		conteudo.add_child(consultar)

	var categoria_atual := ""

	for item in ITENS:
		if item["categoria"] != categoria_atual:
			categoria_atual = item["categoria"]
			conteudo.add_child(
				criar_label(categoria_atual, 24, COR_BOA)
			)

		conteudo.add_child(_criar_cartao_item(item))

	if not GameState.historico_compras.is_empty():
		conteudo.add_child(
			criar_label("Historico de compras", 24, COR_BOA)
		)

		for compra in GameState.historico_compras:
			conteudo.add_child(
				criar_label(
					"%s - %d moedas - Dia %d" % [
						compra["nome"],
						compra["preco"],
						compra["dia"]
					],
					16,
					COR_NEUTRA
				)
			)


func _criar_cartao_item(item: Dictionary) -> PanelContainer:
	var cartao := criar_cartao()

	var linha := HBoxContainer.new()
	cartao.get_child(0).add_child(linha)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	textos.add_child(criar_label(item["nome"], 22))
	textos.add_child(
		criar_label(item["desc"], 16, COR_NEUTRA)
	)
	textos.add_child(
		criar_label(
			"Preco: %d moedas" % item["preco"],
			16,
			COR_ALERTA
		)
	)

	linha.add_child(textos)

	var id: String = str(item["id"])
	var ja_tem: bool = GameState.itens_comprados.has(id)
	var disponivel: bool = bool(item["disponivel"])
	var sem_saldo: bool = GameState.moedas < int(item["preco"])

	var botao := Button.new()
	botao.custom_minimum_size = Vector2(140, 40)
	botao.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if ja_tem:
		botao.text = "COMPRADO"
	elif not disponivel:
		botao.text = "EM BREVE"
	elif sem_saldo:
		botao.text = "SEM MOEDAS"
	else:
		botao.text = "COMPRAR"

	botao.disabled = ja_tem or not disponivel or sem_saldo

	botao.pressed.connect(_comprar_item.bind(id))

	linha.add_child(botao)

	return cartao


func _comprar_item(id: String) -> void:
	var item_escolhido: Dictionary = {}

	for item in ITENS:
		if str(item["id"]) == id:
			item_escolhido = item.duplicate()
			break

	if item_escolhido.is_empty():
		return

	if GameState.itens_comprados.has(id):
		return

	if not bool(item_escolhido["disponivel"]):
		return

	var preco: int = int(item_escolhido["preco"])
	var saldo_anterior: int = GameState.moedas

	var sucesso: bool = GameState.comprar_item_loja(
		item_escolhido
	)

	if sucesso:
		mensagem = (
			"Compra realizada: %s | Gasto: %d moedas | "
			+ "Saldo: %d -> %d moedas"
		) % [
			item_escolhido["nome"],
			preco,
			saldo_anterior,
			GameState.moedas
		]
	else:
		mensagem = "Nao foi possivel realizar a compra."

	_atualizar()


func _consultar_dica() -> void:
	mensagem = Market.consultar_dica()
	_atualizar()
