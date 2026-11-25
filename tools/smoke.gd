extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    if not is_instance_valid(scene.ball) or not is_instance_valid(scene.camera) or scene.packed.size() != 5 or scene.orbs.size() != 3:
        push_error("Smoke: missing scene components")
        quit(1)
        return
    scene.set_menu(false)
    for i in range(100):
        await physics_frame
    if scene.ball.position.y < 0.15 or scene.falls != 0:
        push_error("Smoke: start platform collision failed")
        quit(1)
        return
    var start_z = scene.ball.position.z
    scene.move = Vector2(0,-0.6)
    for i in range(20):
        await physics_frame
    scene.move = Vector2.ZERO
    if scene.ball.position.z >= start_z - 0.1:
        push_error("Smoke: movement failed")
        quit(1)
        return
    for language in ["ar","pt","en"]:
        scene.lang = language
        scene.update_language()
        if scene.heading.text.is_empty():
            quit(1)
            return
    scene.set_menu(true)
    if not scene.menu.visible or scene.hud.visible:
        quit(1)
        return
    scene.set_menu(false)
    scene.reset_course()
    await process_frame
    if scene.count != 0 or scene.finished or not is_instance_valid(scene.ball):
        quit(1)
        return
    print("SMOKE_OK")
    quit(0)
