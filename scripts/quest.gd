extends Node3D

const SAVE = "user://quest.cfg"
const WORDS = {
 "en": ["Marble Quest 3D", "Sky Crossing • Prototype", "Roll with the pad. Collect 3 orbs, reach the flag.", "Orbs", "Falls", "Time", "Restart", "Brake", "Crossing complete", "Play again", "Checkpoint", "Assets missing", "Best"],
 "ar": ["مغامرة الكرة ثلاثية الأبعاد", "عبور السماء • نموذج تجريبي", "حرّك الكرة باللوحة. اجمع ٣ كرات مضيئة ثم بلغ العلم.", "الكرات", "السقوط", "الوقت", "إعادة", "فرامل", "اكتمل العبور", "العب مجدداً", "نقطة حفظ", "الأصول مفقودة", "الأفضل"],
 "pt": ["Marble Quest 3D", "Travessia Celeste • Protótipo", "Mova a bola pelo controle. Colete 3 orbes e alcance a bandeira.", "Orbes", "Quedas", "Tempo", "Reiniciar", "Freio", "Travessia concluída", "Jogar novamente", "Ponto salvo", "Recursos ausentes", "Melhor"]
}
var lang = "en"
var packed: Dictionary = {}
var ball: RigidBody3D
var camera: Camera3D
var course: Node3D
var pad: Control
var heading: Label
var help: Label
var stats: Label
var result: Label
var restart: Button
var brake: Button
var play_again: Button
var move = Vector2.ZERO
var touch_id = -1
var touch_start = Vector2.ZERO
var spawn = Vector3(0, 1.3, 2)
var count = 0
var falls = 0
var elapsed = 0.0
var best = 0.0
var finished = false
var braking = false
var checkpoint_active = false
var orbs: Array[Area3D] = []
var gate: Area3D
var bridge: AnimatableBody3D
var blocker: AnimatableBody3D
var clock = 0.0

func _ready() -> void:
    read_save()
    make_ui()
    if not FileAccess.file_exists("res://assets/manifest.json"):
        help.text = tr_word(11)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
    if not parsed is Dictionary:
        help.text = tr_word(11)
        return
    for key in ["track", "ball", "tree", "marker", "support"]:
        if not parsed.has(key) or not ResourceLoader.exists(parsed[key]):
            help.text = tr_word(11)
            return
        var resource = load(parsed[key])
        if not resource is PackedScene:
            help.text = tr_word(11)
            return
        packed[key] = resource
    make_environment()
    reset_course()

func tr_word(index: int) -> String:
    return WORDS[lang][index]

func make_environment() -> void:
    var world = WorldEnvironment.new()
    var env = Environment.new()
    var sky = Sky.new()
    var sky_mat = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("354f78")
    sky_mat.sky_horizon_color = Color("b9dfd1")
    sky_mat.ground_bottom_color = Color("384966")
    sky_mat.ground_horizon_color = Color("b9dfd1")
    sky.sky_material = sky_mat
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d5e6f2")
    env.ambient_light_energy = 0.7
    world.environment = env
    add_child(world)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -32, 0)
    sun.light_color = Color("fff1cf")
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)
    camera = Camera3D.new()
    camera.fov = 53
    camera.current = true
    add_child(camera)

func mesh_bounds(node: Node3D, root: Node3D) -> AABB:
    var box = AABB()
    var first = true
    var meshes = node.find_children("*", "MeshInstance3D", true, false)
    if node is MeshInstance3D:
        meshes.push_front(node)
    for part in meshes:
        var local = root.global_transform.affine_inverse() * part.global_transform
        var b: AABB = local * part.get_aabb()
        if first:
            box = b
            first = false
        else:
            box = box.merge(b)
    return box

func model(kind: String, parent: Node3D, size: Vector3, offset: Vector3 = Vector3.ZERO) -> Node3D:
    var wrapper = Node3D.new()
    parent.add_child(wrapper)
    var mesh: Node3D = packed[kind].instantiate()
    wrapper.add_child(mesh)
    var bounds = mesh_bounds(mesh, wrapper)
    if bounds.size.length() < 0.001:
        push_error("Imported model has no mesh: " + kind)
        return wrapper
    var factor = size / Vector3(maxf(bounds.size.x, 0.001), maxf(bounds.size.y, 0.001), maxf(bounds.size.z, 0.001))
    mesh.scale = factor
    mesh.position = -bounds.get_center() * factor + offset
    return wrapper

func collider(parent: CollisionObject3D, size: Vector3, pos: Vector3) -> void:
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = size
    col.shape = shape
    parent.add_child(col)
    col.position = pos

func platform(pos: Vector3, size: Vector3, moving: bool = false) -> Node3D:
    var body: PhysicsBody3D
    if moving:
        body = AnimatableBody3D.new()
    else:
        body = StaticBody3D.new()
    course.add_child(body)
    body.position = pos
    model("track", body, size, Vector3(0, -size.y/2, 0))
    collider(body, Vector3(size.x * 0.95, size.y, size.z), Vector3(0, -size.y/2, 0))
    return body

func decoration(kind: String, pos: Vector3, size: Vector3) -> void:
    var n = Node3D.new()
    course.add_child(n)
    n.position = pos
    model(kind, n, size)

func area_at(pos: Vector3, size: Vector3) -> Area3D:
    var a = Area3D.new()
    course.add_child(a)
    a.position = pos
    a.collision_layer = 0
    a.collision_mask = 2
    collider(a, size, Vector3.ZERO)
    return a

func orb(pos: Vector3) -> void:
    var a = area_at(pos, Vector3(1.1, 1.1, 1.1))
    model("ball", a, Vector3.ONE * 0.48)
    var light = OmniLight3D.new()
    light.light_color = Color("67ffe0")
    light.light_energy = 0.8
    light.omni_range = 2.0
    a.add_child(light)
    a.body_entered.connect(func(body):
        if body == ball and not a.is_queued_for_deletion():
            count += 1
            a.queue_free())
    orbs.append(a)

func reset_course() -> void:
    if course != null:
        remove_child(course)
        course.queue_free()
    course = Node3D.new()
    add_child(course)
    count = 0
    falls = 0
    elapsed = 0
    clock = 0
    finished = false
    checkpoint_active = false
    move = Vector2.ZERO
    braking = false
    spawn = Vector3(0, 1.3, 2)
    orbs.clear()
    result.visible = false
    play_again.visible = false
    platform(Vector3(0,0,0),Vector3(5,0.65,6))
    platform(Vector3(0,0,-5),Vector3(2.8,0.6,4))
    platform(Vector3(0,0,-9),Vector3(6,0.7,4))
    platform(Vector3(-3.55,0,-9),Vector3(2.4,0.65,3))
    bridge = platform(Vector3(0,0,-13),Vector3(3.4,0.55,4.1),true) as AnimatableBody3D
    platform(Vector3(0,0,-17),Vector3(5.4,0.7,4))
    platform(Vector3(0,0,-21),Vector3(3.8,0.7,4))
    platform(Vector3(0,0,-25),Vector3(5.2,0.7,4))
    decoration("tree",Vector3(-1.8,1.1,0),Vector3(1.0,2.2,1.0))
    decoration("tree",Vector3(2.0,1.3,-9),Vector3(1.1,2.6,1.1))
    decoration("tree",Vector3(-1.9,1.1,-25),Vector3(1.1,2.2,1.1))
    for z in [0,-9,-17,-25]:
        decoration("support",Vector3(0,-1.6,z),Vector3(2.2,2.4,2.2))
    decoration("marker",Vector3(1.7,1.25,-17),Vector3(0.7,2.2,0.7))
    decoration("marker",Vector3(1.8,1.5,-25),Vector3(0.9,2.8,0.9))
    orb(Vector3(0,0.7,-4.8))
    orb(Vector3(-3.55,0.7,-9))
    orb(Vector3(0,0.7,-20))
    var cp = area_at(Vector3(0,0.8,-17),Vector3(3,1.6,2))
    cp.body_entered.connect(func(body):
        if body == ball and not checkpoint_active:
            spawn = Vector3(0,1.2,-17)
            checkpoint_active = true)
    blocker = AnimatableBody3D.new()
    course.add_child(blocker)
    blocker.position = Vector3(0,0.6,-22)
    model("support",blocker,Vector3(2.1,0.8,0.55))
    collider(blocker,Vector3(2.1,0.8,0.55),Vector3.ZERO)
    gate = area_at(Vector3(0,0.8,-25),Vector3(3,1.6,2))
    gate.body_entered.connect(func(body):
        if body == ball and count == 3 and not finished:
            finish_course())
    ball = RigidBody3D.new()
    course.add_child(ball)
    ball.position = spawn
    ball.collision_layer = 2
    ball.collision_mask = 1
    ball.mass = 1.2
    ball.continuous_cd = true
    ball.linear_damp = 0.4
    ball.angular_damp = 0.3
    var physics_mat = PhysicsMaterial.new()
    physics_mat.friction = 0.85
    physics_mat.bounce = 0.08
    ball.physics_material_override = physics_mat
    var col = CollisionShape3D.new()
    var sphere = SphereShape3D.new()
    sphere.radius = 0.38
    col.shape = sphere
    ball.add_child(col)
    model("ball",ball,Vector3.ONE * 0.76)
    camera.position = spawn + Vector3(0,8,8)
    camera.look_at(spawn + Vector3(0,0,-3))

func _physics_process(delta: float) -> void:
    if not is_instance_valid(ball) or finished:
        return
    elapsed += delta
    clock += delta
    bridge.position.x = sin(clock * 1.2) * 1.05
    blocker.position.x = sin(clock * 1.8) * 1.4
    var axis = move
    axis += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
    axis = axis.limit_length(1.0)
    ball.apply_central_force(Vector3(axis.x,0,axis.y) * 22.0)
    var horizontal = Vector2(ball.linear_velocity.x,ball.linear_velocity.z)
    if horizontal.length() > 7.5:
        var limited = horizontal.limit_length(7.5)
        ball.linear_velocity = Vector3(limited.x,ball.linear_velocity.y,limited.y)
    ball.linear_damp = 5.0 if braking else 0.4
    ball.angular_damp = 4.0 if braking else 0.3
    if ball.position.y < -5:
        falls += 1
        ball.linear_velocity = Vector3.ZERO
        ball.angular_velocity = Vector3.ZERO
        ball.position = spawn
        ball.reset_physics_interpolation()
    camera.position = camera.position.lerp(ball.position + Vector3(0,8,8),1.0-exp(-delta*5.0))
    camera.look_at(camera.position + Vector3(0,-8,-11))
    for a in orbs:
        if is_instance_valid(a):
            a.rotate_y(delta*1.6)
    stats.text = "%s %d/3  •  %s %d  •  %s %ds" % [tr_word(3),count,tr_word(4),falls,tr_word(5),int(elapsed)]
    if gate.overlaps_body(ball) and count == 3:
        finish_course()

func finish_course() -> void:
    finished = true
    ball.set_deferred("freeze", true)
    move = Vector2.ZERO
    var stars = 3 if falls == 0 else (2 if falls <= 2 else 1)
    if best == 0 or elapsed < best:
        best = elapsed
    write_save()
    result.text = "%s\n%s\n%s %.1fs" % [tr_word(8),"★".repeat(stars)+"☆".repeat(3-stars),tr_word(12),best]
    result.visible = true
    play_again.visible = true

func read_save() -> void:
    var cfg = ConfigFile.new()
    if cfg.load(SAVE) == OK:
        best = float(cfg.get_value("progress","best",0.0))
        var saved = str(cfg.get_value("settings","lang","en"))
        if WORDS.has(saved): lang = saved

func write_save() -> void:
    var cfg = ConfigFile.new()
    cfg.set_value("progress","best",best)
    cfg.set_value("settings","lang",lang)
    cfg.save(SAVE)

func label(parent: Control, text_value: String, font_size: int, rect: Rect2) -> Label:
    var l = Label.new()
    parent.add_child(l)
    l.position = rect.position
    l.size = rect.size
    l.text = text_value
    l.add_theme_font_size_override("font_size",font_size)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

func button(parent: Control, caption: String, rect: Rect2) -> Button:
    var b = Button.new()
    parent.add_child(b)
    b.position = rect.position
    b.size = rect.size
    b.text = caption
    b.add_theme_font_size_override("font_size",23)
    var style = StyleBoxFlat.new()
    style.bg_color = Color("173b4b")
    style.border_color = Color("76d8c7")
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    b.add_theme_stylebox_override("normal",style)
    var pressed_style = style.duplicate()
    pressed_style.bg_color = Color("356a75")
    b.add_theme_stylebox_override("pressed",pressed_style)
    return b

func make_ui() -> void:
    var layer = CanvasLayer.new()
    add_child(layer)
    var ui = Control.new()
    layer.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var top = ColorRect.new()
    ui.add_child(top)
    top.size = Vector2(720,230)
    top.color = Color(0.035,0.09,0.13,0.90)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    heading = label(ui,"",36,Rect2(20,8,680,52))
    help = label(ui,"",22,Rect2(24,62,672,92))
    stats = label(ui,"",25,Rect2(16,160,688,42))
    for i in range(3):
        var code = ["en","ar","pt"][i]
        var b = button(ui,["EN","عربي","PT"][i],Rect2(20+i*88,242,82,55))
        b.pressed.connect(func():
            lang = code
            update_language()
            write_save())
    restart = button(ui,"",Rect2(510,242,190,55))
    restart.pressed.connect(func():
        if is_instance_valid(ball): reset_course())
    pad = Panel.new()
    ui.add_child(pad)
    pad.position = Vector2(28,995)
    pad.size = Vector2(250,250)
    var pad_style = StyleBoxFlat.new()
    pad_style.bg_color = Color(0.06,0.19,0.24,0.75)
    pad_style.border_color = Color("8be3d7")
    pad_style.set_border_width_all(3)
    pad_style.set_corner_radius_all(125)
    pad.add_theme_stylebox_override("panel",pad_style)
    label(pad,"↑\n←  •  →\n↓",44,Rect2(15,15,220,220))
    pad.gui_input.connect(pad_input)
    brake = button(ui,"",Rect2(510,1080,180,135))
    brake.button_down.connect(func(): braking = true)
    brake.button_up.connect(func(): braking = false)
    result = label(ui,"",46,Rect2(30,450,660,210))
    result.add_theme_color_override("font_color",Color("ffe198"))
    result.add_theme_color_override("font_outline_color",Color("173b4b"))
    result.add_theme_constant_override("outline_size",12)
    result.visible = false
    play_again = button(ui,"",Rect2(165,675,390,90))
    play_again.visible = false
    play_again.pressed.connect(func(): reset_course())
    update_language()

func update_language() -> void:
    heading.text = tr_word(0)
    help.text = tr_word(1)+"\n"+tr_word(2)
    restart.text = tr_word(6)
    brake.text = tr_word(7)
    play_again.text = tr_word(9)
    var direction = Control.LAYOUT_DIRECTION_RTL if lang == "ar" else Control.LAYOUT_DIRECTION_LTR
    for c in [heading,help,stats,restart,brake,result,play_again]:
        c.layout_direction = direction

func pad_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and touch_id == -1:
            touch_id = event.index
            touch_start = event.position
        elif not event.pressed and touch_id == event.index:
            touch_id = -1
            move = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        move = ((event.position-touch_start)/75.0).limit_length(1.0)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and touch_id == -1:
            touch_start = event.position
            touch_id = -2
        elif touch_id == -2:
            touch_id = -1
            move = Vector2.ZERO
    elif event is InputEventMouseMotion and touch_id == -2:
        move = ((event.position-touch_start)/75.0).limit_length(1.0)
