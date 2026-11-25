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
var bridge: PhysicsBody3D
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
var stage_index = 0
var unlocked_stage = 0
var next_stage_button: Button
var stage_hazards: Array[AnimatableBody3D] = []
const STAGE_NAMES = {
 "en":["Sky Crossing","Emerald Passage","Golden Ruins","Crystal Canyon","Amber Bridges","Frost Terrace","Jade Gardens","Obsidian Circuit","Sapphire Falls","Copper Maze","Ivory Citadel","Twilight Summit","Windward Spiral","Cedar Canopy","Temple Stairway","Amethyst Vault","Timber Traverse","Glacier Run","Lotus Courtyard","Basalt Foundry","Cascade Gorge","Bronze Labyrinth","Moon Palace","Astral Crown"],
 "ar":["عبور السماء","ممر الزمرد","الأطلال الذهبية","وادي البلور","جسور الكهرمان","مدرج الصقيع","حدائق اليشم","حلبة السبج","شلالات الياقوت","متاهة النحاس","قلعة العاج","قمة الشفق","لولب الرياح","غابة الأرز","مدرج المعبد","قبو الجمشت","جسر الأخشاب","ممر الجليد","باحة اللوتس","مصهر البازلت","وادي الشلالات","متاهة البرونز","قصر القمر","تاج النجوم"],
 "pt":["Travessia Celeste","Passagem Esmeralda","Ruínas Douradas","Cânion de Cristal","Pontes de Âmbar","Terraço Gelado","Jardins de Jade","Circuito de Obsidiana","Cascatas de Safira","Labirinto de Cobre","Cidadela de Marfim","Cume do Crepúsculo","Espiral dos Ventos","Bosque de Cedros","Escadaria do Templo","Abóbada de Ametista","Travessia de Madeira","Trilha Glacial","Pátio de Lótus","Forja de Basalto","Garganta das Cascatas","Labirinto de Bronze","Palácio Lunar","Coroa Astral"]
}
const ROUTES = [
 [[0,2],[0,-5],[0,-9],[0,-13],[0,-17],[0,-21],[0,-25]],
 [[0,2],[0,-5],[4,-11],[4,-18],[-1,-24],[-1,-32]],
 [[0,2],[-5,-5],[-5,-13],[2,-13],[2,-22],[7,-29],[7,-37]],
 [[0,2],[0,-6],[6,-12],[0,-18],[-6,-24],[0,-30],[0,-39]],
 [[0,2],[-4,-6],[-4,-15],[5,-15],[5,-24],[-2,-31],[-2,-40]],
 [[0,2],[5,-5],[9,-12],[5,-20],[0,-26],[-5,-34],[-5,-43]],
 [[0,2],[0,-7],[-7,-7],[-7,-17],[0,-23],[7,-23],[7,-34],[0,-41]],
 [[0,2],[6,-4],[6,-13],[-3,-13],[-3,-22],[6,-28],[6,-38],[0,-46]],
 [[0,2],[-5,-6],[0,-14],[7,-19],[7,-29],[0,-36],[-7,-42],[-7,-50]],
 [[0,2],[0,-8],[8,-8],[8,-18],[-4,-18],[-4,-28],[5,-34],[5,-45],[0,-51]],
 [[0,2],[-6,-5],[-6,-16],[0,-23],[7,-23],[7,-34],[0,-42],[-6,-48],[0,-55]],
 [[0,2],[7,-6],[0,-14],[-8,-22],[-8,-33],[0,-39],[8,-39],[8,-50],[0,-57],[0,-65]],
 [[0,2],[6,-5],[10,-13],[6,-21],[-2,-24],[-9,-18],[-12,-10],[-18,-8]],
 [[0,2],[-4,-7],[-9,-13],[-3,-20],[4,-23],[9,-31],[3,-39],[-4,-46]],
 [[0,2],[0,-8],[7,-8],[7,-17],[0,-17],[0,-27],[-7,-27],[-7,-37],[0,-44]],
 [[0,2],[-7,-4],[-12,-12],[-5,-19],[3,-19],[10,-26],[3,-33],[-5,-33],[-9,-42]],
 [[0,2],[0,-9],[6,-17],[6,-28],[-3,-34],[-3,-45],[5,-52]],
 [[0,2],[7,-5],[13,-13],[8,-22],[0,-25],[-8,-31],[-12,-40],[-5,-48]],
 [[0,2],[-8,2],[-8,-8],[0,-14],[8,-14],[8,-24],[0,-31],[-8,-31],[-8,-42],[0,-49]],
 [[0,2],[6,-5],[0,-12],[-6,-19],[0,-26],[6,-33],[0,-40],[-6,-47],[0,-54]],
 [[0,2],[-5,-7],[-5,-19],[5,-25],[5,-37],[-5,-43],[-5,-55],[3,-62]],
 [[0,2],[8,2],[8,-8],[-3,-8],[-3,-18],[8,-18],[8,-28],[-3,-28],[-3,-38],[5,-46]],
 [[0,2],[-7,-6],[-7,-16],[0,-23],[7,-23],[13,-31],[7,-39],[0,-39],[-7,-47],[0,-55]],
 [[0,2],[0,-8],[8,-14],[12,-23],[4,-31],[-6,-31],[-13,-40],[-6,-49],[3,-49],[10,-58],[0,-66]]
]
const STAGE_COUNT = 24
# Hand-validated off-route bonus bearings, clear of every mandatory segment.
const BONUS_DIRECTIONS = [Vector3(0.92388,0,0.382683),Vector3(-1,0,0),Vector3(-0.92388,0,0.382683),Vector3(-0.707107,0,-0.707107),Vector3(-0.92388,0,0.382683),Vector3(0.92388,0,0.382683),Vector3(0.382683,0,-0.92388),Vector3(0.92388,0,0.382683),Vector3(-0.92388,0,0.382683),Vector3(-1,0,0),Vector3(-0.92388,0,0.382683),Vector3(0.92388,0,0.382683),Vector3(0.92388,0,0.382683),Vector3(0.92388,0,-0.382683),Vector3(-1,0,0),Vector3(-0.707107,0,0.707107),Vector3(-1,0,0),Vector3(0.707107,0,0.707107),Vector3(-0.382683,0,0.92388),Vector3(0.92388,0,0.382683),Vector3(-0.92388,0,0.382683),Vector3(0.92388,0,0.382683),Vector3(-0.92388,0,0.382683),Vector3(-0.707107,0,-0.707107)]
const DECK_COLORS = ["6c7c80","426b59","8d7756","625779","85603e","617f91","5e7453","414959","476f82","805649","77756b","645a81"]
const SKY_COLORS = ["7fb9d9","76b8a6","d6ab75","9387c5","d6a575","a5c6e6","8dbba1","66758e","619ec7","c18d80","aebec9","7776a9"]
var route_points: Array[Vector3] = []
var stage_records: Dictionary = {}
var stage_length = 0.0
var secret_claimed = false
var secret_platform: AnimatableBody3D
var secret_origin = Vector3.ZERO
var level_page = 0
var level_buttons: Array[Button] = []
var sky_surface: ProceduralSkyMaterial

var coins = 0
var run_gold = 0
var gust_zones: Array[Dictionary] = []
var challenge_count = 0
var effect_player: AudioStreamPlayer
var effects: Dictionary = {}
var result_backdrop: Panel
var result_symbol: TextureRect
var result_tween: Tween
var gold_flash: Label
var gold_tween: Tween
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
const PRICES = [0,650,1100,1650,2400,3400,4800,6500,8500,11000,14500,19000]
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
var preview_pedestal: Node3D
var cloud_nodes: Array[MeshInstance3D] = []
var cloud_origins: Array[Vector3] = []
var material_textures: Dictionary = {}
var royal_textures: Dictionary = {}
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
    for key in ["rock_alt","rock_spire","tree_alt"]:
        if parsed.has(key) and ResourceLoader.exists(parsed[key]):
            var extra = load(parsed[key])
            if extra is PackedScene: packed[key] = extra
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
    sky_surface = sky_mat
    sky_mat.sky_top_color = Color("4387bc")
    sky_mat.sky_horizon_color = Color("d9edff")
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
    sun.light_energy = 0.73
    sun.shadow_enabled = true
    sun_light = sun
    add_child(sun)
    apply_quality()
    camera = Camera3D.new()
    camera.fov = 58
    camera.current = true
    add_child(camera)
    create_clouds()

func art_texture(key: String) -> Texture2D:
    if not material_textures.has(key):
        var path = "res://assets/material_art/" + key + ".png"
        if ResourceLoader.exists(path):
            material_textures[key] = load(path)
    return material_textures.get(key) as Texture2D

func create_clouds() -> void:
    var tex_cloud = art_texture("cloud")
    if tex_cloud == null: return
    var mat = StandardMaterial3D.new()
    mat.albedo_texture = tex_cloud
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    for i in range(12):
        var cloud = MeshInstance3D.new()
        var quad = QuadMesh.new()
        quad.size = Vector2(15.0+float(i%3)*4.0,7.0+float(i%2)*2.0)
        cloud.mesh = quad
        cloud.material_override = mat
        cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(cloud)
        var origin = Vector3((-1.0 if i%2==0 else 1.0)*(11.0+float(i%4)*5.0),-5.0+float(i%3)*2.1,-float(i)*6.0-4.0)
        cloud.position = origin
        cloud_nodes.append(cloud)
        cloud_origins.append(origin)

func marble_visual(parent: Node3D, diameter: float) -> Node3D:
    var wrapper = Node3D.new()
    parent.add_child(wrapper)
    var mesh = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = diameter*0.5
    sphere.height = diameter
    sphere.radial_segments = 48
    sphere.rings = 24
    mesh.mesh = sphere
    wrapper.add_child(mesh)
    return wrapper

func stone_piece(parent: Node3D, pos: Vector3, size: Vector3, angle: float = 0.0) -> void:
    var part = MeshInstance3D.new()
    var block = BoxMesh.new()
    block.size = size
    part.mesh = block
    part.material_override = palette_material("architecture",Color("73766f"),0.86,0.02)
    parent.add_child(part)
    part.position = pos
    part.rotation.z = angle

func ruin_arch(pos: Vector3, scale_factor: float) -> void:
    var arch = Node3D.new()
    course.add_child(arch)
    arch.position = pos
    arch.scale = Vector3.ONE*scale_factor
    for side in [-1.0,1.0]:
        for row in range(4):
            stone_piece(arch,Vector3(side*1.25,0.23+float(row)*0.48,0),Vector3(0.58,0.46,0.72))
        stone_piece(arch,Vector3(side*1.25,0.13,0),Vector3(0.85,0.26,0.95))
    for i in range(11):
        var theta = float(i)*PI/10.0
        stone_piece(arch,Vector3(cos(theta)*1.25,1.98+sin(theta)*1.25,0),Vector3(0.58,0.43,0.76),theta)

func crystal_cluster(pos: Vector3) -> void:
    var cluster = Node3D.new()
    course.add_child(cluster)
    cluster.position = pos
    for i in range(4):
        var crystal = MeshInstance3D.new()
        var shape = CylinderMesh.new()
        shape.top_radius = 0.0
        shape.bottom_radius = 0.16+float(i%2)*0.06
        shape.height = 0.7+float(i%3)*0.26
        shape.radial_segments = 5
        shape.rings = 1
        crystal.mesh = shape
        crystal.material_override = palette_material("crystal",Color("76c6b6"),0.22,0.34)
        cluster.add_child(crystal)
        crystal.position = Vector3(float(i%2)*0.36,shape.height*0.5,float(i/2)*0.25)
        crystal.rotation.z = (float(i)-1.5)*0.14
    var moss = MeshInstance3D.new()
    var base = BoxMesh.new()
    base.size = Vector3(1.1,0.12,0.9)
    moss.mesh = base
    moss.material_override = palette_material("moss",Color("86ad66"),0.92,0.0)
    cluster.add_child(moss)
    moss.position.y = -0.06

func flowing_water(pos: Vector3, width: float, height: float) -> void:
    var sheet = MeshInstance3D.new()
    var quad = QuadMesh.new()
    quad.size = Vector2(width,height)
    sheet.mesh = quad
    var mat = ShaderMaterial.new()
    mat.shader = load("res://assets/material_shaders/waterfall.gdshader")
    sheet.material_override = mat
    sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    course.add_child(sheet)
    sheet.position = pos

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
        if key == "track":
            mat.albedo_color = Color("a7b29b")
            mat.albedo_texture = art_texture("stone")
            mat.normal_enabled = true
            mat.normal_texture = art_texture("stone_normal")
            mat.normal_scale = 0.24
            mat.uv1_triplanar = true
            mat.uv1_world_triplanar = true
            mat.uv1_scale = Vector3.ONE*0.34
        elif key == "gold_trim":
            mat.albedo_texture = art_texture("gold_metal")
        elif key == "moss":
            mat.albedo_texture = art_texture("moss")
            mat.uv1_triplanar = true
            mat.uv1_world_triplanar = true
        elif key == "crystal":
            mat.albedo_texture = art_texture("crystal")
            mat.emission_enabled = true
            mat.emission = Color("277f71")
            mat.emission_energy_multiplier = 0.25
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

func deck_material() -> StandardMaterial3D:
    var key = "deck_"+str(stage_index)
    if not materials.has(key):
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color.WHITE
        mat.albedo_texture = art_texture("deck_%02d" % stage_index)
        if mat.albedo_texture == null: mat.albedo_color = Color(DECK_COLORS[stage_index%12])
        mat.normal_enabled = true
        mat.normal_texture = art_texture("deck_normal_%02d" % stage_index)
        mat.normal_scale = 0.62
        mat.roughness = 0.78
        mat.metallic = 0.04
        mat.uv1_triplanar = true
        mat.uv1_world_triplanar = true
        mat.uv1_scale = Vector3.ONE*0.24
        materials[key] = mat
    return materials[key]

func deck_side() -> StandardMaterial3D:
    return palette_material("deck_side_"+str(stage_index%12),Color(DECK_COLORS[stage_index%12]).darkened(0.26),0.84,0.08)

func attach_mesh(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
    var item = MeshInstance3D.new()
    item.mesh = shape
    item.material_override = mat
    parent.add_child(item)
    item.position = pos
    return item

func deck_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
    var shape = BoxMesh.new()
    shape.size = size
    attach_mesh(parent,shape,pos,mat)

func platform(pos: Vector3, size: Vector3, moving: bool = false) -> Node3D:
    var body: PhysicsBody3D
    if moving:
        body = AnimatableBody3D.new()
    else:
        body = StaticBody3D.new()
    course.add_child(body)
    body.position = pos
    # Dark structural core, thinner inset textured wearing surface. Exact collider top.
    deck_box(body,Vector3(size.x,size.y-0.12,size.z),Vector3(0,-(size.y+0.12)*0.5,0),deck_side())
    deck_box(body,Vector3(size.x,0.12,size.z),Vector3(0,-0.06,0),deck_material())
    collider(body,size,Vector3(0,-size.y*0.5,0))
    return body

func round_deck(point: Vector3,radius: float,sides: int) -> void:
    var body = StaticBody3D.new()
    course.add_child(body)
    body.position = point
    # A polygonal convex collision hull matches the visible drum rather than an invisible box.
    var mesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = 0.18
    mesh.radial_segments = sides
    mesh.rings = 1
    attach_mesh(body,mesh,Vector3(0,-0.09,0),deck_material())
    var base = CylinderMesh.new()
    base.top_radius = radius
    base.bottom_radius = radius*0.87
    base.height = 0.52
    base.radial_segments = sides
    base.rings = 1
    attach_mesh(body,base,Vector3(0,-0.44,0),deck_side())
    var hull = ConvexPolygonShape3D.new()
    var vertices = PackedVector3Array()
    for i in range(sides):
        var angle = TAU*float(i)/float(sides)
        vertices.append(Vector3(sin(angle)*radius,0,cos(angle)*radius))
        vertices.append(Vector3(sin(angle)*radius,-0.7,cos(angle)*radius))
    hull.points = vertices
    var col = CollisionShape3D.new()
    col.shape = hull
    body.add_child(col)
    var rim = TorusMesh.new()
    rim.inner_radius = radius-0.12
    rim.outer_radius = radius-0.04
    rim.rings = 24
    rim.ring_segments = 8
    attach_mesh(body,rim,Vector3(0,-0.11,0),deck_side())

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
            collect_gold(10)
            play_effect("pickup")
            if count == 2:
                spawn = a.position + Vector3(0,0.65,0)
                checkpoint_active = true
            a.queue_free())
    orbs.append(a)

func reset_course() -> void:
    if course != null:
        remove_child(course)
        course.queue_free()
    # Do not hold every high-resolution course texture in memory.
    for key in materials.keys():
        if str(key).begins_with("deck_") and not str(key).begins_with("deck_side_"): materials.erase(key)
    for key in material_textures.keys():
        if str(key).begins_with("deck_"): material_textures.erase(key)
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
    secret_claimed = false
    run_gold = 0
    secret_platform = null
    orbs.clear()
    stage_hazards.clear()
    gust_zones.clear()
    challenge_count = 0
    if is_instance_valid(result_tween): result_tween.kill()
    result.scale = Vector2.ONE
    result.visible = false
    result_backdrop.visible = false
    result_symbol.visible = false
    if is_instance_valid(gold_tween): gold_tween.kill()
    gold_flash.visible = false
    play_again.visible = false
    result_home.visible = false
    next_stage_button.visible = false
    pad.visible = true
    brake.visible = true
    refresh_lives()
    build_route()
    spawn = route_points[0]+Vector3(0,1.3,0)
    island_landscape()
    var end: Vector3 = route_points.back()
    var orb_indices = [1, int(route_points.size()/2), route_points.size()-2]
    for idx in orb_indices:
        orb(route_points[idx] + Vector3(0,0.7,0))
    gate = area_at(end+Vector3(0,0.8,0),Vector3(3.6,1.6,3.6))
    decoration("marker",end+Vector3(1.12,1.30,0),Vector3(0.68,2.45,0.68))
    var goal_mesh = MeshInstance3D.new()
    var ring = TorusMesh.new()
    ring.inner_radius = 1.12
    ring.outer_radius = 1.38
    goal_mesh.mesh = ring
    var goal_mat = palette_material("goal_ring",Color("ffcf70"),0.32,0.42)
    goal_mat.emission_enabled = true
    goal_mat.emission = Color("e9a648")
    goal_mat.emission_energy_multiplier = 0.65
    goal_mesh.material_override = goal_mat
    course.add_child(goal_mesh)
    goal_mesh.position = end+Vector3(0,0.10,0)
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
    ball_visual = marble_visual(ball,0.76)
    ball.freeze = menu_open
    brake_touch = -1
    touch_id = -1
    apply_skin()
    camera.position = spawn + Vector3(0,6.8,8.6)
    camera.look_at(spawn + Vector3(0,0,-3))
    heading.text = "%02d · %s" % [stage_index+1,STAGE_NAMES[lang][stage_index]]

# Imported environmental meshes remain visual only: the proven course
# collision shapes are unchanged. No generated primitive scenery.
func make_hazard(pos: Vector3) -> AnimatableBody3D:
    var hazard = AnimatableBody3D.new()
    course.add_child(hazard)
    hazard.position = pos
    hazard.set_meta("origin_x",pos.x)
    var size = Vector3(0.8,0.72,0.55)
    stone_piece(hazard,Vector3.ZERO,size)
    collider(hazard,size,Vector3.ZERO)
    stage_hazards.append(hazard)
    return hazard

func start_stage(index: int) -> void:
    if index < 0 or index >= STAGE_COUNT or index > unlocked_stage: return
    stage_index = index
    reset_course()
    home_needs_reset = false
    show_screen("play")

func connect_decks(a: Vector3,b: Vector3,width: float,rail: bool = false) -> PhysicsBody3D:
    var direction = b-a
    var middle = (a+b)*0.5-Vector3(0,0.012,0)
    var length = direction.length()
    var body = platform(middle,Vector3(width,0.56,length),false) as PhysicsBody3D
    body.look_at(middle+direction,Vector3.UP)
    var theme = stage_index%12
    var trim_mat = palette_material("trim_"+str(theme),Color(DECK_COLORS[theme]).lightened(0.26),0.55,0.20)
    # Side bands stop before junctions; no overlapping coplanar strips.
    var visible_length = maxf(0.0,length-7.0)
    if visible_length>0.25:
        for side in [-1.0,1.0]:
            deck_box(body,Vector3(0.10,0.08,visible_length),Vector3(side*(width*0.5-0.16),0.045,0),trim_mat)
            if rail:
                var rp = Vector3(side*(width*0.5-0.12),0.18,0)
                var rs = Vector3(0.16,0.36,visible_length)
                deck_box(body,rs,rp,deck_side())
                collider(body,rs,rp)
            if theme in [4,8,9]:
                for j in range(int(visible_length/1.4)):
                    var post = CylinderMesh.new()
                    post.top_radius = 0.08
                    post.bottom_radius = 0.11
                    post.height = 0.58
                    post.radial_segments = 8
                    attach_mesh(body,post,Vector3(side*(width*0.5-0.18),-0.30,-visible_length*0.5+0.7+j*1.4),trim_mat)
    # Small direction inlays are flush, not extra collision obstacles.
    if length>6.0:
        deck_box(body,Vector3(0.14,0.018,0.55),Vector3(0,0.012,0),trim_mat)
    return body

func route_height(_i: int) -> float:
    # Mandatory junctions share one level. Previously the slope ran underneath
    # a higher flat junction and exposed a vertical lip to the rolling sphere.
    # Elevated bonus routes remain independent of mandatory progression.
    return 0.0

func build_route() -> void:
    route_points.clear()
    stage_length = 0.0
    var raw: Array = ROUTES[stage_index]
    for i in range(raw.size()):
        var pair: Array = raw[i]
        route_points.append(Vector3(float(pair[0]),route_height(i),float(pair[1])))
    var theme = stage_index%12
    var width: float = [4.8,4.5,4.2,4.4,4.0,4.6,4.7,4.1,4.3,4.2,4.6,4.0][theme]
    # Keep junctions spacious enough to turn; bridge difficulty increases sharply.
    if stage_index>=6: width -= 0.30
    if stage_index>=12: width -= 0.30
    if stage_index>=18: width -= 0.25
    for i in range(route_points.size()-1):
        var a: Vector3 = route_points[i]
        var b: Vector3 = route_points[i+1]
        stage_length += a.distance_to(b)
        var segment_width = float(width)
        var long_span = a.distance_to(b)>=7.8
        if stage_index>=2 and long_span and i>=1:
            segment_width = minf(segment_width,3.0 if stage_index<6 else (2.65 if stage_index<12 else (2.35 if stage_index<18 else 2.05)))
        elif theme in [4,7,9,11] and i%2==1: segment_width -= 0.25
        var segment = connect_decks(a,b,segment_width,i%3==1 and stage_index<6)
        if i==2: bridge=segment
        if stage_index>=2 and long_span and i>=1:
            add_challenge(a,b,segment_width,i)
    for i in range(route_points.size()):
        var point: Vector3 = route_points[i]
        var size = float(width)+0.85 if i>0 and i<route_points.size()-1 else 6.0
        if theme in [0,1,3,5,6,8,10,11]:
            var sides = 24 if theme in [0,5,6,8,10] else (8 if theme in [1,11] else 12)
            round_deck(point,size*0.5,sides)
        else:
            platform(point,Vector3(size,0.65,size))
    if stage_index >= 2:
        var anchor: Vector3 = route_points[1]
        var branch: Vector3 = BONUS_DIRECTIONS[stage_index]
        var bonus = anchor+branch*7.4+Vector3(0,0.22,0)
        var ramp_start = anchor+branch*2.9
        var ramp_end = bonus-branch*1.9
        connect_decks(anchor,ramp_start,2.8,false)
        connect_decks(ramp_start,ramp_end,2.8,false)
        connect_decks(ramp_end,bonus,2.8,false)
        secret_origin = bonus
        secret_platform = platform(bonus,Vector3(3.8,0.65,3.8),true) as AnimatableBody3D
        var bonus_area = area_at(bonus+Vector3(0,0.90,0),Vector3(1.55,1.7,1.55))
        var reward = marble_visual(bonus_area,0.56)
        var mat = palette_material("secret_reward",Color("8ae7ff"),0.22,0.25)
        mat.emission_enabled = true
        mat.emission = Color("35b8d1")
        mat.emission_energy_multiplier = 0.8
        for mesh in reward.find_children("*","MeshInstance3D",true,false):
            mesh.material_override = mat
        bonus_area.body_entered.connect(func(body):
            if body == ball and not secret_claimed and not finished:
                secret_claimed = true
                collect_gold(50)
                play_effect("bonus")
                bonus_area.queue_free())
    # Obstacles sit on straight segments, away from the centre and junctions.
    for i in range(2,route_points.size()-1,3):
        if stage_index>=3 and theme in [7,9,11]:
            var a: Vector3 = route_points[i]
            var b: Vector3 = route_points[i+1]
            if a.distance_to(b)<8.0: continue
            var tangent = (b-a).normalized()
            var lateral = Vector3(-tangent.z,0,tangent.x)
            make_hazard((a+b)*0.5+lateral*(width*0.5-0.10)+Vector3(0,0.42,0))
    if is_instance_valid(sky_surface):
        sky_surface.sky_top_color = Color(SKY_COLORS[theme])
        sky_surface.sky_horizon_color = Color(SKY_COLORS[theme]).lerp(Color.WHITE,0.38)

func add_challenge(a: Vector3,b: Vector3,width: float,index: int) -> void:
    # Pairs of real moving bumpers along exposed bridge edges and a crosswind
    # corridor. Centre remains traversable with precise steering and braking.
    var tangent = (b-a).normalized()
    var side = Vector3(-tangent.z,0,tangent.x)
    var middle = (a+b)*0.5
    var intensity = 0.7+float(stage_index)*0.075
    var sign_value = -1.0 if index%2==0 else 1.0
    var hazard = AnimatableBody3D.new()
    course.add_child(hazard)
    hazard.position = middle+side*sign_value*(width*0.5-0.12)+Vector3(0,0.22,0)
    hazard.set_meta("cross_origin",hazard.position)
    hazard.set_meta("cross_side",side*sign_value)
    hazard.set_meta("cross_phase",float(index)*1.7)
    hazard.set_meta("cross_amplitude",minf(0.22,width*0.08))
    var size = Vector3(0.42,0.52,0.48)
    var mesh = BoxMesh.new()
    mesh.size = size
    attach_mesh(hazard,mesh,Vector3.ZERO,palette_material("hazard_copper",Color("b76a39"),0.42,0.35))
    collider(hazard,size,Vector3.ZERO)
    stage_hazards.append(hazard)
    # Yellow edge beacons indicate the wind corridor before entering it.
    for edge in [-1.0,1.0]:
        var post = CylinderMesh.new()
        post.top_radius = 0.09
        post.bottom_radius = 0.15
        post.height = 0.48
        post.radial_segments = 8
        var warning = palette_material("wind_beacon",Color("f4b74b"),0.40,0.28)
        warning.emission_enabled = true
        warning.emission = Color("c88324")
        warning.emission_energy_multiplier = 0.55
        attach_mesh(course,post,middle-tangent*1.35+side*edge*(width*0.5-0.08)+Vector3(0,0.22,0),warning)
    gust_zones.append({"centre":middle,"direction":tangent,"side":side,"width":width,"force":intensity,"phase":float(index)*1.7})
    challenge_count += 1

func landmark_column(pos: Vector3,height: float,colour: Color) -> void:
    var column = Node3D.new()
    course.add_child(column)
    column.position = pos
    var mat = palette_material("column_"+colour.to_html(),colour,0.74,0.06)
    var shaft = CylinderMesh.new()
    shaft.top_radius = 0.29
    shaft.bottom_radius = 0.42
    shaft.height = height
    shaft.radial_segments = 12
    attach_mesh(column,shaft,Vector3(0,height*0.5,0),mat)
    for y in [0.13,height-0.12]:
        var cap = CylinderMesh.new()
        cap.top_radius = 0.51
        cap.bottom_radius = 0.51
        cap.height = 0.24
        cap.radial_segments = 12
        attach_mesh(column,cap,Vector3(0,y,0),mat)

func island_landscape() -> void:
    var theme = stage_index%12
    for i in range(route_points.size()):
        var point: Vector3 = route_points[i]
        if i%2==0 or i==route_points.size()-1:
            decoration("rock",point+Vector3(0,-2.65,0),Vector3(4.9,4.1,4.7))
        if i==0 or i==route_points.size()-1: continue
        var side = -1.0 if i%2==0 else 1.0
        var offset = point+Vector3(side*6.5,-2.65,0)
        # The twelve architectural families use deliberately different silhouettes.
        match theme:
            0:
                decoration("cliff",offset,Vector3(3.4,4.5,3.4))
                flowing_water(offset+Vector3(0,-0.8,1.7),1.5,5.0)
            1:
                decoration("rock",offset,Vector3(3.8,3.6,3.6))
                decoration("forest_tree_alt",offset+Vector3(0,3.6,0),Vector3(2.2,3.6,2.2))
                decoration("forest_bush",offset+Vector3(0.65,2.1,0.5),Vector3(0.9,0.7,0.9))
            2:
                decoration("cliff",offset,Vector3(3.9,4.3,3.9))
                ruin_arch(offset+Vector3(0,2.25,0),1.2)
            3:
                decoration("rock",offset,Vector3(3.5,4.1,3.5))
                crystal_cluster(offset+Vector3(0,2.1,0))
                crystal_cluster(offset+Vector3(0.85,2.2,0.7))
            4:
                decoration("cliff",offset,Vector3(3.7,4.1,3.7))
                decoration("bridge_wood",offset+Vector3(0,2.5,0),Vector3(2.6,0.9,3.3))
                landmark_column(offset+Vector3(0,2.1,0),2.4,Color("755c43"))
            5:
                decoration("rock",offset,Vector3(3.9,4.3,3.9))
                landmark_column(offset+Vector3(0,2.2,0),3.5,Color("97b0c3"))
                crystal_cluster(offset+Vector3(0.9,2.2,0.7))
            6:
                decoration("rock",offset,Vector3(4.0,3.9,4.0))
                decoration("forest_tree",offset+Vector3(0,3.6,0),Vector3(2.8,3.4,2.8))
                decoration("flower",offset+Vector3(0.8,2.2,0.65),Vector3(0.7,0.6,0.7))
            7:
                decoration("cliff",offset,Vector3(3.8,4.4,3.8))
                for k in range(3):
                    landmark_column(offset+Vector3(float(k-1)*0.9,2.3,0),2.2+float(k)*0.6,Color("414853"))
            8:
                decoration("cliff",offset,Vector3(4.0,4.5,4.0))
                flowing_water(offset+Vector3(0,-0.8,1.8),2.4,5.5)
                flowing_water(offset+Vector3(1.1,-0.5,1.9),0.8,4.8)
            9:
                decoration("rock",offset,Vector3(3.8,4.0,3.8))
                landmark_column(offset+Vector3(-0.8,2.1,0),2.5,Color("936744"))
                landmark_column(offset+Vector3(0.8,2.1,0),3.0,Color("936744"))
            10:
                decoration("cliff",offset,Vector3(4.1,4.3,4.1))
                ruin_arch(offset+Vector3(0,2.3,0),1.1)
                landmark_column(offset+Vector3(1.35,2.3,0.7),3.3,Color("b9ad91"))
            11:
                decoration("rock",offset,Vector3(3.7,4.3,3.7))
                var halo = TorusMesh.new()
                halo.inner_radius = 0.86
                halo.outer_radius = 1.05
                var h = attach_mesh(course,halo,offset+Vector3(0,3.6,0),palette_material("halo",Color("9a83c7"),0.32,0.45))
                h.rotation.x = PI*0.5
                crystal_cluster(offset+Vector3(0,2.3,0))
    # Extra licensed imported silhouettes are placed below/outside the driving corridor.
    for i in range(1,route_points.size()-1,2):
        var point: Vector3 = route_points[i]
        var side = 1.0 if i%4==1 else -1.0
        var key = "rock_alt" if theme%2==0 else "rock_spire"
        if packed.has(key):
            decoration(key,point+Vector3(side*7.8,-4.2,1.9),Vector3(3.0,4.8,3.1))
        if theme in [1,6] and packed.has("tree_alt"):
            decoration("tree_alt",point+Vector3(side*8.1,-1.0,1.9),Vector3(1.8,3.0,1.8))
    # Walk-through tunnel arches on broad segments, visually separated from the deck.
    if theme in [2,3,10]:
        var a: Vector3 = route_points[2]
        var b: Vector3 = route_points[3]
        if a.distance_to(b)>6.2:
            var arch_pos = (a+b)*0.5
            var before: int = course.get_child_count()
            ruin_arch(arch_pos,1.65)
            var arch = course.get_child(before) as Node3D
            arch.rotation.y = atan2(b.x-a.x,b.z-a.z)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(ball) or finished or menu_open:
        return
    elapsed += delta
    clock += delta
    respawn_guard = maxf(0.0,respawn_guard-delta)
    for hazard in stage_hazards:
        if hazard.has_meta("cross_origin"):
            var origin: Vector3 = hazard.get_meta("cross_origin")
            var lateral: Vector3 = hazard.get_meta("cross_side")
            var wave = sin(clock*2.2+float(hazard.get_meta("cross_phase")))
            hazard.position = origin+lateral*wave*float(hazard.get_meta("cross_amplitude"))
        else:
            hazard.position.x = float(hazard.get_meta("origin_x")) + sin(clock * 1.45 + hazard.position.z)*0.24
    if is_instance_valid(secret_platform):
        secret_platform.position.y = secret_origin.y+sin(clock*1.4)*0.035
    var axis = move
    axis += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
    axis = axis.limit_length(1.0)
    ball.apply_central_force(Vector3(axis.x,0,axis.y) * (2.0 if braking else 13.5))
    for zone in gust_zones:
        var centre: Vector3 = zone["centre"]
        var direction: Vector3 = zone["direction"]
        var lateral: Vector3 = zone["side"]
        var offset: Vector3 = ball.position-centre
        if absf(offset.dot(direction))<1.55 and absf(offset.dot(lateral))<float(zone["width"])*0.5+0.2 and ball.position.y>centre.y and ball.position.y<centre.y+1.15:
            var wind = sin(clock*1.65+float(zone["phase"]))*float(zone["force"])
            ball.apply_central_force(lateral*wind*(0.35 if braking else 1.0))
    var horizontal = Vector2(ball.linear_velocity.x,ball.linear_velocity.z)
    if horizontal.length() > 4.7:
        var limited = horizontal.limit_length(4.7)
        ball.linear_velocity = Vector3(limited.x,ball.linear_velocity.y,limited.y)
    ball.linear_damp = 5.0 if braking else (1.6 if axis.length() < 0.08 else 0.45)
    ball.angular_damp = 4.0 if braking else 0.4
    if ball.position.y < -5 and respawn_guard <= 0.0:
        lose_attempt()
        if finished: return
    camera.position = camera.position.lerp(ball.position + Vector3(0,6.8,8.6),1.0-exp(-delta*5.0))
    camera.look_at(camera.position + Vector3(0,-6.8,-11.6))
    for a in orbs:
        if is_instance_valid(a):
            a.rotate_y(delta*1.6)
    stats.text = "%s %d/3   •   %s %ds   •   ◈ %d" % [tr_word(3),count,tr_word(5),int(elapsed),coins+run_gold]
    if gate.overlaps_body(ball) and count == 3:
        finish_course()

func finish_course() -> void:
    if finished: return
    finished = true
    won = true
    ball.set_deferred("freeze", true)
    move = Vector2.ZERO
    var target_time = stage_length/(2.5+float(stage_index)*0.025)+8.0
    var stars = mini(lives, 3 if elapsed <= target_time else 2)
    var record: Dictionary = stage_records.get(str(stage_index),{})
    var previous_time = float(record.get("time",0.0))
    stage_records[str(stage_index)] = {"time":elapsed if previous_time<=0.0 else minf(previous_time,elapsed),"stars":maxi(stars,int(record.get("stars",0)))}
    unlocked_stage = maxi(unlocked_stage,mini(stage_index+1,STAGE_COUNT-1))
    coins += run_gold
    earned_total += run_gold
    victories += 1
    play_effect("win")
    if best == 0 or elapsed < best:
        best = elapsed
    write_save()
    result.text = "%s\n%s   •   +%d ◈\n%s %.1fs   •   %d/3" % [tr_word(8),"★".repeat(stars)+"☆".repeat(3-stars),run_gold,tr_word(5),elapsed,count]
    show_result()

func lose_attempt() -> void:
    if finished or menu_open or respawn_guard > 0.0: return
    respawn_guard = 0.75
    falls += 1
    play_effect("fall")
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
        run_gold = 0
        play_effect("lose")
        ball.set_deferred("freeze",true)
        result.text = "%s\n%s %d/3" % [word(8),tr_word(3),count]
        show_result()
    else:
        ball.position = spawn
        ball.reset_physics_interpolation()

func show_result() -> void:
    result_backdrop.visible = true
    result_backdrop.add_theme_stylebox_override("panel",imported_style("fantasy_win" if won else "fantasy_lose",Color(0.75,0.72,0.65) if won else Color(0.72,0.52,0.54),false,true))
    result_symbol.texture = tex("adventure_win" if won else "adventure_lose")
    result_symbol.visible = true
    result.visible = true
    result.pivot_offset = result.size*0.5
    result.scale = Vector2(0.78,0.78)
    if is_instance_valid(result_tween): result_tween.kill()
    result_tween = create_tween()
    result_tween.tween_property(result,"scale",Vector2.ONE,0.43).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    result_symbol.pivot_offset = result_symbol.size*0.5
    result_symbol.scale = Vector2(0.2,0.2)
    result_tween.parallel().tween_property(result_symbol,"scale",Vector2.ONE,0.53).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    if won and vibration and OS.has_feature("mobile"): Input.vibrate_handheld(180)
    play_again.visible = true
    result_home.visible = true
    next_stage_button.visible = won and stage_index < STAGE_COUNT-1
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
    var art = art_texture("marble_%02d" % index)
    if art != null:
        mat.albedo_texture = art
        mat.albedo_color = Color.WHITE
    mat.rim_enabled = true
    mat.rim = 0.42
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
        unlocked_stage = clampi(int(cfg.get_value("progress","unlocked_stage",0)),0,STAGE_COUNT-1)
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
        var records = cfg.get_value("progress","stage_records",{})
        if records is Dictionary: stage_records = records

func write_save() -> void:
    var cfg = ConfigFile.new()
    cfg.set_value("progress","best",best)
    cfg.set_value("settings","lang",lang)
    cfg.set_value("progress","coins",coins)
    cfg.set_value("progress","unlocked_stage",unlocked_stage)
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
    cfg.set_value("progress","stage_records",stage_records)
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
    b.add_theme_color_override("font_disabled_color",Color("e1e5df"))
    b.add_theme_color_override("font_outline_color",Color("151f1b"))
    b.add_theme_constant_override("outline_size",4)
    b.clip_text = true
    b.add_theme_constant_override("icon_max_width",35)
    b.add_theme_constant_override("h_separation",12)
    b.layout_direction = Control.LAYOUT_DIRECTION_LTR
    b.expand_icon = false
    b.add_theme_constant_override("icon_max_width",30)
    skin_button(b,"green")
    b.pressed.connect(play_ui_sound)
    return b

func royal_style(key: String, round_button: bool = false) -> StyleBox:
    if not royal_textures.has(key):
        var path = "res://assets/royal_ui/" + key + ".svg"
        if ResourceLoader.exists(path):
            royal_textures[key] = load(path)
    var image = royal_textures.get(key) as Texture2D
    if image == null:
        return texture_style("green_round" if round_button else "green_rect",round_button)
    var style = StyleBoxTexture.new()
    style.texture = image
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
        style.set_content_margin(side, 0.0 if round_button else 12.0)
        if not round_button:
            style.set_texture_margin(side, 42.0 if side == SIDE_LEFT or side == SIDE_RIGHT else 16.0)
    return style

func button_surface(fill: Color,edge: Color,pressed: bool = false) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_border_width_all(2)
    style.border_width_bottom = 3 if pressed else 5
    style.set_corner_radius_all(18)
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
        style.set_content_margin(side,11.0)
    style.shadow_color = Color(0,0,0,0.34)
    style.shadow_size = 3 if pressed else 5
    style.shadow_offset = Vector2(0,2 if pressed else 4)
    return style

func imported_style(key: String,tint: Color=Color.WHITE,round_shape: bool=false,frame: bool=false) -> StyleBox:
    var texture = tex(key)
    if texture==null: return texture_style("green_round" if round_shape else "green_rect",round_shape)
    var style = StyleBoxTexture.new()
    style.texture = texture
    style.modulate_color = tint
    if not round_shape:
        var edge = minf(30.0,minf(texture.get_width(),texture.get_height())*0.32)
        if frame: edge = minf(36.0,minf(texture.get_width(),texture.get_height())*0.37)
        for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
            style.set_texture_margin(side,edge)
            style.set_content_margin(side,12.0)
    return style

func skin_button(b: Button, theme_name: String, round_button: bool = false) -> void:
    if round_button:
        b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.add_theme_stylebox_override("normal",imported_style("mobile_circle",Color.WHITE,true))
        b.add_theme_stylebox_override("hover",imported_style("mobile_circle",Color(1.12,1.12,1.12),true))
        b.add_theme_stylebox_override("pressed",imported_style("mobile_circle",Color(0.72,0.72,0.72),true))
        b.add_theme_stylebox_override("disabled",imported_style("mobile_circle",Color(0.5,0.5,0.5),true))
    else:
        var key = "adventure_brown" if theme_name in ["green","gold"] else ("adventure_red" if theme_name=="red" else "adventure_grey")
        var tint = Color(0.80,0.94,0.88) if theme_name=="green" else (Color(0.88,0.91,1.0) if theme_name=="grey" else Color.WHITE)
        b.add_theme_stylebox_override("normal",imported_style(key,tint))
        b.add_theme_stylebox_override("hover",imported_style(key,tint.lightened(0.12)))
        b.add_theme_stylebox_override("pressed",imported_style(key,tint.darkened(0.23)))
        b.add_theme_stylebox_override("disabled",imported_style("adventure_grey",Color(0.48,0.48,0.48)))
    b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())

func panel_style(bg: Color, line: Color, radius: int) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = line
    style.set_border_width_all(3)
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
    panel.add_theme_stylebox_override("panel",imported_style("adventure_panel",Color(0.88,0.88,0.88),false,true))
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
    effect_player = AudioStreamPlayer.new()
    add_child(effect_player)
    for key in ["pickup","bonus","win","fall","lose"]:
        var path = "res://assets/ui/"+key+".wav"
        if ResourceLoader.exists(path): effects[key] = load(path)
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
    hud_panel.add_theme_stylebox_override("panel",imported_style("adventure_panel",Color(0.84,0.84,0.84),false,true))
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
    restart.icon = tex("mobile_retry")
    skin_button(restart,"grey",true)
    restart.pressed.connect(func():
        if is_instance_valid(ball): reset_course())
    menu_button = button(hud,"",Rect2())
    menu_button.icon = tex("mobile_pause")
    skin_button(menu_button,"green",true)
    menu_button.pressed.connect(func(): show_screen("pause"))
    pad = Panel.new()
    hud.add_child(pad)
    pad.add_theme_stylebox_override("panel",royal_style("joystick_base",true))
    pad.modulate = Color(1,1,1,0.94)
    joystick_knob = Panel.new()
    pad.add_child(joystick_knob)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_knob.size = Vector2(78,78)
    joystick_knob.add_theme_stylebox_override("panel",royal_style("joystick_knob",true))
    pad.gui_input.connect(pad_input)
    brake = button(hud,"",Rect2())
    skin_button(brake,"red",true)
    brake.add_theme_stylebox_override("normal",royal_style("brake_idle",true))
    brake.add_theme_stylebox_override("hover",royal_style("brake_idle",true))
    brake.add_theme_stylebox_override("pressed",royal_style("brake_active",true))
    brake.button_down.connect(func(): braking = true; play_ui_sound())
    brake.button_up.connect(func(): braking = brake_touch >= 0)
    gold_flash = label(hud,"",42,Rect2())
    gold_flash.add_theme_color_override("font_color",Color("ffdf83"))
    gold_flash.add_theme_color_override("font_outline_color",Color("192527"))
    gold_flash.add_theme_constant_override("outline_size",5)
    gold_flash.visible = false
    result_backdrop = Panel.new()
    hud.add_child(result_backdrop)
    result_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result_backdrop.visible = false
    result_symbol = TextureRect.new()
    hud.add_child(result_symbol)
    result_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    result_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    result_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result_symbol.visible = false
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
    next_stage_button = action(hud,"next_stage","play",func(): start_stage(stage_index+1),"gold")
    next_stage_button.visible = false

    menu = make_page("main")
    menu_panel = page_panels["main"]
    menu_panel.add_theme_stylebox_override("panel",imported_style("adventure_panel",Color(0.84,0.84,0.84),false,true))
    menu_title = page_titles["main"]
    menu_title.add_theme_font_size_override("font_size",54)
    menu_title.clip_text = false
    menu_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    menu_title.add_theme_color_override("font_outline_color",Color("182a20"))
    menu_title.add_theme_constant_override("outline_size",12)
    menu_title.autowrap_mode = TextServer.AUTOWRAP_OFF
    menu_title.max_lines_visible = 2
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
    action(menu,"levels","play",func(): show_screen("levels"),"gold")
    action(menu,"achievements","check",func(): show_screen("achievements"),"grey")
    for key in ["play","levels","shop","settings","achievements"]:
        var b: Button = actions[key]
        var art_key = "adventure_brown" if key in ["play","levels"] else "adventure_grey"
        var colour = Color(0.88,1.0,0.88) if key=="play" else (Color(0.83,0.93,1.0) if key=="shop" else Color.WHITE)
        b.add_theme_stylebox_override("normal",imported_style(art_key,colour))
        b.add_theme_stylebox_override("hover",imported_style(art_key,colour.lightened(0.12)))
        b.add_theme_stylebox_override("pressed",imported_style(art_key,colour.darkened(0.25)))
        b.icon = load("res://assets/royal_ui/icon_"+key+".svg")
        b.add_theme_constant_override("icon_max_width",49)
        b.add_theme_constant_override("h_separation",18)
        b.add_theme_constant_override("outline_size",2)

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
    for i in range(6):
        var level = button(levels,"",Rect2())
        level.pressed.connect(func(): start_stage(level_page*6+i))
        level_buttons.append(level)
    action(levels,"levels_prev","back",func(): level_page=maxi(0,level_page-1); update_language(),"grey")
    action(levels,"levels_next","play",func(): level_page=mini(3,level_page+1); update_language(),"gold")
    action(levels,"levels_back","back",func(): show_screen("main"),"grey")
    var achievements = make_page("achievements")
    achievement_text = label(achievements,"",28,Rect2())
    achievement_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    action(achievements,"achievements_back","back",func(): show_screen("main"),"grey")
    var about = make_page("about")
    info_text = label(about,"",26,Rect2())
    info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    action(about,"privacy_policy","home",func(): OS.shell_open("https://github.com/mhmmad444410aa-ai/MarbleQuest3D/blob/main/docs/PRIVACY.md"),"grey")
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
    place(pad,30,h-260,224,224)
    place(joystick_knob,73,73,78,78)
    place(brake,w-254,h-260,224,224)
    var ry = h*0.23
    var rw = minf(w-60,550)
    place(result_backdrop,cx-rw*0.5,ry,rw,590)
    place(result_symbol,cx-62,ry+20,124,124)
    place(result,cx-rw*0.5+12,ry+150,rw-24,158)
    place(next_stage_button,cx-rw*0.44,ry+315,rw*0.88,74)
    place(play_again,cx-rw*0.44,ry+397,rw*0.88,74)
    place(result_home,cx-rw*0.44,ry+479,rw*0.88,74)
    place(gold_flash,cx-150,h*0.27,300,70)
    var mh = h-48.0
    var my = 24.0
    place(menu_panel,px,my,pw,mh)
    place(main_balance,bx,my+8,bw,44)
    place(menu_title,px+18,my+57,pw-36,158)
    place(menu_subtitle,px+12,my+226,pw-24,44)
    var by = h*0.53
    var bh = clampf((h-by-88)/5.45,58,108)
    place(menu_play,bx,by,bw,bh)
    place(actions["levels"],bx,by+bh*1.08,bw,bh)
    place(actions["shop"],bx,by+bh*2.16,bw,bh)
    place(actions["settings"],bx,by+bh*3.24,bw,bh)
    place(actions["achievements"],bx,by+bh*4.32,bw,bh)
    place(menu_hint,bx,by+bh*5.32,bw,32)
    actions["settings"].add_theme_font_size_override("font_size",32)
    actions["achievements"].add_theme_font_size_override("font_size",30)
    menu_play.add_theme_font_size_override("font_size",42)
    actions["levels"].add_theme_font_size_override("font_size",33)
    actions["shop"].add_theme_font_size_override("font_size",33)
    if screen == "main":
        place(preview_box,px+pw*0.14,my+278,pw*0.72,maxf(95,by-my-292))

    var sh = 690.0
    var sy = maxf(20,(h-sh)*0.5)
    place(page_panels["shop"],px,sy,pw,sh)
    place(page_titles["shop"],px+10,sy+15,pw-20,60)
    place(balance_label,bx,sy+78,bw,48)
    if screen == "shop":
        place(preview_box,px+pw*0.15,sy+135,pw*0.70,280)
    place(preview_caption,bx,sy+414,bw,60)
    place(actions["previous"],bx,sy+230,68,68)
    place(actions["next"],bx+bw-68,sy+230,68,68)
    for i in range(PRICES.size()):
        place(shop_buttons[i],bx,sy+496,bw,86)
    place(actions["shop_back"],bx,sy+603,bw,65)

    var dh = minf(h-48,1080.0)
    var dy = maxf(20,(h-dh)*0.5)
    place(page_panels["settings"],px,dy,pw,dh)
    place(page_titles["settings"],px+10,dy+15,pw-20,68)
    place(actions["language_title"],bx,dy+94,bw,54)
    var lw = (bw-24)/3.0
    for i in range(3):
        place(language_buttons[i],bx+i*(lw+12),dy+158,lw,70)
    var settings_keys = ["quality","vibration","sound","volume","sensitivity","fps","defaults","about","settings_back"]
    var setting_step = (dh-260.0)/9.0
    for i in range(settings_keys.size()):
        place(actions[settings_keys[i]],bx,dy+244+i*setting_step,bw,setting_step-9.0)
        actions[settings_keys[i]].add_theme_font_size_override("font_size",30)
    for key in ["achievements","about"]:
        var py2 = maxf(20,(h-540)*0.5)
        place(page_panels[key],px,py2,pw,540)
        place(page_titles[key],px+12,py2+18,pw-24,72)
        place(actions[key+"_back"],bx,py2+438,bw,70)
        if key == "achievements": place(achievement_text,bx,py2+105,bw,300)
        if key == "about":
            place(info_text,bx,py2+105,bw,245)
            place(actions["privacy_policy"],bx,py2+360,bw,62)

    var lh = minf(h-48,820.0)
    var ly = (h-lh)*0.5
    place(page_panels["levels"],px,ly,pw,lh)
    place(page_titles["levels"],px+12,ly+15,pw-24,68)
    var step = (lh-230.0)/6.0
    for i in range(6):
        place(level_buttons[i],bx,ly+92+i*step,bw,step-8)
        level_buttons[i].add_theme_font_size_override("font_size",23)
    place(actions["levels_prev"],bx,ly+lh-130,bw*0.48,55)
    place(actions["levels_next"],bx+bw*0.52,ly+lh-130,bw*0.48,55)
    place(actions["levels_back"],bx,ly+lh-66,bw,52)
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
        if next in ["main","shop"]:
            var target_page: Control = pages[next]
            if preview_box.get_parent() != target_page:
                preview_box.reparent(target_page,false)
        preview_world.render_target_update_mode = SubViewport.UPDATE_ALWAYS if next in ["main","shop"] else SubViewport.UPDATE_DISABLED
        if is_instance_valid(preview_pedestal): preview_pedestal.visible = next == "main"
        layout_ui.call_deferred()
    if next == "levels":
        level_page = int(unlocked_stage/6)
        update_language()
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
    balance_label.text = {"en":"GOLD","ar":"الذهب","pt":"OURO"}[lang]+"  "+str(coins)
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
    heading.text = "%02d · %s" % [stage_index+1,STAGE_NAMES[lang][stage_index]]
    help.text = {"en":"Gold +10 · Blue +50 · Finish to bank","ar":"الذهبية +١٠ · الزرقاء +٥٠ · أكمل للحفظ","pt":"Ouro +10 · Azul +50 · Conclua para guardar"}[lang]
    restart.text = ""
    menu_button.text = ""
    brake.text = ""
    brake.tooltip_text = word(29)
    menu_button.tooltip_text = word(3)
    for b in [menu_title,menu_subtitle,main_balance,menu_hint]:
        b.add_theme_color_override("font_outline_color",Color("142a24"))
        b.add_theme_constant_override("outline_size",7)
    play_again.text = word(9)
    result_home.text = word(5)
    menu_title.text = {"en":"MARBLE\nQUEST 3D","ar":"مغامرة الكرة\nثلاثية الأبعاد","pt":"MARBLE\nQUEST 3D"}[lang]
    menu_title.add_theme_font_size_override("font_size",42 if lang=="ar" else 54)
    menu_subtitle.text = EXTRA[lang][2]
    menu_hint.text = {"en":"Collect gold and finish the course to bank it.","ar":"اجمع الذهب وأكمل المرحلة لحفظه.","pt":"Colete ouro e conclua a fase para guardá-lo."}[lang]
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
    for i in range(level_buttons.size()):
        var idx = level_page*6+i
        var level_button: Button = level_buttons[i]
        var record: Dictionary = stage_records.get(str(idx),{})
        var stars = int(record.get("stars",0))
        level_button.text = "%02d  ·  %s  %s" % [idx+1,STAGE_NAMES[lang][idx],"★".repeat(stars)]
        level_button.disabled = idx > unlocked_stage
        level_button.icon = tex("lock" if idx > unlocked_stage else "play")
    actions["levels_prev"].text = more(13)
    actions["levels_next"].text = more(12)
    actions["levels_prev"].disabled = level_page==0
    actions["levels_next"].disabled = level_page==3
    page_titles["levels"].text = more(0)+"  "+str(level_page+1)+"/4"
    for control in ui_root.find_children("*","Control",true,false):
        if control is Label or control is Button:
            control.text_direction = Control.TEXT_DIRECTION_RTL if lang=="ar" else Control.TEXT_DIRECTION_LTR
    next_stage_button.text = {"en":"NEXT COURSE","ar":"المرحلة التالية","pt":"PRÓXIMA FASE"}[lang]
    for key in ["levels","achievements","about"]:
        actions[key+"_back"].text = word(6)
    actions["sound"].text = more(2)+"  •  "+word(20 if sound_on else 21)
    actions["volume"].text = more(3)+"  •  "+str(int(sound_volume*100))+"%"
    actions["sensitivity"].text = more(4)+"  •  "+str(int(sensitivity*100))+"%"
    actions["fps"].text = more(5)+"  •  "+str(fps)
    actions["defaults"].text = more(6)
    actions["about"].text = more(7)
    info_text.text = more(8)
    actions["privacy_policy"].text = {"en":"Privacy Policy","ar":"سياسة الخصوصية","pt":"Política de Privacidade"}[lang]
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
    if event is InputEventScreenDrag and event.index == touch_id and not menu_open and not finished:
        move = ((event.position-pad.global_position-touch_start)*sensitivity/75.0).limit_length(1.0)
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

func collect_gold(amount: int) -> void:
    run_gold += amount
    if is_instance_valid(gold_tween): gold_tween.kill()
    gold_flash.text = "+%d  ◈" % amount
    gold_flash.modulate = Color.WHITE
    gold_flash.visible = true
    gold_flash.scale = Vector2(0.7,0.7)
    gold_flash.pivot_offset = gold_flash.size*0.5
    gold_tween = create_tween()
    gold_tween.tween_property(gold_flash,"scale",Vector2.ONE,0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    gold_tween.tween_interval(0.45)
    gold_tween.tween_property(gold_flash,"modulate:a",0.0,0.32)
    gold_tween.tween_callback(func(): gold_flash.visible=false)

func play_effect(key: String) -> void:
    if sound_on and sound_volume>0.0 and effects.has(key):
        effect_player.stream = effects[key]
        effect_player.volume_db = linear_to_db(sound_volume*0.8)
        effect_player.play()

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
    var total_stars = 0
    for record in stage_records.values():
        total_stars += int(record.get("stars",0))
    achievement_text.text = "%s: %d/24\n\n★ %d/72\n\n%s: %.1fs\n\n%s: %d" % [more(9),stage_records.size(),total_stars,more(10),best,more(16),earned_total]

func setup_preview() -> void:
    var root = Node3D.new()
    preview_world.add_child(root)
    var light = DirectionalLight3D.new()
    root.add_child(light)
    light.rotation_degrees = Vector3(-35,-35,0)
    light.light_energy = 0.90
    var env_node = WorldEnvironment.new()
    var env = Environment.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("dbe8e4")
    env.ambient_light_energy = 0.56
    env_node.environment = env
    root.add_child(env_node)
    var cam = Camera3D.new()
    root.add_child(cam)
    cam.fov = 43.0
    cam.position = Vector3(0,0.72,4.5)
    cam.look_at(Vector3.ZERO)
    cam.current = true
    preview_mesh = marble_visual(root,2.1)
    preview_pedestal = Node3D.new()
    root.add_child(preview_pedestal)
    preview_pedestal.visible = screen == "main"
    refresh_preview()

func select_preview(delta: int) -> void:
    preview_index = posmod(preview_index+delta,PRICES.size())
    refresh_shop()

func refresh_preview() -> void:
    if not is_instance_valid(preview_mesh): return
    var mat = skin_material(equipped if screen == "main" else preview_index)
    for part in preview_mesh.find_children("*","MeshInstance3D",true,false):
        part.material_override = mat

func _process(delta: float) -> void:
    if screen == "main" or screen == "play":
        visual_clock += delta
        for i in range(cloud_nodes.size()):
            if is_instance_valid(cloud_nodes[i]):
                cloud_nodes[i].position.x = cloud_origins[i].x + sin(visual_clock*0.14+float(i))*2.6
    if is_instance_valid(preview_mesh) and screen in ["shop","main"]:
        preview_mesh.rotate_y(delta*0.7)
    if is_instance_valid(ball_visual) and screen == "main":
        ball_visual.rotate_y(delta*0.45)
    if is_instance_valid(brake):
        brake.modulate = Color(1.15,1.15,1.15) if braking else Color.WHITE
    if is_instance_valid(joystick_knob) and not menu_open and not finished:
        var target = (pad.size-joystick_knob.size)*0.5+move*54.0
        joystick_knob.position = joystick_knob.position.lerp(target,1.0-exp(-delta*20.0))
