extends Area2D

# ===== 关卡终点门（区域触发版）=====
@export var next_scene : PackedScene

func _on_body_entered(body):
	if body.is_in_group("Player"):
		GameManager.stop_timer()
		AudioManager.level_complete_sfx.play()

		if next_scene:
			# 切换到下一关
			SceneTransition.load_scene(next_scene)
		else:
			# 最后一关，显示结算画面
			show_completion_screen(body)

func show_completion_screen(player):
	player.hide()
	player.set_process(false)
	player.set_physics_process(false)

	var completion = preload("res://Scenes/UI/CompletionScreen.tscn").instantiate()
	get_tree().current_scene.add_child(completion)
