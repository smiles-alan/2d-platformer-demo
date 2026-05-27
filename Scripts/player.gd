extends CharacterBody2D

# ===== 玩家属性 =====
@export_category("Player Properties")
@export var move_speed : float = 400         # 移动速度
@export var jump_force : float = 600         # 跳跃力度
@export var gravity : float = 30             # 重力加速度
@export var max_jump_count : int = 2         # 最大跳跃次数
var jump_count : int = 2                     # 当前剩余跳跃次数
var is_dead : bool = false                   # 是否正在死亡流程中

@export_category("Toggle Functions")
@export var double_jump := false             # 是否启用二段跳

@onready var player_sprite = $AnimatedSprite2D    # 玩家动画精灵
@onready var spawn_point = %SpawnPoint            # 重生点
@onready var particle_trails = $ParticleTrails    # 移动拖尾粒子
@onready var death_particles = $DeathParticles    # 死亡粒子效果

func _physics_process(_delta):
	movement()
	player_animations()
	flip_player()

# 物理移动处理
func movement():
	if !is_on_floor():
		velocity.y += gravity             # 空中时施加重力
	elif is_on_floor():
		jump_count = max_jump_count       # 落地重置跳跃次数

	handle_jumping()

	var input_axis = Input.get_axis("Left", "Right")
	velocity = Vector2(input_axis * move_speed, velocity.y)
	move_and_slide()

	# 掉出世界则死亡
	if global_position.y > 1000:
		die()

# 跳跃逻辑处理
func handle_jumping():
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor() and !double_jump:       # 普通跳跃
			jump()
		elif double_jump and jump_count > 0:      # 二段跳
			jump()
			jump_count -= 1

# 执行跳跃
func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

# 玩家动画状态控制
func player_animations():
	particle_trails.emitting = false

	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)   # 行走动画
		else:
			player_sprite.play("Idle")        # 待机动画
	else:
		player_sprite.play("Jump")            # 跳跃动画

# 根据移动方向翻转玩家朝向
func flip_player():
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

# 玩家死亡
func die():
	if is_dead:
		return
	is_dead = true
	AudioManager.death_sfx.play()
	death_particles.emitting = true
	death_tween()

# 死亡动画 -> 重生
func death_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)   # 缩小消失
	await tween.finished
	global_position = spawn_point.global_position              # 回到重生点
	await get_tree().create_timer(0.3).timeout
	AudioManager.respawn_sfx.play()
	is_dead = false
	respawn_tween()

# 重生缩放动画
func respawn_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)    # 恢复原始大小

# 跳跃时的挤压拉伸效果
func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)  # 压扁拉长
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)        # 恢复

# 踩踏敌人后的反弹
func stomp_bounce():
	velocity.y = -jump_force * 0.55

# 碰撞检测：陷阱 / 敌人
func _on_collision_body_entered(body):
	if body.is_in_group("Traps"):
		die()
	elif body.is_in_group("Enemy"):
		# 纯位置判断：玩家碰撞体底部在敌人碰撞体顶部上方时为踩踏（阈值55）
		if global_position.y + 55 < body.global_position.y:
			body.stomp()
			stomp_bounce()
		else:
			die()
