extends SceneTree

var checks := 0
var failures := 0
var now_ms:=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func key(scene, code: int, pressed := true, echo := false) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = echo
    scene._input(event)
func reset(scene) -> void:
    for code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_J,KEY_L,KEY_I,KEY_K,KEY_ESCAPE]:key(scene,code,false)
    scene.held.clear()
    scene.session.restart()
    scene.sync_voice_context()
func tick(scene, seconds := 0.1) -> void:
    now_ms+=roundi(seconds*1000)
    scene._physics_process(seconds)
func run() -> void:
    var scene = load("res://scenes/main.tscn").instantiate()
    var settings := OS.get_cache_dir().path_join("stuntcar-keyboard-%d.cfg" % OS.get_process_id())
    DirAccess.remove_absolute(settings)
    scene.control_clock=func():return now_ms
    scene.settings_path = settings
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.session.sound_enabled = false
    reset(scene)
    key(scene, KEY_W)
    tick(scene)
    check(scene.model.target_speed_mps > 22.0 and scene.model.speed_mps > 22.0, "W accelerates the actual car.")
    var first: float = scene.model.target_speed_mps
    tick(scene)
    check(scene.model.target_speed_mps > first, "A held gas key continues to accelerate.")
    key(scene, KEY_W, false)
    var released: float = scene.model.target_speed_mps
    tick(scene)
    check(is_equal_approx(scene.model.target_speed_mps, released), "Release stops the pedal input.")
    reset(scene)
    key(scene, KEY_UP)
    tick(scene)
    check(scene.model.target_speed_mps > 22.0, "Up also accelerates.")
    key(scene, KEY_A)
    tick(scene)
    check(scene.model.last_command == -1 and scene.model.target_speed_mps > 22.0, "Gas and a turn work together.")
    reset(scene)
    key(scene, KEY_W)
    key(scene, KEY_S)
    tick(scene)
    check(is_equal_approx(scene.model.target_speed_mps, 22.0), "Opposite pedals cancel each other.")
    reset(scene)
    scene.model.target_speed_mps = 46.0
    key(scene, KEY_S)
    tick(scene)
    check(scene.model.speed_mps < 22.0 and scene.model.boost_remaining == 0.0, "S brakes immediately despite a higher old target.")
    for i in range(20): tick(scene)
    check(is_zero_approx(scene.model.speed_mps) and is_zero_approx(scene.model.target_speed_mps), "A held brake stops the car.")
    key(scene, KEY_S, false)
    scene.session.submit_voice("slower")
    check(is_zero_approx(scene.model.target_speed_mps), "Slower does not start a car stopped with the keyboard.")
    scene.model.speed_mps = 8.0
    scene.model.target_speed_mps = 8.0
    scene.session.submit_voice("slower")
    check(scene.model.target_speed_mps < 8.0, "Slower decreases a low target set by the keyboard.")
    scene.model.speed_mps = 0.0
    scene.model.target_speed_mps = 0.0
    key(scene, KEY_W)
    tick(scene)
    check(scene.model.speed_mps > 0.0 and not scene.model.emergency_braking, "W starts the stopped car again.")
    reset(scene)
    scene.model.change_speed(1, 0.9)
    key(scene, KEY_DOWN)
    tick(scene)
    check(scene.model.boost_remaining == 0.0 and scene.model.speed_mps < 22.0, "Down brakes and cancels a turbo.")
    reset(scene)
    key(scene, KEY_LEFT)
    tick(scene)
    check(scene.model.last_command == -1, "Very easy preserves the explicit left direction.")
    reset(scene)
    key(scene, KEY_RIGHT)
    tick(scene)
    check(scene.model.last_command == 1, "Right arrow turns right.")
    reset(scene)
    key(scene, KEY_W)
    tick(scene)
    key(scene, KEY_ESCAPE)
    tick(scene)
    var paused: float = scene.model.target_speed_mps
    scene.session.activate(0)
    tick(scene)
    check(is_equal_approx(scene.model.target_speed_mps, paused), "A pedal held before pause does not restart after resume.")
    reset(scene)
    key(scene, KEY_W)
    scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    tick(scene)
    check(scene.held.is_empty() and scene.session.state == "PAUSED", "Window focus loss clears the pedals.")
    scene.session.go_to_menu()
    scene.sync_voice_context()
    key(scene, KEY_W)
    tick(scene)
    check(scene.session.state == "MENU" and scene.model.target_speed_mps == 22.0, "Gas does not start a drive from a menu.")
    check(scene.get("key_faster") != null and scene.get("key_slower") != null, "Both speed keys can be assigned.")
    if scene.get("key_faster") != null:
        scene.on_action("rebind")
        scene.capture_binding(KEY_J)
        scene.capture_binding(KEY_L)
        check(scene.binding_stage == 3 and scene.key_left == KEY_A, "Partial assignment keeps all old keys.")
        scene.capture_binding(KEY_I)
        scene.capture_binding(KEY_I)
        check(scene.binding_stage == 4, "A duplicate brake key does not complete the assignment.")
        scene.capture_binding(KEY_K)
        check(scene.binding_stage == 0 and scene.key_left == KEY_J and scene.key_right == KEY_L and scene.key_faster == KEY_I and scene.key_slower == KEY_K, "Four distinct keys commit together.")
        reset(scene)
        key(scene, KEY_I)
        tick(scene)
        check(scene.model.speed_mps > 22.0, "A custom gas key drives the car.")
        scene.ui.render(scene.session)
        check("I" in scene.ui.keys_label.text and "K" in scene.ui.keys_label.text, "The drive display shows the assigned speed keys.")
        scene.save_settings()
        var stored := ConfigFile.new()
        stored.load(settings)
        check(stored.get_value("input", "faster") == KEY_I and stored.get_value("input", "slower") == KEY_K, "Speed keys persist in the settings.")
        scene.key_left = KEY_A
        scene.key_right = KEY_D
        scene.key_faster = KEY_W
        scene.key_slower = KEY_S
        scene.load_settings()
        check(scene.key_faster == KEY_I and scene.key_slower == KEY_K, "Settings restore the speed keys.")
        var legacy := ConfigFile.new()
        legacy.set_value("input", "left", KEY_W)
        legacy.set_value("input", "right", KEY_S)
        legacy.save(settings)
        scene.load_settings()
        check(scene.key_left == KEY_W and scene.key_right == KEY_S, "A legacy steering assignment survives.")
        check(scene.key_faster != KEY_W and scene.key_faster != KEY_S and scene.key_slower != KEY_W and scene.key_slower != KEY_S and scene.key_faster != scene.key_slower, "Legacy steering keys do not conflict with new speed keys.")
    scene.queue_free()
    for i in range(3): await process_frame
    DirAccess.remove_absolute(settings)
    print("KEYBOARD SPEED: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
