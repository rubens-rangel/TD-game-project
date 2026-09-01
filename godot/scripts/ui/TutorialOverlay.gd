extends CanvasLayer
class_name TutorialOverlay

signal finished

const STEPS := [
	{
		"title": "Defenda o labirinto",
		"body": "Inimigos seguem o caminho até a sua base. Se a vida da base chegar a zero, a partida acaba. Construa torres, muralhas e habilidades para sobreviver às ondas."
	},
	{
		"title": "Loja à direita",
		"body": "Abra a loja, toque em Comprar e clique no mapa. O preview fica verde quando o local é válido e vermelho quando não dá para colocar. Botão direito cancela a construção."
	},
	{
		"title": "Melhorar e vender",
		"body": "Clique em uma torre para ver o painel de melhorias. Use moedas ou esmeraldas para evoluir. Se posicionar mal, você pode vender e recuperar parte do investimento."
	},
	{
		"title": "Skills e pausa",
		"body": "As teclas 1 a 5 ativam skills (coletar moedas, dano, velocidade, slow e magnetismo). Esc abre o menu de pausa, salvamento e opções."
	}
]

var _step: int = 0
var _title: Label
var _body: Label
var _counter: Label
var _next_btn: Button

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -170
	panel.offset_bottom = 170
	panel.add_theme_stylebox_override("panel", UIHelper.panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	_title = UIHelper.create_label("", 22, GameConstants.COLOR_UI_GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)

	_body = UIHelper.create_label("", 15, Color(0.88, 0.9, 0.96))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_body)

	_counter = UIHelper.create_label("", 12, Color(0.65, 0.68, 0.8))
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_counter)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	var skip_btn := UIHelper.secondary_button("Pular", Vector2(120, 40))
	skip_btn.pressed.connect(_finish)
	_next_btn = UIHelper.primary_button("Próximo", Vector2(140, 40))
	_next_btn.pressed.connect(_next)
	buttons.add_child(skip_btn)
	buttons.add_child(_next_btn)
	vbox.add_child(buttons)

	margin.add_child(vbox)
	panel.add_child(margin)
	add_child(panel)
	_render()

func _next() -> void:
	if _step >= STEPS.size() - 1:
		_finish()
		return
	_step += 1
	_render()

func _render() -> void:
	var data: Dictionary = STEPS[_step]
	_title.text = str(data.title)
	_body.text = str(data.body)
	_counter.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next_btn.text = "Concluir" if _step >= STEPS.size() - 1 else "Próximo"

func _finish() -> void:
	UXSettings.set_tutorial_done(true)
	finished.emit()
	queue_free()
