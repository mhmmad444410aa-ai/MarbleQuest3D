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
var menu_open = true
var ui_root: Control
var hud: Control
var menu: Control
var menu_title: Label
var menu_subtitle: Label
var menu_play: Button
var menu_hint: Label
var menu_button: Button
var joystick_knob: Panel
var hud_panel: Panel
var menu_panel: Panel
var language_buttons: Array[Button] = []
var materials: Dictionary = {}
const EXTRA = {
    "en": ["Play", "Sky Crossing", "A floating-island expedition", "Menu", "Choose your language"],
    "ar": ["ابدأ", "عبور السماء", "مغامرة بين الجزر العائمة", "القائمة", "اختر لغتك"],
    "pt": ["Jogar", "Travessia Celeste", "Uma expedição entre ilhas flutuantes", "Menu", "Escolha seu idioma"]
}

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
    set_menu(true)

func tr_word(index: int) -> String:
    return WORDS[lang][index]

func make_environment() -> void:
    var world = WorldEnvironment.new()
    var env = Environment.new()
    var sky = Sky.new()
    var sky_mat = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("7595ad")
    sky_mat.sky_horizon_color = Color("e6e1c8")
    sky_mat.ground_bottom_color = Color("557c89")
    sky_mat.ground_horizon_color = Color("c2d6d4")
    sky.sky_material = sky_mat
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d5e6f2")
    env.ambient_light_energy = 0.42
    world.environment = env
    add_child(world)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -32, 0)
    sun.light_color = Color("fff1cf")
    sun.light_energy = 0.72
    sun.shadow_enabled = true
    add_child(sun)
    camera = Camera3D.new()
    camera.fov = 58
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
    apply_palette(kind, mesh)
    return wrapper

func palette_material(key: String, colour: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    if not materials.has(key):
        var mat = StandardMaterial3D.new()
        mat.albedo_color = colour
        mat.roughness = roughness
        mat.metallic = metallic
        materials[key] = mat
    return materials[key]

func apply_palette(kind: String, root: Node3D) -> void:
    var parts = root.find_children("*", "MeshInstance3D", true, false)
    if root is MeshInstance3D:
        parts.push_front(root)
    var mat: StandardMaterial3D
    match kind:
        "track": mat = palette_material("track", Color("8a856e"), 0.88, 0.0)
        "ball": mat = palette_material("ball", Color("287c88"), 0.19, 0.38)
        "tree": mat = palette_material("tree", Color("416c54"), 0.88, 0.0)
        "marker": mat = palette_material("marker", Color("a34e30"), 0.58, 0.05)
        _: mat = palette_material("support", Color("6a7f79"), 0.86, 0.0)
    for part in parts:
        part.material_override = mat

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
    model("track", body, size, Vector3(0, -size.y*0.5, 0))
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
    var pickup = model("ball", a, Vector3.ONE * 0.48)
    var gold = palette_material("pickup", Color("ffc46b"), 0.27, 0.35)
    gold.emission_enabled = true
    gold.emission = Color("c77927")
    gold.emission_energy_multiplier = 0.45
    for part in pickup.find_children("*", "MeshInstance3D", true, false):
        part.material_override = gold
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
    bridge = platform(Vector3(0,0,-13),Vector3(3.8,0.55,4.35),true) as AnimatableBody3D
    platform(Vector3(0,0,-17),Vector3(5.4,0.7,4.35))
    platform(Vector3(0,0,-21),Vector3(3.8,0.7,4))
    platform(Vector3(0,0,-25),Vector3(5.2,0.7,4))
    decoration("tree",Vector3(-1.8,1.1,0),Vector3(1.0,2.2,1.0))
    decoration("tree",Vector3(2.0,1.3,-9),Vector3(1.1,2.6,1.1))
    decoration("tree",Vector3(-1.9,1.1,-25),Vector3(1.1,2.2,1.1))
    for z in [0,-9,-17,-25]:
        decoration("support",Vector3(0,-1.7,z),Vector3(3.0,2.6,2.6))
        decoration("support",Vector3(0,-3.5,z),Vector3(1.7,1.5,1.5))
    for i in range(6):
        var side = -1.0 if i % 2 == 0 else 1.0
        var island = Vector3(side*(8.0+float(i%3)*2.5), -2.5-float(i%2), -float(i)*5.0)
        decoration("support",island,Vector3(4.2,3.0,3.8))
        decoration("tree",island+Vector3(0,2.6,0),Vector3(1.6,2.4,1.6))
        decoration("tree",island+Vector3(1.0,2.2,0.9),Vector3(0.85,1.5,0.85))
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
    if not is_instance_valid(ball) or finished or menu_open:
        return
    elapsed += delta
    clock += delta
    bridge.position.x = sin(clock * 0.85) * 0.65
    blocker.position.x = sin(clock * 1.8) * 1.4
    var axis = move
    axis += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
    axis = axis.limit_length(1.0)
    ball.apply_central_force(Vector3(axis.x,0,axis.y) * 13.5)
    var horizontal = Vector2(ball.linear_velocity.x,ball.linear_velocity.z)
    if horizontal.length() > 4.7:
        var limited = horizontal.limit_length(4.7)
        ball.linear_velocity = Vector3(limited.x,ball.linear_velocity.y,limited.y)
    ball.linear_damp = 5.0 if braking else (1.6 if axis.length() < 0.08 else 0.45)
    ball.angular_damp = 4.0 if braking else 0.4
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
    if is_instance_valid(joystick_knob):
        joystick_knob.position = (pad.size - joystick_knob.size) * 0.5 + move * 54.0
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
    l.size = Vector2(maxf(rect.size.x,1.0),maxf(rect.size.y,1.0))
    l.text = text_value
    l.add_theme_font_size_override("font_size",font_size)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    l.clip_text = true
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
    style.bg_color = Color("183c40")
    style.border_color = Color("c1ac78")
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    b.add_theme_stylebox_override("normal",style)
    var pressed_style = style.duplicate()
    pressed_style.bg_color = Color("356a75")
    b.add_theme_stylebox_override("pressed",pressed_style)
    b.add_theme_stylebox_override("hover",pressed_style)
    b.layout_direction = Control.LAYOUT_DIRECTION_LTR
    return b

func panel_style(bg: Color, line: Color, radius: int) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = line
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    return style

func make_ui() -> void:
    var layer = CanvasLayer.new()
    add_child(layer)
    ui_root = Control.new()
    ui_root.layout_direction = Control.LAYOUT_DIRECTION_LTR
    layer.add_child(ui_root)
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud = Control.new()
    ui_root.add_child(hud)
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_panel = Panel.new()
    hud.add_child(hud_panel)
    hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_panel.add_theme_stylebox_override("panel",panel_style(Color(0.06,0.15,0.17,0.89),Color("c1ac78"),22))
    heading = label(hud,"",34,Rect2())
    help = label(hud,"",24,Rect2())
    stats = label(hud,"",28,Rect2())
    help.add_theme_color_override("font_color",Color("b5d3cd"))
    heading.add_theme_color_override("font_color",Color("ffe4ae"))
    restart = button(hud,"",Rect2())
    restart.pressed.connect(func():
        if is_instance_valid(ball): reset_course())
    menu_button = button(hud,"",Rect2())
    menu_button.pressed.connect(func(): set_menu(true))
    pad = Panel.new()
    hud.add_child(pad)
    pad.add_theme_stylebox_override("panel",panel_style(Color(0.06,0.18,0.2,0.68),Color("d5c392"),125))
    joystick_knob = Panel.new()
    pad.add_child(joystick_knob)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_knob.size = Vector2(78,78)
    joystick_knob.add_theme_stylebox_override("panel",panel_style(Color("d5c392"),Color("fff1c9"),39))
    pad.gui_input.connect(pad_input)
    brake = button(hud,"",Rect2())
    brake.button_down.connect(func(): braking = true)
    brake.button_up.connect(func(): braking = false)
    result = label(hud,"",40,Rect2())
    result.max_lines_visible = 3
    result.add_theme_color_override("font_color",Color("ffe198"))
    result.add_theme_color_override("font_outline_color",Color("173b4b"))
    result.add_theme_constant_override("outline_size",8)
    result.visible = false
    play_again = button(hud,"",Rect2())
    play_again.visible = false
    play_again.pressed.connect(func(): reset_course())
    menu = Control.new()
    ui_root.add_child(menu)
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu_panel = Panel.new()
    menu.add_child(menu_panel)
    menu_panel.add_theme_stylebox_override("panel",panel_style(Color(0.06,0.14,0.16,0.94),Color("c1ac78"),32))
    menu_title = label(menu,"",38,Rect2())
    menu_title.add_theme_color_override("font_color",Color("ffe4ae"))
    menu_subtitle = label(menu,"",29,Rect2())
    menu_hint = label(menu,"",25,Rect2())
    menu_play = button(menu,"",Rect2())
    menu_play.add_theme_font_size_override("font_size",32)
    menu_play.pressed.connect(func():
        if is_instance_valid(ball): set_menu(false))
    for i in range(3):
        var code = ["en","ar","pt"][i]
        var b = button(menu,["EN","العربية","PT-BR"][i],Rect2())
        language_buttons.append(b)
        b.pressed.connect(func():
            lang = code
            update_language()
            write_save())
    ui_root.resized.connect(layout_ui)
    update_language()
    layout_ui()
    set_menu(true)

func place(c: Control, x: float, y: float, w: float, h: float) -> void:
    c.position = Vector2(x,y)
    c.size = Vector2(w,h)

func layout_ui() -> void:
    if not is_instance_valid(menu_panel): return
    var w = ui_root.size.x
    var h = ui_root.size.y
    if w < 320 or h < 500: return
    var cx = w * 0.5
    var pw = minf(w-36,680)
    place(hud_panel,18,20,w-36,176)
    place(heading,32,27,w-64,52)
    place(stats,32,82,w-64,49)
    place(help,32,134,w-64,48)
    place(restart,20,208,164,66)
    place(menu_button,w-184,208,164,66)
    place(pad,28,h-278,232,232)
    place(joystick_knob,77,77,78,78)
    place(brake,w-204,h-185,176,130)
    place(result,24,h*0.38,w-48,190)
    place(play_again,cx-160,h*0.38+200,320,76)
    var y = minf(h*0.37,h-460)
    place(menu_panel,cx-pw*0.5,y,pw,420)
    place(menu_title,cx-pw*0.5+16,y+22,pw-32,104)
    place(menu_subtitle,cx-pw*0.5+16,y+132,pw-32,64)
    place(menu_play,cx-pw*0.5+32,y+209,pw-64,86)
    place(menu_hint,cx-pw*0.5+16,y+308,pw-32,38)
    var bw = (pw-76)/3.0
    for i in range(language_buttons.size()):
        place(language_buttons[i],cx-pw*0.5+24+i*(bw+14),y+352,bw,48)

func set_menu(open: bool) -> void:
    menu_open = open
    hud.visible = not open
    menu.visible = open
    move = Vector2.ZERO
    touch_id = -1
    braking = false
    if is_instance_valid(ball):
        ball.freeze = open or finished

func update_language() -> void:
    heading.text = EXTRA[lang][1]
    help.text = {"en":"Collect 3 orbs, reach the flag.","ar":"اجمع ٣ كرات ثم بلغ العلم.","pt":"Colete 3 orbes e alcance a bandeira."}[lang]
    restart.text = tr_word(6)
    brake.text = tr_word(7)
    play_again.text = tr_word(9)
    menu_title.text = {"en":"Marble Quest 3D","ar":"مغامرة الكرة 3D","pt":"Marble Quest 3D"}[lang]
    menu_subtitle.text = EXTRA[lang][2]
    menu_play.text = EXTRA[lang][0]
    menu_hint.text = EXTRA[lang][4]
    menu_button.text = EXTRA[lang][3]
    # Keep control geometry LTR so OS locale cannot mirror overlapping absolute positions.
    # Godot's text shaping still handles Arabic bidirectional text automatically.
    for c in [heading,help,stats,restart,brake,result,play_again,menu_title,menu_subtitle,menu_play,menu_hint,menu_button]:
        c.layout_direction = Control.LAYOUT_DIRECTION_LTR
    layout_ui.call_deferred()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
        touch_id = -1
        move = Vector2.ZERO
    elif event is InputEventMouseButton and not event.pressed and touch_id == -2:
        touch_id = -1
        move = Vector2.ZERO

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
