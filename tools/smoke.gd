extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    if not is_instance_valid(scene.ball) or not is_instance_valid(scene.camera) or scene.packed.size() < 16 or scene.orbs.size() != 3:
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
    # Verify actual rolling through the widened moving bridge, not just scene load.
    scene.ball.position = Vector3(0,1.3,-9)
    scene.ball.linear_velocity = Vector3.ZERO
    scene.ball.angular_velocity = Vector3.ZERO
    for i in range(30):
        await physics_frame
    scene.move = Vector2(0,-0.8)
    for i in range(240):
        await physics_frame
        if scene.ball.position.z < -16.5:
            break
    scene.move = Vector2.ZERO
    if scene.ball.position.z >= -16.5 or scene.falls != 0 or scene.lives != 3:
        push_error("Smoke: actual bridge crossing failed at " + str(scene.ball.position))
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/royal_ui/joystick_base.svg") or not ResourceLoader.exists("res://assets/royal_ui/brake_active.svg") or scene.royal_textures.size() < 4:
        push_error("Smoke: royal UI artwork not imported")
        quit(1)
        return
    for i in range(12):
        var art = scene.art_texture("marble_%02d" % i)
        if art == null or art.get_width() != 2048 or scene.skin_material(i).albedo_texture == null:
            push_error("Smoke: HD marble material missing " + str(i))
            quit(1)
            return
    if scene.art_texture("stone_normal") == null or scene.cloud_nodes.size() != 12 or not ResourceLoader.exists("res://assets/material_shaders/waterfall.gdshader"):
        push_error("Smoke: enhanced environment missing")
        quit(1)
        return
    print("HD_MATERIALS_OK")
    for key in ["adventure_brown","adventure_grey","adventure_red","adventure_panel","adventure_win","adventure_lose","fantasy_win","fantasy_lose","mobile_circle","mobile_retry","mobile_pause"]:
        if scene.tex(key)==null:
            push_error("Missing imported UI "+key)
            quit(1)
            return
    print("IMPORTED_UI_OK")
    print("BRIDGE_AND_ROYAL_UI_OK")
    for language in ["ar","pt","en"]:
        scene.lang = language
        scene.update_language()
        await process_frame
        scene.layout_ui()
        await process_frame
        if scene.heading.text.is_empty() or not scene.hud_panel.get_rect().encloses(scene.heading.get_rect()) or not scene.hud_panel.get_rect().encloses(scene.help.get_rect()) or not scene.menu_panel.get_rect().encloses(scene.menu_title.get_rect()) or not scene.menu_panel.get_rect().encloses(scene.menu_subtitle.get_rect()) or scene.pad.get_rect().intersects(scene.brake.get_rect()):
            push_error("Smoke failed: if scene.heading.text.is_empty() or not scene.hud_panel.get_rect().encloses(scene.heading.get_rect()) or not scene.hud_panel.get_rect().encloses(scene.help.get_rect()) or not scene.menu_panel.get_rect().encloses(scene.menu_title.get_rect()) or not scene.menu_panel.get_rect().encloses(scene.menu_subtitle.get_rect()) or scene.pad.get_rect().intersects(scene.brake.get_rect()):")
            quit(1)
            return
    scene.set_menu(true)
    if not scene.menu.visible or scene.hud.visible:
        push_error("Smoke failed: if not scene.menu.visible or scene.hud.visible:")
        quit(1)
        return
    scene.set_menu(false)
    scene.reset_course()
    await process_frame
    if scene.count != 0 or scene.finished or not is_instance_valid(scene.ball):
        push_error("Smoke failed: if scene.count != 0 or scene.finished or not is_instance_valid(scene.ball):")
        quit(1)
        return
    if scene.lives != 3 or scene.tex("pause") == null or scene.tex("green_rect") == null:
        push_error("Smoke: attempts or real UI sprites missing")
        quit(1)
        return
    scene.show_screen("pause")
    if not scene.menu_open or not scene.ball.freeze or not scene.pages["pause"].visible:
        push_error("Smoke failed: if not scene.menu_open or not scene.ball.freeze or not scene.pages[\"pause\"].visible:")
        quit(1)
        return
    var paused_time = scene.elapsed
    for i in range(4):
        await physics_frame
    if scene.elapsed != paused_time:
        push_error("Smoke failed: if scene.elapsed != paused_time:")
        quit(1)
        return
    scene.show_screen("settings")
    if not scene.pages["settings"].visible or scene.pages["pause"].visible:
        push_error("Smoke failed: if not scene.pages[\"settings\"].visible or scene.pages[\"pause\"].visible:")
        quit(1)
        return
    scene.show_screen("shop")
    if not scene.pages["shop"].visible or scene.shop_buttons.size()!=12:
        push_error("Smoke failed: if not scene.pages[\"shop\"].visible or scene.shop_buttons.size()!=12:")
        quit(1)
        return
    scene.coins = 800
    # Preserve Array[int]; assigning an untyped literal through a dynamic Node fails.
    scene.owned.clear()
    scene.owned.append(0)
    scene.equipped = 0
    scene.preview_index = 0
    if scene.audio_player.stream == null or scene.effects.size()!=5 or scene.effects.has("roll"):
        push_error("Smoke: bundled UI click not loaded")
        quit(1)
        return
    scene.select_preview(11)
    if scene.preview_index != 11 or not is_instance_valid(scene.preview_mesh):
        push_error("Smoke failed: if scene.preview_index != 11 or not is_instance_valid(scene.preview_mesh):")
        quit(1)
        return
    scene.select_preview(1)
    if scene.preview_index != 0:
        push_error("Smoke failed: if scene.preview_index != 0:")
        quit(1)
        return
    scene.buy_or_equip(1)
    if scene.coins != 150 or not scene.owned.has(1) or scene.equipped != 1:
        push_error("Smoke failed: if scene.coins != 150 or not scene.owned.has(1) or scene.equipped != 1:")
        quit(1)
        return
    scene.buy_or_equip(1)
    scene.buy_or_equip(11)
    if scene.coins != 150 or scene.owned.has(11) or scene.equipped != 1:
        push_error("Smoke failed: if scene.coins != 150 or scene.owned.has(11) or scene.equipped != 1:")
        quit(1)
        return
    scene.show_screen("play")
    for i in range(3):
        scene.respawn_guard = 0.0
        scene.lose_attempt()
        await process_frame
        scene.lose_attempt()
        if scene.lives != 2-i:
            push_error("Smoke failed: if scene.lives != 2-i:")
            quit(1)
            return
    scene.lose_attempt()
    if scene.lives != 0 or not scene.finished or scene.won or not scene.result.visible:
        push_error("Smoke failed: if scene.lives != 0 or not scene.finished or scene.won or not scene.result.visible:")
        quit(1)
        return
    scene.reset_course()
    if scene.lives != 3 or scene.finished:
        push_error("Smoke failed: if scene.lives != 3 or scene.finished:")
        quit(1)
        return
    scene.run_gold = 30
    scene.finish_course()
    var awarded = scene.coins
    scene.finish_course()
    if not scene.won or awarded != 180 or scene.coins != awarded:
        push_error("Smoke failed: if not scene.won or awarded != 180 or scene.coins != awarded:")
        quit(1)
        return
    # Real physics traversal from spawn through all mandatory pickups and the final gate,
    # on every course; do not manually invoke finish_course for this regression.
    for stage in range(24):
        scene.start_stage(stage)
        var gold_before: int = scene.coins
        await process_frame
        if scene.route_points.size()<6 or scene.stage_index!=stage:
            push_error("Stage data or progression failed "+str(stage))
            quit(1)
            return
        if stage>=2:
            for j in range(scene.route_points.size()-1):
                var a: Vector3 = scene.route_points[j]
                var b: Vector3 = scene.route_points[j+1]
                var point: Vector3 = scene.secret_origin
                var clearance = Geometry2D.get_closest_point_to_segment(Vector2(point.x,point.z),Vector2(a.x,a.z),Vector2(b.x,b.z)).distance_to(Vector2(point.x,point.z))
                if clearance<5.0:
                    push_error("Blue bonus overlaps mandatory route "+str(stage+1))
                    quit(1)
                    return
        if stage>=3 and scene.challenge_count<1:
            push_error("Challenge course missing hazards "+str(stage+1))
            quit(1)
            return
        var waypoint = 1
        for tick in range(5400):
            await physics_frame
            if scene.finished: break
            var target: Vector3 = scene.route_points[waypoint]
            var error = Vector2(target.x-scene.ball.position.x,target.z-scene.ball.position.z)
            if error.length()<0.65 and waypoint<scene.route_points.size()-1:
                waypoint+=1
                target=scene.route_points[waypoint]
                error=Vector2(target.x-scene.ball.position.x,target.z-scene.ball.position.z)
            var velocity = Vector2(scene.ball.linear_velocity.x,scene.ball.linear_velocity.z)
            scene.move = (error*0.8-velocity*0.40).limit_length(0.9)
        scene.move = Vector2.ZERO
        if not scene.won or scene.count != 3 or scene.falls != 0 or scene.lives != 3:
            push_error("Full route failed stage %d at %s waypoint %d pickups %d falls %d" % [stage+1,str(scene.ball.position),waypoint,scene.count,scene.falls])
            quit(1)
            return
        if scene.art_texture("deck_%02d" % stage)==null or scene.art_texture("deck_normal_%02d" % stage)==null:
            push_error("Missing distinct deck artwork "+str(stage))
            quit(1)
            return
        if scene.secret_claimed or scene.run_gold != 30 or scene.coins != gold_before+30:
            push_error("Gold reward failed stage %d: run=%d banked=%d blue=%s" % [stage+1,scene.run_gold,scene.coins-gold_before,str(scene.secret_claimed)])
            quit(1)
            return
        print("FULL_COURSE_OK ",stage+1)
    scene.start_stage(2)
    await process_frame
    var bonus_before: int = scene.coins
    scene.ball.position = scene.secret_origin+Vector3(0,1.1,0)
    scene.ball.linear_velocity = Vector3.ZERO
    for i in range(60):
        await physics_frame
        if scene.secret_claimed: break
    if not scene.secret_claimed or scene.run_gold!=50 or scene.coins!=bonus_before:
        push_error("Blue bonus economy failed")
        quit(1)
        return
    print("BLUE_BONUS_OK")
    if scene.stage_records.size()!=24:
        push_error("Stage records missing")
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/royal_ui/launcher.webp"):
        push_error("Approved launcher icon missing")
        quit(1)
        return
    for key in ["gold_metal","moss","crystal"]:
        if scene.art_texture(key) == null:
            push_error("New material missing "+key)
            quit(1)
            return
    print("SMOKE_OK")
    quit(0)
