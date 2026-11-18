
extends Control

const CAMINHO_CONFIG := "user://configuracoes.cfg"

var botao_musica: CheckButton
var botao_efeitos: CheckButton
var player_musica: AudioStreamPlayer

var musica_ativada: bool = true
var efeitos_ativados: bool = true


func _ready() -> void:
	# Procura os controles já existentes na cena.
	var linha_musica := find_child(
		"LinhaMusica", true, false
	)

	var linha_efeitos := find_child(
		"LinhaEfeitos", true, false
	)

	var linha_tela := find_child(
		"LinhaTela", true, false
	)

	if linha_musica != null:
		botao_musica = linha_musica.get_node_or_null(
			"CheckButton"
		)

	if linha_efeitos != null:
		botao_efeitos = linha_efeitos.get_node_or_null(
			"CheckButton"
		)

	# Remove a opção Tela Cheia da interface.
	if linha_tela != null:
		linha_tela.hide()

	# Busca o player da música na cena principal.
	var cena_principal := get_tree().current_scene

	if cena_principal != null:
		player_musica = cena_principal.get_node_or_null(
			"AudioStreamPlayer"
		)

	# Conecta os controles.
	if botao_musica != null:
		botao_musica.toggled.connect(
			_alterar_musica
		)

	if botao_efeitos != null:
		botao_efeitos.toggled.connect(
			_alterar_efeitos
		)

	_carregar_configuracoes()
	_aplicar_configuracoes()


# ==========================================
# MÚSICA
# ==========================================

func _alterar_musica(ativado: bool) -> void:
	musica_ativada = ativado
	_aplicar_musica()


func _aplicar_musica() -> void:
	if player_musica == null:
		return

	# Silencia sem reiniciar a música.
	player_musica.volume_db = (
		0.0 if musica_ativada else -80.0
	)

	# Mantém a música em repetição.
	if player_musica.stream is AudioStreamMP3:
		var musica_mp3 := (
			player_musica.stream as AudioStreamMP3
		)
		musica_mp3.loop = true

	if musica_ativada and not player_musica.playing:
		player_musica.play()


# ==========================================
# EFEITOS SONOROS
# ==========================================

func _alterar_efeitos(ativado: bool) -> void:
	efeitos_ativados = ativado
	_aplicar_efeitos()


func _aplicar_efeitos() -> void:
	# Se existir um barramento chamado SFX,
	# controla todos os efeitos ligados a ele.
	var indice_sfx := AudioServer.get_bus_index("SFX")

	if indice_sfx >= 0:
		AudioServer.set_bus_mute(
			indice_sfx,
			not efeitos_ativados
		)

	# Também controla os players de efeitos
	# que já existem na cena principal.
	var cena_principal := get_tree().current_scene

	if cena_principal != null:
		_aplicar_efeitos_nos_nos(cena_principal)


func _aplicar_efeitos_nos_nos(no: Node) -> void:
	if no is AudioStreamPlayer:
		var player := no as AudioStreamPlayer

		# Nunca silencia a música junto com os efeitos.
		if player != player_musica:
			player.volume_db = (
				0.0 if efeitos_ativados else -80.0
			)

	for filho in no.get_children():
		_aplicar_efeitos_nos_nos(filho)


# ==========================================
# APLICAR CONFIGURAÇÕES
# ==========================================

func _aplicar_configuracoes() -> void:
	if botao_musica != null:
		botao_musica.set_pressed_no_signal(
			musica_ativada
		)

	if botao_efeitos != null:
		botao_efeitos.set_pressed_no_signal(
			efeitos_ativados
		)

	_aplicar_musica()
	_aplicar_efeitos()


# ==========================================
# SALVAR CONFIGURAÇÕES
# ==========================================

func _salvar_configuracoes() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"audio", "musica", musica_ativada
	)

	config.set_value(
		"audio", "efeitos", efeitos_ativados
	)

	var erro := config.save(CAMINHO_CONFIG)

	if erro != OK:
		push_warning(
			"Não foi possível salvar as configurações."
		)


# ==========================================
# CARREGAR CONFIGURAÇÕES
# ==========================================

func _carregar_configuracoes() -> void:
	var config := ConfigFile.new()

	var erro := config.load(CAMINHO_CONFIG)

	if erro != OK:
		return

	musica_ativada = config.get_value(
		"audio", "musica", true
	)

	efeitos_ativados = config.get_value(
		"audio", "efeitos", true
	)


# ==========================================
# BOTÕES DA TELA
# ==========================================

func _on_botao_fechar_pressed() -> void:
	_salvar_configuracoes()
	hide()


func _on_salvar_pressed() -> void:
	_salvar_configuracoes()
	hide()
