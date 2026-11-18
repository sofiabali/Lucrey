class_name GraficoPizza
extends Control
## Gráfico de rosca desenhado por código. Cada fatia: {"valor": float, "cor": Color}.

const ESPESSURA := 22.0
const COR_VAZIO := Color(0.106, 0.149, 0.2)

var fatias: Array = []


func definir_fatias(novas: Array) -> void:
	fatias = novas
	queue_redraw()


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0 - ESPESSURA / 2.0
	var total := 0.0
	for f in fatias:
		total += float(f["valor"])

	if total <= 0.0:
		draw_arc(centro, raio, 0.0, TAU, 64, COR_VAZIO, ESPESSURA, true)
		return

	var inicio := -PI / 2.0  # começa no topo
	for f in fatias:
		var angulo: float = TAU * float(f["valor"]) / total
		var pontos: int = maxi(8, int(angulo * 12.0))
		draw_arc(centro, raio, inicio, inicio + angulo, pontos, f["cor"], ESPESSURA, true)
		inicio += angulo
