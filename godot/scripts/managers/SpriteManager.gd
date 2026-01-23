extends RefCounted
class_name SpriteManager

# Sistema de gerenciamento de sprites usando Sprite2D ao invés de _draw()
# MUITO mais performático porque usa GPU ao invés de CPU

var game: Node2D
var sprite_container: Node2D  # Container para todos os sprites

# Referências para obter texturas e dados
var tex_enemy_zombie: Texture2D
var tex_enemy_zombie_gordo: Texture2D
var tex_enemy_zombie_corredor: Texture2D
var tex_enemy_humanoid: Texture2D
var tex_enemy_robot: Texture2D
var tex_enemy_alien: Texture2D
var tex_enemy_boss: Texture2D
var wave_manager: WaveManager
var weather_manager: WeatherManager
var culling_manager: CullingManager
var enemy_effects: Dictionary  # Referência ao enemy_effects do Game
var get_enemy_direction_func: Callable  # Função para obter direção do inimigo

# Pools de sprites (reutilização)
var enemy_sprite_pool: Array = []  # Array de Sprite2D nodes
var hp_bar_pool: Array = []  # Array de Control nodes (barras de HP)
var shadow_pool: Array = []  # Array de Sprite2D nodes (sombras circulares)

# Mapeamento: enemy_idx -> sprite_node
var enemy_sprites: Dictionary = {}  # {enemy_idx: sprite_node}
var enemy_hp_bars: Dictionary = {}  # {enemy_idx: hp_bar_node}
var enemy_shadows: Dictionary = {}  # {enemy_idx: shadow_node}

# Configurações
const MAX_POOL_SIZE := 200  # Tamanho máximo do pool
const INITIAL_POOL_SIZE := 50  # Tamanho inicial do pool

func _init(game_node: Node2D):
	game = game_node
	sprite_container = Node2D.new()
	sprite_container.name = "SpriteContainer"
	game.add_child(sprite_container)
	
	# Pré-criar alguns sprites no pool
	_prewarm_pool()

func setup_textures(
	zombie: Texture2D,
	zombie_gordo: Texture2D,
	zombie_corredor: Texture2D,
	humanoid: Texture2D,
	robot: Texture2D,
	alien: Texture2D,
	boss: Texture2D
) -> void:
	"""Configura as texturas dos inimigos"""
	tex_enemy_zombie = zombie
	tex_enemy_zombie_gordo = zombie_gordo
	tex_enemy_zombie_corredor = zombie_corredor
	tex_enemy_humanoid = humanoid
	tex_enemy_robot = robot
	tex_enemy_alien = alien
	tex_enemy_boss = boss

func setup_managers(
	wave_mgr: WaveManager,
	weather_mgr: WeatherManager,
	culling_mgr: CullingManager,
	enemy_effects_ref: Dictionary,
	get_direction_func: Callable = Callable()
) -> void:
	"""Configura os managers necessários"""
	wave_manager = wave_mgr
	weather_manager = weather_mgr
	culling_manager = culling_mgr
	enemy_effects = enemy_effects_ref
	get_enemy_direction_func = get_direction_func

func _prewarm_pool() -> void:
	"""Pré-cria sprites no pool para evitar alocações durante o jogo"""
	for i in range(INITIAL_POOL_SIZE):
		var sprite = _create_enemy_sprite()
		enemy_sprite_pool.append(sprite)
		
		var shadow = _create_shadow_sprite()
		shadow_pool.append(shadow)
		
		var hp_bar = _create_hp_bar()
		hp_bar_pool.append(hp_bar)

func _create_enemy_sprite() -> Sprite2D:
	"""Cria um novo Sprite2D para inimigo"""
	var sprite = Sprite2D.new()
	sprite.visible = false  # Invisível até ser usado
	sprite_container.add_child(sprite)
	return sprite

func _create_shadow_sprite() -> Sprite2D:
	"""Cria um Sprite2D para sombra circular"""
	var shadow_node = Sprite2D.new()
	# Criar uma textura circular simples usando código
	# Usar um círculo preto com transparência
	var shadow_size = 64  # Tamanho maior para melhor qualidade
	var shadow_image = Image.create(shadow_size, shadow_size, false, Image.FORMAT_RGBA8)
	shadow_image.fill(Color(0, 0, 0, 0))
	
	# Desenhar círculo na imagem com fade suave nas bordas
	var center = Vector2(shadow_size / 2.0, shadow_size / 2.0)
	var radius = shadow_size / 2.0 - 2.0
	for y in range(shadow_size):
		for x in range(shadow_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				# Fade suave: mais opaco no centro, mais transparente nas bordas
				var fade = 1.0 - (dist / radius) * 0.7  # 70% de fade nas bordas
				var alpha = 0.3 * fade
				shadow_image.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	var shadow_texture = ImageTexture.create_from_image(shadow_image)
	shadow_node.texture = shadow_texture
	shadow_node.visible = false
	sprite_container.add_child(shadow_node)
	return shadow_node

func _create_hp_bar() -> Control:
	"""Cria uma barra de HP (usando ColorRect ou ProgressBar)"""
	var hp_bar_container = Control.new()
	hp_bar_container.visible = false
	
	# Fundo da barra
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2)
	bg.size = Vector2(20, 3)
	bg.position = Vector2(-10, -16)
	hp_bar_container.add_child(bg)
	
	# Barra de HP (verde)
	var hp_fill = ColorRect.new()
	hp_fill.color = Color(0.2, 0.8, 0.2)
	hp_fill.size = Vector2(20, 3)
	hp_fill.position = Vector2(-10, -16)
	hp_fill.name = "HPFill"
	hp_bar_container.add_child(hp_fill)
	
	sprite_container.add_child(hp_bar_container)
	return hp_bar_container

# ========== FUNÇÕES PÚBLICAS ==========

func get_enemy_sprite() -> Sprite2D:
	"""Obtém um sprite do pool ou cria novo"""
	if enemy_sprite_pool.size() > 0:
		var sprite = enemy_sprite_pool.pop_back()
		sprite.visible = true
		return sprite
	return _create_enemy_sprite()

func return_enemy_sprite(sprite: Sprite2D) -> void:
	"""Retorna sprite ao pool"""
	sprite.visible = false
	sprite.texture = null
	sprite.modulate = Color.WHITE
	if enemy_sprite_pool.size() < MAX_POOL_SIZE:
		enemy_sprite_pool.append(sprite)

func get_shadow() -> Sprite2D:
	"""Obtém uma sombra do pool"""
	if shadow_pool.size() > 0:
		var shadow = shadow_pool.pop_back()
		shadow.visible = true
		return shadow
	return _create_shadow_sprite()

func return_shadow(shadow: Sprite2D) -> void:
	"""Retorna sombra ao pool"""
	shadow.visible = false
	if shadow_pool.size() < MAX_POOL_SIZE:
		shadow_pool.append(shadow)

func get_hp_bar() -> Control:
	"""Obtém uma barra de HP do pool"""
	if hp_bar_pool.size() > 0:
		var hp_bar = hp_bar_pool.pop_back()
		hp_bar.visible = true
		return hp_bar
	return _create_hp_bar()

func return_hp_bar(hp_bar: Control) -> void:
	"""Retorna barra de HP ao pool"""
	hp_bar.visible = false
	if hp_bar_pool.size() < MAX_POOL_SIZE:
		hp_bar_pool.append(hp_bar)

# ========== ATUALIZAÇÃO DE INIMIGOS ==========

func update_all_enemies(enemies: Array, camera_pos: Vector2 = Vector2.ZERO) -> void:
	"""Atualiza todos os sprites dos inimigos - otimizado com time slicing"""
	var active_enemy_indices = {}
	var enemies_count = enemies.size()
	
	# Time slicing: processar apenas um subconjunto por frame em waves muito grandes
	var max_updates = enemies_count
	if enemies_count > 200:
		max_updates = 100  # Limitar a 100 atualizações por frame
	elif enemies_count > 100:
		max_updates = 150
	
	var processed = 0
	for e in enemies:
		if processed >= max_updates:
			break
		
		var enemy_idx = e.get("idx", -1)
		if enemy_idx < 0:
			continue
		
		# Remover se morto ou fora da tela
		if e["hp"] <= 0 or e.get("reached", false):
			remove_enemy_sprite(enemy_idx)
			continue
		
		# Verificar culling
		if culling_manager and not culling_manager.should_render(e["pos"], camera_pos):
			remove_enemy_sprite(enemy_idx)
			continue
		
		active_enemy_indices[enemy_idx] = true
		_update_single_enemy(enemy_idx, e, camera_pos)
		processed += 1
	
	# Remover sprites de inimigos que não existem mais
	for enemy_idx in enemy_sprites.keys():
		if not active_enemy_indices.has(enemy_idx):
			remove_enemy_sprite(enemy_idx)

func _update_single_enemy(enemy_idx: int, enemy_data: Dictionary, camera_pos: Vector2) -> void:
	"""Atualiza sprite de um único inimigo"""
	# Obter textura
	var texture = _get_enemy_texture(enemy_data)
	if texture == null:
		return
	
	# Calcular tamanho
	var is_boss = enemy_data.get("is_boss", false)
	var enemy_size_multiplier = 1.5 if is_boss else 1.2
	var size = Vector2(28.0 * enemy_size_multiplier, 28.0 * enemy_size_multiplier)  # TILE_SIZE = 28
	
	# Calcular modulate (efeitos visuais)
	var modulate = _get_enemy_modulate(enemy_data)
	
	# Calcular LOD
	var lod_level = 0
	if culling_manager:
		lod_level = culling_manager.get_lod_level(enemy_data["pos"], camera_pos)
	
	# Obter ou criar sprite
	if not enemy_sprites.has(enemy_idx):
		enemy_sprites[enemy_idx] = get_enemy_sprite()
		enemy_sprites[enemy_idx].z_index = 10  # Acima do grid
	
	var sprite = enemy_sprites[enemy_idx]
	sprite.position = enemy_data["pos"]
	
	# Suporte para sprite sheets (2x2 grid) usando AtlasTexture
	var tex_size = texture.get_size()
	var is_sprite_sheet = tex_size.x >= 128 and tex_size.y >= 128
	
	if is_sprite_sheet and get_enemy_direction_func.is_valid():
		# Sprite sheet: usar AtlasTexture para mostrar a direção correta
		var direction = get_enemy_direction_func.call(enemy_data)
		var frame_size = tex_size / 2.0
		var atlas_region: Rect2
		
		# Mapear direção para região do sprite sheet (mesma lógica do código antigo)
		match direction:
			"up":
				atlas_region = Rect2(frame_size.x, frame_size.y, frame_size.x, frame_size.y)  # Baixo no sprite
			"down":
				atlas_region = Rect2(0, 0, frame_size.x, frame_size.y)  # Cima no sprite
			"left":
				atlas_region = Rect2(0, frame_size.y, frame_size.x, frame_size.y)  # Esquerda no sprite
			"right":
				atlas_region = Rect2(frame_size.x, 0, frame_size.x, frame_size.y)  # Direita no sprite
			_:
				atlas_region = Rect2(0, 0, frame_size.x, frame_size.y)  # Default: cima
		
		# Criar ou atualizar AtlasTexture
		var atlas_texture: AtlasTexture
		if sprite.texture is AtlasTexture:
			atlas_texture = sprite.texture as AtlasTexture
		else:
			atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
		
		# Atualizar região do atlas
		atlas_texture.region = atlas_region
		sprite.texture = atlas_texture
		
		# Ajustar escala para o tamanho desejado
		if frame_size.x > 0 and frame_size.y > 0:
			sprite.scale = size / frame_size
		else:
			sprite.scale = Vector2.ONE
	else:
		# Textura normal (não é sprite sheet)
		sprite.texture = texture
		if tex_size.x > 0 and tex_size.y > 0:
			sprite.scale = size / tex_size
		else:
			sprite.scale = Vector2.ONE
	
	sprite.modulate = modulate
	sprite.visible = true
	
	# Aplicar animação de morte (shrink)
	var is_dying = enemy_data.get("dying", false)
	if is_dying:
		var dying_progress = enemy_data.get("dying_time", 0.0) / 0.5
		sprite.scale *= (1.0 - dying_progress * 0.5)  # encolhe até 50%
	
	# Atualizar sombra (sempre mostrar para todos os inimigos visíveis)
	if not enemy_shadows.has(enemy_idx):
		enemy_shadows[enemy_idx] = get_shadow()
		enemy_shadows[enemy_idx].z_index = 5  # Abaixo do sprite
	
	var shadow = enemy_shadows[enemy_idx]
	# Calcular posição e tamanho da sombra baseado no tamanho do inimigo
	var shadow_offset = Vector2(0, size.y * 0.25)
	var shadow_radius = size.x * 0.28
	shadow.position = enemy_data["pos"] + shadow_offset
	# Ajustar escala da sombra para o tamanho correto
	if shadow.texture:
		var shadow_texture_size = shadow.texture.get_size()
		if shadow_texture_size.x > 0:
			shadow.scale = Vector2(shadow_radius * 2.0 / shadow_texture_size.x, shadow_radius * 2.0 / shadow_texture_size.y)
	shadow.visible = true
	
	# Atualizar barra de HP (apenas LOD próximo e não morrendo)
	# is_dying já foi declarado acima
	if (lod_level <= 1 or is_boss) and not is_dying:
		if not enemy_hp_bars.has(enemy_idx):
			enemy_hp_bars[enemy_idx] = get_hp_bar()
			enemy_hp_bars[enemy_idx].z_index = 15  # Acima do sprite
		
		var hp_bar = enemy_hp_bars[enemy_idx]
		hp_bar.position = enemy_data["pos"] + Vector2(-10, -16)
		
		# Atualizar tamanho da barra de HP
		var max_hp = enemy_data.get("max_hp", 2)
		var hp_ratio = clamp(float(enemy_data["hp"]) / float(max_hp), 0.0, 1.0)
		var hp_fill = hp_bar.get_node_or_null("HPFill")
		if hp_fill:
			var bar_width = 28 if is_boss else 20
			hp_fill.size.x = bar_width * hp_ratio
			
			# Mudar cor baseado no HP
			if hp_ratio > 0.6:
				hp_fill.color = Color(0.2, 0.8, 0.2)  # Verde
			elif hp_ratio > 0.3:
				hp_fill.color = Color(0.9, 0.7, 0.2)  # Amarelo
			else:
				hp_fill.color = Color(0.9, 0.2, 0.2)  # Vermelho
			
			if is_boss:
				hp_fill.color = Color(0.9, 0.2, 0.9)  # Roxo para boss
		
		hp_bar.visible = true
	elif enemy_hp_bars.has(enemy_idx):
		# Esconder barra de HP se LOD distante ou morrendo
		return_hp_bar(enemy_hp_bars[enemy_idx])
		enemy_hp_bars.erase(enemy_idx)

func _get_enemy_texture(enemy: Dictionary) -> Texture2D:
	"""Retorna a textura do inimigo (lógica completa aqui)"""
	var is_boss = enemy.get("is_boss", false)
	if is_boss and tex_enemy_boss != null:
		return tex_enemy_boss
	
	var enemy_type = enemy.get("enemy_type", -1)
	
	# Usar GameConstants.EnemyType se disponível
	if enemy_type >= 0:
		match enemy_type:
			0:  # ZOMBIE
				return tex_enemy_zombie if tex_enemy_zombie != null else null
			1:  # ZOMBIE_GORDO
				return tex_enemy_zombie_gordo if tex_enemy_zombie_gordo != null else tex_enemy_zombie
			2:  # ZOMBIE_CORREDOR
				return tex_enemy_zombie_corredor if tex_enemy_zombie_corredor != null else tex_enemy_zombie
			3:  # HUMANOID
				return tex_enemy_humanoid if tex_enemy_humanoid != null else null
			4:  # ROBOT
				return tex_enemy_robot if tex_enemy_robot != null else null
			5:  # ALIEN
				return tex_enemy_alien if tex_enemy_alien != null else null
	
	# Fallback: usar wave para determinar (compatibilidade com saves antigos)
	if wave_manager:
		if wave_manager.wave >= 50 and tex_enemy_alien != null:
			return tex_enemy_alien
		elif wave_manager.wave >= 11 and tex_enemy_robot != null:
			return tex_enemy_robot
		elif wave_manager.wave >= 6 and tex_enemy_humanoid != null:
			return tex_enemy_humanoid
	
	return tex_enemy_zombie

func _get_enemy_modulate(enemy: Dictionary) -> Color:
	"""Retorna a cor de modulate do inimigo (efeitos visuais)"""
	var modulate = Color.WHITE
	var enemy_idx = enemy.get("idx", -1)
	var is_dying = enemy.get("dying", false)
	
	# Efeito de noite
	if weather_manager and weather_manager.is_night():
		modulate = Color(0.5, 0.5, 0.6, 0.8)
	
	# Animação de morte
	if is_dying:
		var dying_progress = enemy.get("dying_time", 0.0) / 0.5
		modulate.a = 1.0 - dying_progress
	
	# Efeitos de status
	elif enemy_idx >= 0 and enemy_effects.has(enemy_idx):
		var effects = enemy_effects[enemy_idx]
		if effects.get("freeze_time", 0.0) > 0.0:
			modulate = Color(0.7, 0.9, 1.2, 1.0)  # Azul (congelado)
		elif effects.get("fire_time", 0.0) > 0.0:
			modulate = Color(1.2, 0.7, 0.5, 1.0)  # Laranja (em chamas)
	
	return modulate

func remove_enemy_sprite(enemy_idx: int) -> void:
	"""Remove sprite de um inimigo (quando morre ou sai da tela)"""
	if enemy_sprites.has(enemy_idx):
		return_enemy_sprite(enemy_sprites[enemy_idx])
		enemy_sprites.erase(enemy_idx)
	
	if enemy_shadows.has(enemy_idx):
		return_shadow(enemy_shadows[enemy_idx])
		enemy_shadows.erase(enemy_idx)
	
	if enemy_hp_bars.has(enemy_idx):
		return_hp_bar(enemy_hp_bars[enemy_idx])
		enemy_hp_bars.erase(enemy_idx)

func cleanup() -> void:
	"""Limpa todos os sprites (chamar quando necessário)"""
	for enemy_idx in enemy_sprites.keys():
		remove_enemy_sprite(enemy_idx)
