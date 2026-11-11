extends "res://scripts/tela_cheia.gd"

## Itens de exemplo. Mantenha os da mesma categoria juntos.
const ITENS := [
	{"id": "boost_xp", "categoria": "Boosts", "nome": "Boost de XP", "desc": "Ganhe o dobro de XP por 1 dia.", "preco": 100},
	{"id": "dica", "categoria": "Boosts", "nome": "Dica de mercado", "desc": "Revela uma notícia antes de ela sair.", "preco": 150},
	{"id": "avatar", "categoria": "Visuais", "nome": "Avatar novo", "desc": "Desbloqueia um visual para o seu perfil.", "preco": 300},
	{"id": "tema", "categoria": "Visuais", "nome": "Tema escuro dourado", "desc": "Muda as cores da interface.", "preco": 250},
]

## TEMPORÁRIO: depois trocamos pelas moedas reais do GameState.
var moedas: int = 500
var comprados: Dictionary = {}


func _titulo() -> String:
	return "Loja"


func _construir() -> void:
	pass


func _atualizar() -> void:
	limpar(conteudo)
	conteudo.add_child(criar_label("Suas moedas: %d" % moedas, 20, COR_ALERTA))

	var categoria_atual := ""
	for item in ITENS:
		if item["categoria"] != categoria_atual:
			categoria_atual = item["categoria"]
			conteudo.add_child(criar_label(categoria_atual, 24, COR_BOA))
		conteudo.add_child(_criar_cartao_item(item))


func _criar_cartao_item(item: Dictionary) -> PanelContainer:
	var cartao := criar_cartao()
	var linha := HBoxContainer.new()
	cartao.get_child(0).add_child(linha)

	# Lado esquerdo: nome, descrição e preço
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(criar_label(item["nome"], 22))
	textos.add_child(criar_label(item["desc"], 16, COR_NEUTRA))
	textos.add_child(criar_label("Preço: %d moedas" % item["preco"], 16, COR_ALERTA))
	linha.add_child(textos)

	# Lado direito: botão de compra
	var ja_tem: bool = comprados.has(item["id"])
	var sem_saldo: bool = moedas < item["preco"]

	var comprar := Button.new()
	comprar.text = "COMPRADO" if ja_tem else "COMPRAR"
	comprar.disabled = ja_tem or sem_saldo
	comprar.custom_minimum_size = Vector2(130, 40)
	comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	comprar.pressed.connect(_comprar.bind(item))
	linha.add_child(comprar)

	return cartao


func _comprar(item: Dictionary) -> void:
	moedas -= item["preco"]
	comprados[item["id"]] = true
	_atualizar()
