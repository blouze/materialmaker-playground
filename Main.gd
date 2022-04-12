extends Spatial

onready var camera = $Camera
onready var mesh = $MeshInstance

onready var dest_transform :Transform = mesh.transform
export (float, 1, 5) var speed = 1.5
export (int, 10, 100) var inertia = 50

onready var dest_rot :float
export (float, 0.0, 0.02) var rot_incr = 0.01
export (String) var prop_name = "o8100_n_rot"


func _ready():
	var mat = mesh.get_active_material(0)
	dest_rot = mat.get_shader_param(prop_name)

func _physics_process(delta):
	if Input.is_action_pressed("move_left"):
		dest_transform.basis = dest_transform.basis.rotated(Vector3.UP, -delta * speed)
	if Input.is_action_pressed("move_right"):
		dest_transform.basis = dest_transform.basis.rotated(Vector3.UP, delta * speed)
	if Input.is_action_pressed("move_up"):
		dest_transform.basis = dest_transform.basis.rotated(Vector3.RIGHT, -delta * speed)
	if Input.is_action_pressed("move_down"):
		dest_transform.basis = dest_transform.basis.rotated(Vector3.RIGHT, delta * speed)
	
	mesh.transform = mesh.transform.interpolate_with(dest_transform, 1.0 / inertia)
	
	var mat = mesh.get_active_material(0)
#	if Input.is_action_pressed("cam_left"):
#	if Input.is_action_pressed("cam_right"):
	if Input.is_action_pressed("cam_up"):
		dest_rot += rot_incr
	if Input.is_action_pressed("cam_down"):
		dest_rot -= rot_incr
	
	var rot = mat.get_shader_param(prop_name)
	mat.set_shader_param(prop_name, lerp(rot, dest_rot, 1.0 / inertia))


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
