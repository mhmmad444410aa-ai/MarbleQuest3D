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
var lives = 3
var coins = 0
var owned: Array[int] = [0]
var equipped = 0
var quality = 1
var sun_light: DirectionalLight3D
var vibration = false
var won = false
var screen = "main"
var settings_return = "main"
var home_needs_reset = false
var pages: Dictionary = {}
var page_panels: Dictionary = {}
var page_titles: Dictionary = {}
var actions: Dictionary = {}
var shop_buttons: Array[Button] = []
var shop_labels: Array[Label] = []
var shop_swatches: Array[TextureRect] = []
var life_icons: Array[TextureRect] = []
var life_label: Label
var balance_label: Label
var main_balance: Label
var result_home: Button
var quality_button: Button
var vibration_button: Button
var ui_textures: Dictionary = {}
const PRICES = [0,60,120,200,240,280,320,360,400,440,480,520]
const SKINS = [Color("287c88"),Color("ce983b"),Color("885ac7"),Color("e1e7ef"),Color("bd3449"),Color("355bb8"),Color("168e64"),Color("242c3b"),Color("a0b7d7"),Color("b66f42"),Color("e6d5c2"),Color("674b9b")]
const SKIN_NAMES = {
 "en":["Jade","Golden","Amethyst","Frost","Ruby","Sapphire","Emerald","Obsidian","Crystal","Copper","Marble","Galaxy"],
 "ar":["اليشم","الذهبية","الجمشت","الصقيع","الياقوت","الزفير","الزمرد","السبج","البلور","النحاس","الرخام","المجرة"],
 "pt":["Jade","Dourada","Ametista","Gelo","Rubi","Safira","Esmeralda","Obsidiana","Cristal","Cobre","Mármore","Galáxia"]
}
const MORE = {
 "en":["LEVELS","ACHIEVEMENTS","SOUND","VOLUME","SENSITIVITY","FRAME RATE","RESET SETTINGS","PRIVACY & ABOUT","Offline game. Saves stay on this device. No ads or accounts in this build.","Courses completed","Best time","Preview","Next","Previous","Sky Crossing","First victory","Coins earned","Not yet unlocked"],
 "ar":["المراحل","الإنجازات","الصوت","مستوى الصوت","الحساسية","معدل الإطارات","استعادة الإعدادات","الخصوصية وحول اللعبة","لعبة دون إنترنت. الحفظ على جهازك. لا إعلانات أو حسابات في هذه النسخة.","المراحل المكتملة","أفضل وقت","معاينة","التالي","السابق","عبور السماء","الفوز الأول","النقاط المكتسبة","لم تُفتح بعد"],
 "pt":["FASES","CONQUISTAS","SOM","VOLUME","SENSIBILIDADE","QUADROS POR SEGUNDO","RESTAURAR AJUSTES","PRIVACIDADE E SOBRE","Jogo offline. Dados no dispositivo. Sem anúncios ou contas nesta versão.","Fases concluídas","Melhor tempo","Prévia","Próxima","Anterior","Travessia Celeste","Primeira vitória","Pontos ganhos","Ainda bloqueada"]
}
var sound_on = true
var sound_volume = 0.7
var sensitivity = 1.0
var fps = 60
var victories = 0
var earned_total = 0
var preview_index = 0
var preview_box: SubViewportContainer
var preview_world: SubViewport
var preview_mesh: Node3D
var preview_caption: Label
var achievement_text: Label
var info_text: Label
var audio_player: AudioStreamPlayer
var brake_touch = -1
var respawn_guard = 0.0
var visual_clock = 0.0
var ball_visual: Node3D
var last_velocity = Vector3.ZERO
var last_spin = Vector3.ZERO
var pause_snapshot = false
const UI_WORDS = {
    "en": ["PLAY","MARBLE SHOP","SETTINGS","PAUSED","RESUME","MAIN MENU","BACK","ATTEMPTS","OUT OF ATTEMPTS","TRY AGAIN","POINTS","EQUIP","EQUIPPED","UNLOCK","NOT ENOUGH POINTS","GRAPHICS","LOW","MEDIUM","HIGH","VIBRATION","ON","OFF","LANGUAGE","Jade","Amber","Amethyst","Pearl","Earn points by completing a course.","SKY CROSSING","BRAKE","RESTART"],
    "ar": ["ابدأ اللعب","متجر الكرات","الإعدادات","توقف مؤقت","متابعة","القائمة الرئيسية","رجوع","المحاولات","نفدت المحاولات","حاول مجدداً","النقاط","اختيار","مجهزة","فتح","النقاط غير كافية","الرسومات","منخفضة","متوسطة","عالية","الاهتزاز","تشغيل","إيقاف","اللغة","اليشم","الكهرمان","الجمشت","اللؤلؤ","اكسب النقاط بإكمال المرحلة.","عبور السماء","فرامل","إعادة"],
    "pt": ["JOGAR","LOJA DE BOLAS","CONFIGURAÇÕES","PAUSADO","CONTINUAR","MENU PRINCIPAL","VOLTAR","TENTATIVAS","SEM TENTATIVAS","TENTAR NOVAMENTE","PONTOS","EQUIPAR","EQUIPADA","DESBLOQUEAR","PONTOS INSUFICIENTES","GRÁFICOS","BAIXA","MÉDIA","ALTA","VIBRAÇÃO","LIGADA","DESLIGADA","IDIOMA","Jade","Âmbar","Ametista","Pérola","Ganhe pontos ao concluir a fase.","TRAVESSIA CELESTE","FREIO","REINICIAR"]
}
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
    for key in ["track", "ball", "tree", "marker", "support", "cliff", "waterfall", "rock", "bridge_wood", "grass", "flower", "forest_tree", "forest_tree_alt", "forest_bush"]:
        if not parsed.has(key) or not ResourceLoader.exists(parsed[key]):
            help.text = tr_word(11)
            return
        var resource = load(parsed[key])
        if not resource is PackedScene:
            help.text = tr_word(11)
            return
        packed[key] = resource
    make_environment()
    setup_preview()
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
    sun_light = sun
    add_child(sun)
    apply_quality()
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
    if kind in ["track", "ball", "tree", "marker", "support"]:
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
    lives = 3
    respawn_guard = 0.0
    pause_snapshot = false
    won = false
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
    result_home.visible = false
    pad.visible = true
    brake.visible = true
    refresh_lives()
    platform(Vector3(0,0,0),Vector3(5,0.65,6))
    platform(Vector3(0,0,-5),Vector3(2.8,0.6,4))
    platform(Vector3(0,0,-9),Vector3(6,0.7,4))
    platform(Vector3(-3.55,0,-9),Vector3(2.4,0.65,3))
    bridge = platform(Vector3(0,0,-13),Vector3(3.8,0.55,4.35),true) as AnimatableBody3D
    platform(Vector3(0,0,-17),Vector3(5.4,0.7,4.35))
    platform(Vector3(0,0,-21),Vector3(3.8,0.7,4))
    platform(Vector3(0,0,-25),Vector3(5.2,0.7,4))
    island_landscape()
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
    ball_visual = model("ball",ball,Vector3.ONE * 0.76)
    apply_skin()
    camera.position = spawn + Vector3(0,8,8)
    camera.look_at(spawn + Vector3(0,0,-3))

# Imported environmental meshes remain visual only: the proven course
# collision shapes are unchanged. No generated primitive scenery.
func island_landscape() -> void:
    var islands = [
        [Vector3(0,-1.9,0),Vector3(5.6,3.0,6.4)],
        [Vector3(0,-2.3,-9),Vector3(7.0,3.8,4.6)],
        [Vector3(-3.55,-1.7,-9),Vector3(2.7,2.8,3.2)],
        [Vector3(0,-2.1,-17),Vector3(6.1,3.4,4.6)],
        [Vector3(0,-2.2,-25),Vector3(6.0,3.6,4.5)]
    ]
    for entry in islands:
        var centre: Vector3 = entry[0]
        var extent: Vector3 = entry[1]
        decoration("cliff",centre,extent)
        decoration("rock",centre+Vector3(0,-extent.y*0.48,0),extent*0.60)
        decoration("rock",centre+Vector3(extent.x*0.37,-0.4,0.4),extent*0.33)
    # Border foliage, deliberately off the path of the marble.
    for v in [Vector3(-2.1,0,0.6),Vector3(2.5,0,-9.8),Vector3(-2.15,0,-17.2),Vector3(-2.15,0,-25.2)]:
        decoration("forest_tree",v+Vector3(0,1.55,0),Vector3(1.8,3.1,1.8))
        decoration("forest_bush",v+Vector3(0.28,0.33,0.55),Vector3(0.85,0.66,0.8))
        decoration("flower",v+Vector3(0.38,0.17,-0.65),Vector3(0.35,0.34,0.35))
        decoration("grass",v+Vector3(-0.2,0.15,0.75),Vector3(0.4,0.30,0.4))
    # Distinct floating landmarks beside the route.
    for i in range(6):
        var side = -1.0 if i % 2 == 0 else 1.0
        var centre = Vector3(side*(7.4+float(i%3)*1.5),-2.4-float(i%2)*0.7,-float(i)*5.0)
        var extent = Vector3(4.5+float(i%2),3.8,4.3)
        decoration("cliff",centre,extent)
        decoration("rock",centre+Vector3(0,-2.4,0),Vector3(2.6,2.0,2.4))
        decoration("forest_tree_alt",centre+Vector3(-0.7,3.1,0),Vector3(2.2,3.8,2.1))
        decoration("forest_tree",centre+Vector3(0.9,2.7,0.45),Vector3(1.6,2.8,1.5))
        decoration("forest_bush",centre+Vector3(0.1,2.3,1.0),Vector3(1.0,0.7,1.0))
    decoration("waterfall",Vector3(-3.9,-3.1,-17),Vector3(2.3,5.0,2.5))
    decoration("waterfall",Vector3(7.3,-4.0,-7),Vector3(3.0,6.5,3.0))
    # Actual imported bridge model on a background island, not a collider.
    decoration("bridge_wood",Vector3(8.1,-0.6,-15),Vector3(1.8,0.6,3.5))

func _physics_process(delta: float) -> void:
    if not is_instance_valid(ball) or finished or menu_open:
        return
    elapsed += delta
    clock += delta
    respawn_guard = maxf(0.0,respawn_guard-delta)
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
    if ball.position.y < -5 and respawn_guard <= 0.0:
        lose_attempt()
        if finished: return
    camera.position = camera.position.lerp(ball.position + Vector3(0,8,8),1.0-exp(-delta*5.0))
    camera.look_at(camera.position + Vector3(0,-8,-11))
    for a in orbs:
        if is_instance_valid(a):
            a.rotate_y(delta*1.6)
    stats.text = "%s %d/3   •   %s %ds   •   ◈ %d" % [tr_word(3),count,tr_word(5),int(elapsed),coins]
    if gate.overlaps_body(ball) and count == 3:
        finish_course()

func finish_course() -> void:
    if finished: return
    finished = true
    won = true
    ball.set_deferred("freeze", true)
    move = Vector2.ZERO
    var stars = lives
    coins += stars * 35
    earned_total += stars * 35
    victories += 1
    play_ui_sound()
    if best == 0 or elapsed < best:
        best = elapsed
    write_save()
    result.text = "%s\n%s   •   +%d ◈\n%s %.1fs   •   %d/3" % [tr_word(8),"★".repeat(stars)+"☆".repeat(3-stars),stars*35,tr_word(5),elapsed,count]
    show_result()

func lose_attempt() -> void:
    if finished or menu_open or respawn_guard > 0.0: return
    respawn_guard = 0.75
    falls += 1
    play_ui_sound()
    lives = maxi(0,lives-1)
    refresh_lives()
    move = Vector2.ZERO
    touch_id = -1
    braking = false
    if vibration and OS.has_feature("mobile"):
        Input.vibrate_handheld(100)
    ball.linear_velocity = Vector3.ZERO
    ball.angular_velocity = Vector3.ZERO
    if lives == 0:
        finished = true
        won = false
        ball.set_deferred("freeze",true)
        result.text = "%s\n%s %d/3" % [word(8),tr_word(3),count]
        show_result()
    else:
        ball.position = spawn
        ball.reset_physics_interpolation()

func show_result() -> void:
    result.visible = true
    play_again.visible = true
    result_home.visible = true
    pad.visible = false
    brake.visible = false
    refresh_shop()

func apply_skin() -> void:
    if not is_instance_valid(ball): return
    var mat = skin_material(equipped)
    for part in ball.find_children("*","MeshInstance3D",true,false):
        part.material_override = mat

func skin_material(index: int) -> StandardMaterial3D:
    var mat = palette_material("skin_"+str(index),SKINS[index], [0.23,0.18,0.26,0.33,0.20,0.20,0.22,0.13,0.12,0.38,0.56,0.18][index], [0.28,0.82,0.34,0.1,0.32,0.4,0.25,0.65,0.1,0.8,0.06,0.45][index])
    mat.rim_enabled = true
    mat.rim = 0.35
    if index == 8 or index == 11:
        mat.emission_enabled = true
        mat.emission = SKINS[index]
        mat.emission_energy_multiplier = 0.18
    return mat

func buy_or_equip(index: int) -> void:
    if index < 0 or index >= PRICES.size(): return
    if not owned.has(index):
        if coins < PRICES[index]: return
        coins -= PRICES[index]
        owned.append(index)
    equipped = index
    apply_skin()
    write_save()
    refresh_shop()

func apply_quality() -> void:
    if is_instance_valid(sun_light):
        sun_light.shadow_enabled = quality > 0
        sun_light.directional_shadow_max_distance = 24.0 if quality == 1 else 48.0
    get_viewport().scaling_3d_scale = [0.75,0.9,1.0][quality]

func read_save() -> void:
    var cfg = ConfigFile.new()
    if cfg.load(SAVE) == OK:
        best = float(cfg.get_value("progress","best",0.0))
        var saved = str(cfg.get_value("settings","lang","en"))
        if WORDS.has(saved): lang = saved
        coins = maxi(0,int(cfg.get_value("progress","coins",0)))
        var saved_owned = cfg.get_value("progress","owned",[0])
        if not saved_owned is Array: saved_owned = [0]
        for id in saved_owned:
            if int(id) >= 0 and int(id) < PRICES.size() and not owned.has(int(id)):
                owned.append(int(id))
        equipped = int(cfg.get_value("progress","equipped",0))
        if not owned.has(equipped): equipped = 0
        quality = clampi(int(cfg.get_value("settings","quality",1)),0,2)
        vibration = bool(cfg.get_value("settings","vibration",false))
        sound_on = bool(cfg.get_value("settings","sound_on",true))
        sound_volume = clampf(float(cfg.get_value("settings","volume",0.7)),0.0,1.0)
        sensitivity = clampf(float(cfg.get_value("settings","sensitivity",1.0)),0.5,1.5)
        fps = 30 if int(cfg.get_value("settings","fps",60)) == 30 else 60
        victories = maxi(0,int(cfg.get_value("progress","victories",0)))
        earned_total = maxi(0,int(cfg.get_value("progress","earned_total",0)))

func write_save() -> void:
    var cfg = ConfigFile.new()
    cfg.set_value("progress","best",best)
    cfg.set_value("settings","lang",lang)
    cfg.set_value("progress","coins",coins)
    cfg.set_value("progress","owned",owned)
    cfg.set_value("progress","equipped",equipped)
    cfg.set_value("settings","quality",quality)
    cfg.set_value("settings","vibration",vibration)
    cfg.set_value("settings","sound_on",sound_on)
    cfg.set_value("settings","volume",sound_volume)
    cfg.set_value("settings","sensitivity",sensitivity)
    cfg.set_value("settings","fps",fps)
    cfg.set_value("progress","victories",victories)
    cfg.set_value("progress","earned_total",earned_total)
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

func word(index: int) -> String:
    return UI_WORDS[lang][index]

func tex(key: String) -> Texture2D:
    if not ui_textures.has(key):
        var path = "res://assets/ui/" + key + ".png"
        if ResourceLoader.exists(path):
            ui_textures[key] = load(path)
    return ui_textures.get(key) as Texture2D

func texture_style(key: String, round_button: bool = false) -> StyleBox:
    var image = tex(key)
    if image == null:
        return panel_style(Color("245d60"),Color("c1ac78"),22)
    var style = StyleBoxTexture.new()
    style.texture = image
    if not round_button:
        var edge = minf(16.0,minf(image.get_width(),image.get_height())/4.0)
        for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
            style.set_texture_margin(side,edge)
            style.set_content_margin(side,10.0)
    return style

func button(parent: Control, caption: String, rect: Rect2) -> Button:
    var b = Button.new()
    parent.add_child(b)
    b.position = rect.position
    b.size = rect.size
    b.text = caption
    b.add_theme_font_size_override("font_size",26)
    b.add_theme_color_override("font_color",Color.WHITE)
    b.add_theme_color_override("font_hover_color",Color.WHITE)
    b.add_theme_color_override("font_pressed_color",Color.WHITE)
    b.add_theme_color_override("font_disabled_color",Color("d1dad6"))
    b.add_theme_constant_override("icon_max_width",35)
    b.add_theme_constant_override("h_separation",12)
    b.layout_direction = Control.LAYOUT_DIRECTION_LTR
    skin_button(b,"green")
    b.pressed.connect(play_ui_sound)
    return b

func skin_button(b: Button, theme_name: String, round_button: bool = false) -> void:
    var name = theme_name + ("_round" if round_button else "_rect")
    b.add_theme_stylebox_override("normal",texture_style(name,round_button))
    b.add_theme_stylebox_override("hover",texture_style(name,round_button))
    b.add_theme_stylebox_override("pressed",texture_style("grey"+("_round" if round_button else "_rect"),round_button))
    b.add_theme_stylebox_override("disabled",texture_style("grey"+("_round" if round_button else "_rect"),round_button))
    b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())

func panel_style(bg: Color, line: Color, radius: int) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = line
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0.02,0.08,0.09,0.35)
    style.shadow_size = 6
    style.shadow_offset = Vector2(0,4)
    return style

func make_page(key: String) -> Control:
    var page = Control.new()
    ui_root.add_child(page)
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var panel = Panel.new()
    page.add_child(panel)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel",panel_style(Color(0.045,0.12,0.14,0.96),Color("bca778"),30))
    pages[key] = page
    page_panels[key] = panel
    var title = label(page,"",38,Rect2())
    title.add_theme_color_override("font_color",Color("ffe4ae"))
    page_titles[key] = title
    return page

func action(parent: Control, key: String, icon_name: String, callback: Callable, colour: String = "green") -> Button:
    var b = button(parent,"",Rect2())
    b.icon = tex(icon_name)
    skin_button(b,colour)
    b.pressed.connect(callback)
    actions[key] = b
    return b

func make_ui() -> void:
    audio_player = AudioStreamPlayer.new()
    add_child(audio_player)
    if ResourceLoader.exists("res://assets/ui/click.wav"):
        audio_player.stream = load("res://assets/ui/click.wav")
    Engine.max_fps = fps
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
    hud_panel.add_theme_stylebox_override("panel",panel_style(Color(0.06,0.15,0.17,0.89),Color("c1ac78"),24))
    heading = label(hud,"",32,Rect2())
    help = label(hud,"",22,Rect2())
    stats = label(hud,"",26,Rect2())
    life_label = label(hud,"",22,Rect2())
    heading.add_theme_color_override("font_color",Color("ffe4ae"))
    for i in range(3):
        var dot = TextureRect.new()
        hud.add_child(dot)
        dot.texture = tex("green_round")
        dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        life_icons.append(dot)
    restart = button(hud,"",Rect2())
    restart.icon = tex("repeat")
    skin_button(restart,"grey",true)
    restart.pressed.connect(func():
        if is_instance_valid(ball): reset_course())
    menu_button = button(hud,"",Rect2())
    menu_button.icon = tex("pause")
    skin_button(menu_button,"green",true)
    menu_button.pressed.connect(func(): show_screen("pause"))
    pad = Panel.new()
    hud.add_child(pad)
    pad.add_theme_stylebox_override("panel",texture_style("grey_round",true))
    pad.modulate = Color(0.65,0.88,0.89,0.90)
    joystick_knob = Panel.new()
    pad.add_child(joystick_knob)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_knob.size = Vector2(78,78)
    joystick_knob.add_theme_stylebox_override("panel",texture_style("green_round",true))
    pad.gui_input.connect(pad_input)
    brake = button(hud,"",Rect2())
    brake.icon = tex("stop")
    skin_button(brake,"red",true)
    brake.button_down.connect(func(): braking = true; play_ui_sound())
    brake.button_up.connect(func(): braking = brake_touch >= 0)
    result = label(hud,"",36,Rect2())
    result.max_lines_visible = 3
    result.add_theme_color_override("font_color",Color("ffe198"))
    result.add_theme_color_override("font_outline_color",Color("173b4b"))
    result.add_theme_constant_override("outline_size",8)
    result.visible = false
    play_again = action(hud,"retry","repeat",func(): reset_course())
    play_again.visible = false
    result_home = action(hud,"result_home","home",func(): go_home(),"grey")
    result_home.visible = false

    menu = make_page("main")
    menu_panel = page_panels["main"]
    menu_title = page_titles["main"]
    menu_subtitle = label(menu,"",28,Rect2())
    menu_hint = label(menu,"",20,Rect2())
    main_balance = label(menu,"",25,Rect2())
    menu_play = action(menu,"play","play",func():
        if is_instance_valid(ball):
            if home_needs_reset or finished: reset_course()
            home_needs_reset = false
            show_screen("play"))
    action(menu,"shop","shop",func(): show_screen("shop"),"grey")
    action(menu,"settings","gear",func():
        settings_return = "main"
        show_screen("settings"),"grey")
    action(menu,"levels","play",func(): show_screen("levels"),"grey")
    action(menu,"achievements","check",func(): show_screen("achievements"),"grey")

    var store = make_page("shop")
    balance_label = label(store,"",29,Rect2())
    preview_caption = label(store,"",32,Rect2())
    preview_box = SubViewportContainer.new()
    store.add_child(preview_box)
    preview_box.stretch = true
    preview_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_world = SubViewport.new()
    preview_world.own_world_3d = true
    preview_world.transparent_bg = true
    preview_world.render_target_update_mode = SubViewport.UPDATE_DISABLED
    preview_box.add_child(preview_world)
    action(store,"previous","back",func(): select_preview(-1),"grey")
    action(store,"next","play",func(): select_preview(1),"grey")
    for i in range(PRICES.size()):
        var swatch = TextureRect.new()
        store.add_child(swatch)
        swatch.texture = tex("white_round")
        swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        swatch.modulate = SKINS[i]
        swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
        shop_swatches.append(swatch)
        var item = label(store,"",27,Rect2())
        shop_labels.append(item)
        var purchase = button(store,"",Rect2())
        purchase.pressed.connect(func(): buy_or_equip(i))
        shop_buttons.append(purchase)
    action(store,"shop_back","back",func(): show_screen("main"),"grey")

    var settings = make_page("settings")
    actions["language_title"] = button(settings,"",Rect2())
    actions["language_title"].disabled = true
    for i in range(3):
        var code = ["en","ar","pt"][i]
        var b = button(settings,["EN","العربية","PT-BR"][i],Rect2())
        language_buttons.append(b)
        b.pressed.connect(func():
            lang = code
            update_language()
            write_save())
    quality_button = action(settings,"quality","gear",func():
        quality = (quality+1)%3
        apply_quality()
        update_language()
        write_save(),"grey")
    vibration_button = action(settings,"vibration","gamepad",func():
        vibration = not vibration
        update_language()
        write_save(),"grey")
    action(settings,"sound","gamepad",func(): sound_on = not sound_on; save_settings(),"grey")
    action(settings,"volume","gamepad",func(): sound_volume = fmod(sound_volume+0.25,1.25); save_settings(),"grey")
    action(settings,"sensitivity","gamepad",func(): sensitivity = 0.5 if sensitivity >= 1.5 else sensitivity+0.25; save_settings(),"grey")
    action(settings,"fps","gear",func(): fps = 30 if fps == 60 else 60; save_settings(),"grey")
    action(settings,"defaults","repeat",func(): restore_settings(),"grey")
    action(settings,"about","gear",func(): show_screen("about"),"grey")
    action(settings,"settings_back","back",func(): show_screen(settings_return),"grey")
    var levels = make_page("levels")
    action(levels,"level_one","play",func(): reset_course(); show_screen("play"))
    action(levels,"levels_back","back",func(): show_screen("main"),"grey")
    var achievements = make_page("achievements")
    achievement_text = label(achievements,"",28,Rect2())
    achievement_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    action(achievements,"achievements_back","back",func(): show_screen("main"),"grey")
    var about = make_page("about")
    info_text = label(about,"",26,Rect2())
    info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    action(about,"about_back","back",func(): show_screen("settings"),"grey")

    var paused = make_page("pause")
    action(paused,"resume","play",func(): show_screen("play"))
    action(paused,"pause_restart","repeat",func():
        reset_course()
        show_screen("play"),"grey")
    action(paused,"pause_settings","gear",func():
        settings_return = "pause"
        show_screen("settings"),"grey")
    action(paused,"pause_home","home",func(): go_home(),"grey")
    ui_root.resized.connect(layout_ui)
    update_language()
    layout_ui()
    show_screen("main")

func place(c: Control, x: float, y: float, w: float, h: float) -> void:
    c.position = Vector2(x,y)
    c.size = Vector2(w,h)

func layout_ui() -> void:
    if not is_instance_valid(menu_panel): return
    var w = ui_root.size.x
    var h = ui_root.size.y
    if w < 320 or h < 500: return
    var cx = w*0.5
    var pw = minf(w-40,620)
    var px = cx-pw*0.5
    var bw = pw-48
    var bx = px+24
    place(hud_panel,18,20,w-36,190)
    place(heading,30,26,w-60,48)
    place(stats,30,78,w-60,40)
    place(help,30,122,w-60,36)
    place(life_label,cx-180,165,155,32)
    for i in range(3):
        place(life_icons[i],cx-18+i*45,161,38,38)
    place(restart,24,225,72,72)
    place(menu_button,w-96,225,72,72)
    place(pad,28,h-278,232,232)
    place(joystick_knob,77,77,78,78)
    place(brake,w-190,h-202,160,160)
    place(result,24,h*0.35,w-48,185)
    place(play_again,cx-160,h*0.35+190,320,80)
    place(result_home,cx-160,h*0.35+282,320,74)
    var mh = 710.0
    var my = clampf(h*0.23,24,h-mh-24)
    place(menu_panel,px,my,pw,mh)
    place(menu_title,px+12,my+20,pw-24,70)
    place(menu_subtitle,px+16,my+92,pw-32,50)
    place(main_balance,bx,my+144,bw,45)
    place(menu_play,bx,my+205,bw,100)
    place(actions["shop"],bx,my+320,bw,82)
    place(actions["settings"],bx,my+416,bw,82)
    place(actions["levels"],bx,my+510,bw*0.49,80)
    place(actions["achievements"],bx+bw*0.51,my+510,bw*0.49,80)
    place(menu_hint,bx,my+616,bw,40)

    var sh = 690.0
    var sy = maxf(20,(h-sh)*0.5)
    place(page_panels["shop"],px,sy,pw,sh)
    place(page_titles["shop"],px+10,sy+15,pw-20,60)
    place(balance_label,bx,sy+78,bw,48)
    place(preview_box,px+pw*0.15,sy+135,pw*0.70,280)
    place(preview_caption,bx,sy+414,bw,60)
    place(actions["previous"],bx,sy+230,68,68)
    place(actions["next"],bx+bw-68,sy+230,68,68)
    for i in range(PRICES.size()):
        place(shop_buttons[i],bx,sy+496,bw,86)
    place(actions["shop_back"],bx,sy+603,bw,65)

    var dh = 930.0
    var dy = maxf(20,(h-dh)*0.5)
    place(page_panels["settings"],px,dy,pw,dh)
    place(page_titles["settings"],px+10,dy+15,pw-20,68)
    place(actions["language_title"],bx,dy+94,bw,54)
    var lw = (bw-24)/3.0
    for i in range(3):
        place(language_buttons[i],bx+i*(lw+12),dy+158,lw,70)
    var settings_keys = ["quality","vibration","sound","volume","sensitivity","fps","defaults","about","settings_back"]
    for i in range(settings_keys.size()):
        place(actions[settings_keys[i]],bx,dy+244+i*72,bw,62)
    for key in ["levels","achievements","about"]:
        var py2 = maxf(20,(h-540)*0.5)
        place(page_panels[key],px,py2,pw,540)
        place(page_titles[key],px+12,py2+18,pw-24,72)
        place(actions[key+"_back"],bx,py2+438,bw,70)
        if key == "levels": place(actions["level_one"],bx,py2+154,bw,100)
        if key == "achievements": place(achievement_text,bx,py2+105,bw,300)
        if key == "about": place(info_text,bx,py2+105,bw,300)

    var ph = 520.0
    var py = maxf(20,(h-ph)*0.5)
    place(page_panels["pause"],px,py,pw,ph)
    place(page_titles["pause"],px+10,py+18,pw-20,72)
    for i in range(4):
        place(actions[["resume","pause_restart","pause_settings","pause_home"][i]],bx,py+110+i*96,bw,80)

func show_screen(next: String) -> void:
    if screen == "play" and next != "play" and is_instance_valid(ball) and not finished:
        last_velocity = ball.linear_velocity
        last_spin = ball.angular_velocity
        pause_snapshot = true
    screen = next
    menu_open = next != "play"
    hud.visible = next == "play"
    for key in pages:
        pages[key].visible = next == key
    move = Vector2.ZERO
    touch_id = -1
    braking = false
    brake_touch = -1
    if is_instance_valid(ball):
        ball.freeze = menu_open or finished
        if next == "play" and pause_snapshot and not finished:
            ball.linear_velocity = last_velocity
            ball.angular_velocity = last_spin
            pause_snapshot = false
    if is_instance_valid(preview_world):
        preview_world.render_target_update_mode = SubViewport.UPDATE_ALWAYS if next == "shop" else SubViewport.UPDATE_DISABLED
    if next == "achievements": refresh_achievements()
    if next == "shop" or next == "main": refresh_shop()
    if next == "settings": update_language()

func go_home() -> void:
    home_needs_reset = true
    show_screen("main")

func set_menu(open: bool) -> void:
    show_screen("main" if open else "play")

func refresh_lives() -> void:
    if not is_instance_valid(life_label): return
    life_label.text = word(7)+"  "+str(lives)+"/3"
    for i in range(life_icons.size()):
        life_icons[i].modulate = Color.WHITE if i < lives else Color(0.4,0.4,0.4,0.55)

func refresh_shop() -> void:
    if not is_instance_valid(balance_label): return
    balance_label.text = word(10)+"  "+str(coins)
    main_balance.text = balance_label.text
    preview_caption.text = SKIN_NAMES[lang][preview_index]+"  ·  "+str(preview_index+1)+"/12"
    for i in range(shop_buttons.size()):
        shop_labels[i].visible = false
        shop_swatches[i].visible = false
        var b = shop_buttons[i]
        b.visible = i == preview_index
        if i == equipped:
            b.text = word(12)
            b.icon = tex("check")
            b.disabled = true
        elif owned.has(i):
            b.text = word(11)
            b.icon = tex("check")
            b.disabled = false
        else:
            b.text = str(PRICES[i])+"  "+word(13)
            b.icon = tex("lock")
            b.disabled = coins < PRICES[i]
    refresh_preview()

func update_language() -> void:
    heading.text = word(28)
    help.text = {"en":"Collect 3 orbs, reach the flag.","ar":"اجمع ٣ كرات ثم بلغ العلم.","pt":"Colete 3 orbes e alcance a bandeira."}[lang]
    restart.text = ""
    menu_button.text = ""
    brake.text = word(29)
    play_again.text = word(9)
    result_home.text = word(5)
    menu_title.text = {"en":"Marble Quest 3D","ar":"مغامرة الكرة 3D","pt":"Marble Quest 3D"}[lang]
    menu_subtitle.text = EXTRA[lang][2]
    menu_hint.text = word(27)
    menu_play.text = word(0)
    actions["shop"].text = word(1)
    actions["settings"].text = word(2)
    page_titles["shop"].text = word(1)
    page_titles["settings"].text = word(2)
    page_titles["pause"].text = word(3)
    actions["resume"].text = word(4)
    actions["pause_restart"].text = word(30)
    actions["pause_settings"].text = word(2)
    actions["pause_home"].text = word(5)
    actions["shop_back"].text = word(6)
    actions["settings_back"].text = word(6)
    actions["language_title"].text = word(22)
    quality_button.text = word(15)+"  •  "+word(16+quality)
    vibration_button.text = word(19)+"  •  "+word(20 if vibration else 21)
    actions["levels"].text = more(0)
    actions["achievements"].text = more(1)
    page_titles["levels"].text = more(0)
    page_titles["achievements"].text = more(1)
    page_titles["about"].text = more(7)
    actions["level_one"].text = "01  ·  "+more(14)
    for key in ["levels","achievements","about"]:
        actions[key+"_back"].text = word(6)
    actions["sound"].text = more(2)+"  •  "+word(20 if sound_on else 21)
    actions["volume"].text = more(3)+"  •  "+str(int(sound_volume*100))+"%"
    actions["sensitivity"].text = more(4)+"  •  "+str(int(sensitivity*100))+"%"
    actions["fps"].text = more(5)+"  •  "+str(fps)
    actions["defaults"].text = more(6)
    actions["about"].text = more(7)
    info_text.text = more(8)
    refresh_achievements()
    refresh_lives()
    refresh_shop()
    layout_ui.call_deferred()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not menu_open and not finished:
        if event.pressed and brake.get_global_rect().has_point(event.position) and brake_touch == -1:
            brake_touch = event.index
            braking = true
            play_ui_sound()
        elif not event.pressed and event.index == brake_touch:
            brake_touch = -1
            braking = false
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
        move = ((event.position-touch_start)*sensitivity/75.0).limit_length(1.0)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and touch_id == -1:
            touch_start = event.position
            touch_id = -2
        elif touch_id == -2:
            touch_id = -1
            move = Vector2.ZERO
    elif event is InputEventMouseMotion and touch_id == -2:
        move = ((event.position-touch_start)*sensitivity/75.0).limit_length(1.0)


func more(index: int) -> String:
    return MORE[lang][index]

func play_ui_sound() -> void:
    if sound_on and sound_volume > 0.0 and is_instance_valid(audio_player) and audio_player.stream != null:
        audio_player.volume_db = linear_to_db(sound_volume)
        audio_player.play()

func save_settings() -> void:
    Engine.max_fps = fps
    apply_quality()
    update_language()
    write_save()

func restore_settings() -> void:
    quality = 1
    vibration = false
    sound_on = true
    sound_volume = 0.7
    sensitivity = 1.0
    fps = 60
    save_settings()

func refresh_achievements() -> void:
    if not is_instance_valid(achievement_text): return
    achievement_text.text = "%s: %d\n\n%s: %.1fs\n\n%s: %d\n\n%s: %s" % [more(9),victories,more(10),best,more(16),earned_total,more(15),"✓" if victories>0 else more(17)]

func setup_preview() -> void:
    var root = Node3D.new()
    preview_world.add_child(root)
    var light = DirectionalLight3D.new()
    root.add_child(light)
    light.rotation_degrees = Vector3(-35,-35,0)
    light.light_energy = 1.3
    var env_node = WorldEnvironment.new()
    var env = Environment.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("dbe8e4")
    env.ambient_light_energy = 0.8
    env_node.environment = env
    root.add_child(env_node)
    var cam = Camera3D.new()
    root.add_child(cam)
    cam.position = Vector3(0,0.8,4.0)
    cam.look_at(Vector3.ZERO)
    cam.current = true
    preview_mesh = model("ball",root,Vector3.ONE*2.1)
    refresh_preview()

func select_preview(delta: int) -> void:
    preview_index = posmod(preview_index+delta,PRICES.size())
    refresh_shop()

func refresh_preview() -> void:
    if not is_instance_valid(preview_mesh): return
    var mat = skin_material(preview_index)
    for part in preview_mesh.find_children("*","MeshInstance3D",true,false):
        part.material_override = mat

func _process(delta: float) -> void:
    if is_instance_valid(preview_mesh) and screen == "shop":
        preview_mesh.rotate_y(delta*0.7)
    if is_instance_valid(ball_visual) and screen == "main":
        ball_visual.rotate_y(delta*0.45)
    if is_instance_valid(joystick_knob) and not menu_open and not finished:
        var target = (pad.size-joystick_knob.size)*0.5+move*54.0
        joystick_knob.position = joystick_knob.position.lerp(target,1.0-exp(-delta*20.0))
