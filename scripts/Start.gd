extends Node

var webxr_interface
var vr_supported = false

# A constant to define the dead zone for both the trackpad and the joystick.
# See https://web.archive.org/web/20191208161810/http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html
# for more information on what dead zones are, and how we are using them in this project.
const CONTROLLER_DEADZONE = 0.65
const MOVEMENT_SPEED = 1.5

func _ready():
	webxr_interface = ARVRServer.find_interface("WebXR")
	if webxr_interface:
		webxr_interface.xr_standard_mapping = true
	 
		webxr_interface.connect("session_supported", self, "_webxr_session_supported")
		webxr_interface.connect("session_started", self, "_webxr_session_started")
		webxr_interface.connect("session_ended", self, "_webxr_session_ended")
		webxr_interface.connect("session_failed", self, "_webxr_session_failed")
		
		webxr_interface.connect("select", self, "_webxr_on_select")
		
		webxr_interface.is_session_supported("immersive-vr")

func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == 'immersive-vr':
		vr_supported = supported

func start_VR_session():
	# We want an immersive VR session, as opposed to AR ('immersive-ar') or a
	# simple 3DoF viewer ('viewer').
	webxr_interface.session_mode = 'immersive-vr'
	# 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
	# experience (it puts you 1.6m above the ground if you have 3DoF headset),
	# whereas as 'local' puts you down at the ARVROrigin.
	# This list means it'll first try to request 'bounded-floor', then 
	# fallback on 'local-floor' and ultimately 'local', if nothing else is
	# supported.
	webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	# In order to use 'local-floor' or 'bounded-floor' we must also
	# mark the features as required or optional.
	webxr_interface.required_features = 'local-floor'
	webxr_interface.optional_features = 'bounded-floor'
 
	# This will return false if we're unable to even request the session,
	# however, it can still fail asynchronously later in the process, so we
	# only know if it's really succeeded or failed when our 
	# _webxr_session_started() or _webxr_session_failed() methods are called.
	if not webxr_interface.initialize():
		OS.alert("Failed to initialize")
		return

func _webxr_session_started() -> void:
	$UI.visible = false
	# This tells Godot to start rendering to the headset.
	get_viewport().arvr = true
	# This will be the reference space type you ultimately got, out of the
	# types that you requested above. This is useful if you want the game to
	# work a little differently in 'bounded-floor' versus 'local-floor'.
	print ("Reference space type: " + webxr_interface.reference_space_type)
 
func _webxr_session_ended() -> void:
	$UI.visible = true
	# If the user exits immersive mode, then we tell Godot to render to the web
	# page again.
	get_viewport().arvr = false
 
func _webxr_session_failed(message: String) -> void:
	OS.alert("Failed to initialize: " + message)

func _on_Button_pressed():
	if not vr_supported:
		OS.alert("Your browser doesn't support VR")
		return
	start_VR_session()

func _webxr_on_select(controller_id: int):
	get_tree().reload_current_scene()
	$UI.visible = false

func _on_ARVRControllerR_button_pressed(button):
	print ("Mano Derecha PRESS: " + button)
	get_tree().reload_current_scene()
	$UI.visible = false
