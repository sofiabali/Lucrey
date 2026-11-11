extends "res://scripts/tela_cheia.gd"


func _titulo() -> String:
	return "Cotações"


func _construir() -> void:
	pass


func _atualizar() -> void:
	limpar(conteudo)
	conteudo.add_child(criar_label("Em breve...", 18, COR_NEUTRA))
