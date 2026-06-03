extends AnimatedSprite2D

@export var fade_duration := 1.2
@export var initial_scale := Vector2(1.5, 1.5)
@export var scale_up_factor := 1.8

func _ready() -> void:
	_setup_animations()
	
	scale = initial_scale
	modulate.a = 0.8
	
	play("default")
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", initial_scale * scale_up_factor, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(fade_duration * 0.5)
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration * 0.5)
	fade_tween.tween_callback(queue_free)

func _setup_animations() -> void:
	var texture = load("res://assets/sprites/player/smoke.png") as Texture2D
	if texture == null: return
	
	var frames = SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_speed("default", 12.0)
	frames.set_animation_loop("default", false)
	
	var frame_width = 96
	var frame_height = 96
	var frame_count = texture.get_width() / frame_width
	
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("default", atlas)
	
	self.sprite_frames = frames
