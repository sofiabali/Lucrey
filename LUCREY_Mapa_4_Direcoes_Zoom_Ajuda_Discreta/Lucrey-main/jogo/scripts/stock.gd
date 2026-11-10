class_name Stock
extends Resource
## Dados de uma ação fictícia (não usa cotações reais).
@export var ticker: String = ""
@export var nome: String = ""
@export var setor: String = ""
@export var preco: float = 10.0
@export var volatilidade: float = 0.02
var historico: Array[float] = []

func avancar_dia(choque: float = 0.0) -> void:
	var variacao: float = randfn(0.0, volatilidade) + choque
	preco = maxf(0.01, preco * (1.0 + variacao))
	historico.append(preco)
	if historico.size() > 500:
		historico.pop_front()
