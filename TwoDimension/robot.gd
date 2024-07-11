extends Node3D
 
var vl : float = 0
var vr : float = 0
var theRobot
var left_front_wheel : RigidBody3D
var right_front_wheel : RigidBody3D
var flag
var iter=0
# Keyboard state
var _up = false
var _down = false
var _right = false
var _left = false

var counter_speed= 0
var counter_degree=0

var motor_left
var motor_right

var total_time=0

const PID = preload("res://PID.gd")
var my_pid_angular
var my_pid_torque

var my_proportional_linear
var my_proportional_angular

var prec_x
var prec_z

# Called when the node enters the scene tree for the first time.
func _ready():
	
	theRobot = $Body
	left_front_wheel = $LeftWheel
	right_front_wheel = $RightWheel
	
	motor_left=$LeftWheel/LeftMotor
	motor_right=$RightWheel/RightMotor
	
	my_pid_angular=PID.new()
	my_pid_angular.create_pid(0.3, 0, 0, PI/4)
	my_pid_torque=PID.new()
	my_pid_torque.create_pid(0.05,0.01, 0, 0.2)
	
	my_proportional_linear=PID.new()
	my_proportional_linear.create_pid(0.5,0,0, 0.4)
	my_proportional_angular=PID.new()
	my_proportional_angular.create_pid(1, 0, 0, PI/4)
	
	prec_x=$Body.position.x
	prec_z=$Body.position.z
	
func _input(event):
	if event is InputEventKey:
		match event.keycode:
			KEY_UP:
				_up=event.pressed
			KEY_DOWN:
				_down=event.pressed
			KEY_LEFT:
				_left=event.pressed
			KEY_RIGHT:
				_right=event.pressed
		

func rotate_front_steer(degree):
	var left = $LeftMotor 
	var right = $RightMotor
	var ruota_left= $LeftWheel
	var ruota_right= $RightWheel

	var parent = $Body
	
	# Rotazione desiderata rispetto al nodo padre
	var desired_rotation_degrees = Vector3(0,180*degree/PI, 0)
	
	# Converti la rotazione desiderata in un Basis (matrice di rotazione)
	var desired_rotation_basis = Basis(Vector3(0,1,0),degree)
	
	# Ottieni la trasformazione del nodo padre
	var parent_transform = parent.global_transform
	
	# Imposta la rotazione del nodo figlio combinando la rotazione del nodo padre con quella desiderata
	
	left.global_transform.basis = parent_transform.basis * desired_rotation_basis
	right.global_transform.basis = parent_transform.basis * desired_rotation_basis
	
	
	ruota_left.global_transform.basis = parent_transform.basis * desired_rotation_basis
	ruota_right.global_transform.basis = parent_transform.basis * desired_rotation_basis
	
func apply_forces(value):
	left_front_wheel.set_force(value)
	right_front_wheel.set_force(value)

func _physics_process(_delta):

	rotate_front_steer(counter_degree)
	apply_forces(counter_speed)
	pass


func _process(_delta):
	var speed= (_up as float) - (_down as float)
	
	var degree=(_left as float) - (_right as float)
	
	var target_x=0.9
	
	
	var target_z=0
	
	var dx = target_x-$Body.global_position.x
	var dz = target_z-$Body.global_position.z 
	
	var _x = prec_x - $Body.global_position.x
	var _z = prec_z - $Body.global_position.z
	
	prec_x= $Body.global_position.x
	prec_z= $Body.global_position.z
	
	var direction=1
	
	var _distance=sqrt(_x * _x + _z * _z)
	var current_speed=_distance/_delta
	
	# di base va da 0 a 180 e poi da -180 a 0 
	var heading_angle=$Body.global_rotation.y + PI
	if heading_angle>PI/2 and heading_angle<3*PI/2 and dx>0:
		dx=dx+0.143
		pass
	else :
		direction=-1 
		dx=dx-0.143
		dz=dz-0.108
	var target_heading= atan2(dz,dx)
	
	if dx>=0 and dz>=0:
		target_heading=target_heading+PI/2
	elif dx<0 and dz>=0:
		target_heading=target_heading-PI/2
	elif  dx>=0 and dz<0:
		target_heading=target_heading+ 3*PI/2
	elif dx<0 and dz<0:
		target_heading=target_heading+ 2*PI + PI/2
		
	var angle=target_heading
	
	var distance=sqrt(dx * dx + dz * dz)
	
	#while angle>2*PI:
		#angle= angle - 2*PI
	#while angle <- PI:
		#angle= angle + 2*PI
	
	distance=distance*direction
	speed=current_speed*direction
	var v_target = my_proportional_linear.PID_evaluate_error(_delta, distance)
	
	#primo pid che ha in input quanto il corpo deve ruotare e da in output a quanto si devono ruotare le ruote
	if direction==-1:
		angle=angle-PI
	var w_target = my_proportional_angular.PID_evaluate(_delta, angle,heading_angle)
	
	if w_target/PI*180>15 or w_target/PI*180<-15:
		print("w_target: ",w_target/PI*180) 
	
	
	counter_degree=w_target*direction
	counter_speed = my_pid_torque.PID_evaluate(_delta, v_target, current_speed)
	
	counter_speed=-counter_speed
	

func _integrate_forces(state):
	pass
