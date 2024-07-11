extends RigidBody3D

var forza=0
func set_force(forza_new):
	forza=forza_new
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	state.apply_torque(transform.basis * Vector3(0,0,forza))
	pass
