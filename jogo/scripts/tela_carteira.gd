@onready var valor_patrimonio: Label = %ValorPatrimonioTotal
@onready var valor_investido: Label = %ValorInvestido
@onready var valor_disponivel: Label = %ValorDisponivel
@onready var lista: VBoxContainer = %ListaAcoes
@onready var mensagem_vazia: Label = %MensagemCarteiraVazia


## A moldura já existe na cena, então não montamos outra.
func _montar() -> void:
	pass


func _construir() -> void:
	GameState.dinheiro_mudou.connect(func(_v: float) -> void: _atualizar())
	Market.dia_avancou.connect(func(_d: int) -> void: _atualizar())


func _atualizar() -> void:
	valor_patrimonio.text = _moeda(GameState.patrimonio())
	valor_investido.text = _moeda(GameState.valor_da_carteira())
	valor_disponivel.text = _moeda(GameState.dinheiro)

	# Apaga as linhas antigas (o cabeçalho da tabela não está no grupo e fica)
	for filho in lista.get_children():
		if filho.is_in_group("linhas_carteira"):
			lista.remove_child(filho)
			filho.queue_free()

	var tem_acoes := false
	for ticker in GameState.carteira:
		var qtd: int = GameState.carteira[ticker]
		if qtd <= 0:
			continue
		tem_acoes = true
		lista.add_child(_criar_linha(ticker, qtd))

	mensagem_vazia.visible = not tem_acoes
	lista.visible = tem_acoes


func _criar_linha(ticker: String, qtd: int) -> HBoxContainer:
	var acao: Stock = Market.buscar(ticker)
	var lucro: float = GameState.lucro_da_posicao(ticker)
	var custo: float = GameState.custo_da_posicao(ticker)
	var pct: float = 0.0
	if custo > 0.0:
		pct = lucro / custo * 100.0

	var cor := COR_NEUTRA
	if lucro > 0.0:
		cor = COR_BOA
	elif lucro < 0.0:
		cor = COR_RUIM

	var linha := HBoxContainer.new()
	linha.add_to_group("linhas_carteira")
	linha.add_child(_celula("%s (%s)" % [acao.nome, ticker]))
	linha.add_child(_celula("%d ações" % qtd))
	linha.add_child(_celula(_moeda(acao.preco)))
	linha.add_child(_celula(_moeda(acao.preco * qtd)))
	linha.add_child(_celula("%+.2f%%" % pct, cor))
	return linha


## Uma coluna da tabela (expande igual ao cabeçalho, para alinhar).
func _celula(texto: String, cor: Color = COR_TEXTO) -> Label:
	var l := criar_label(texto, 16, cor)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _moeda(valor: float) -> String:
	return "R$ %.2f" % valor


func _on_botao_voltar_pressed() -> void:
	hide()
