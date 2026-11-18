extends Control
## Gráfico vetorial simples para exibir valores reais da simulação local.
var valores: Array[float] = []
var cor_linha: Color = Color("58cf8d")

func definir_valores(novos_valores: Array[float]) -> void:
	valores = novos_valores.duplicate()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var area := Rect2(Vector2(8, 12), size - Vector2(16, 24))
	if area.size.x <= 0 or area.size.y <= 0:
		return
	draw_rect(area, Color("101c29", 0.85), true)
	for i in range(1, 4):
		var y := area.position.y + area.size.y * float(i) / 4.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color("738694", 0.22), 1)
	if valores.is_empty():
		return
	var minimo: float = valores.min()
	var maximo: float = valores.max()
	var intervalo: float = maxf(maximo - minimo, 0.01)
	var pontos := PackedVector2Array()
	for i in range(valores.size()):
		var x: float = area.position.x + area.size.x * float(i) / float(maxi(valores.size() - 1, 1))
		var y: float = area.end.y - area.size.y * (valores[i] - minimo) / intervalo
		pontos.append(Vector2(x, y))
	if pontos.size() == 1:
		draw_line(Vector2(area.position.x, area.position.y + area.size.y * 0.5), Vector2(area.end.x, area.position.y + area.size.y * 0.5), cor_linha, 3.0)
		draw_circle(Vector2(area.end.x - 8, area.position.y + area.size.y * 0.5), 4.0, Color.WHITE)
	else:
		draw_polyline(pontos, cor_linha, 3.0, true)
		draw_circle(pontos[pontos.size() - 1], 4.0, Color.WHITE)
