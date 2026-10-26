class_name Stock
extends Resource
## Uma ação do mercado: guarda preço atual, histórico e volatilidade.

@export var ticker: String = ""
@export var nome: String = ""
@export var setor: String = ""
@export var preco: float = 10.0
## Desvio padrão da variação diária (0.02 = ~2% ao dia).
@export var volatilidade: float = 0.02

var historico: Array[float] = []


func avancar_dia(choque: float = 0.0) -> void:
	# randfn(média, desvio) sorteia uma variação com distribuição normal.
	# "choque" serve depois para notícias/eventos (ex.: -0.05 = queda de 5%).
	var variacao := randfn(0.0, volatilidade) + choque
	preco = maxf(0.01, preco * (1.0 + variacao))
	historico.append(preco)
