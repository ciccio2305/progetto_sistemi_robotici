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
var punto =preload("res://punto.tscn")

signal start

var my_pid_angular
var my_pid_torque

var my_proportional_linear
var my_proportional_angular

var prec_x
var prec_z
var list_of_point=[]
var current_target=0

var stay_still=true
var prec_direction
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
	my_pid_torque.create_pid(1,0.05, 0, 0.2)
	
	my_proportional_linear=PID.new()
	my_proportional_linear.create_pid(0.5,0,0,1)
	my_proportional_angular=PID.new()
	my_proportional_angular.create_pid(1, 0, 0, PI/4)
	
	prec_x=$Body.position.x
	prec_z=$Body.position.z
	
	stay_still=true 
	prec_direction=1
	list_of_point.append([$Body.global_position.x,$Body.global_position.y])
	
	

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json)
	print("here")
	for x in json["points"]:
		list_of_point.append([x[0]/100 * 18 -9,x[1]/100 * 18 -9])
	
	for x in list_of_point:
		var new_punto=punto.instantiate()
		self.add_child(new_punto)
		#get_tree().get_root().get_child(0).add_child(new_punto)
		new_punto.global_position.x=x[0]
		new_punto.global_position.y=0.117
		new_punto.global_position.z=x[1]
	print(list_of_point)
	#self.global_position.x=list_of_point[1][0]
	#self.global_position.z=list_of_point[1][1]
	stay_still=false 
	current_target=2
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
				$HTTPRequest.request("http://localhost:5000/get_path")
				print("here")
				_right=event.pressed
		

func rotate_front_steer(degree):
	var left = $LeftMotor 
	var right = $RightMotor
	var ruota_left= $LeftWheel
	var ruota_right= $RightWheel

	var parent = $Body
	
	#raggio di curvatura 
	var R=(0.145*2)/tan(degree)
	

	# Converti la rotazione desiderata in un Basis (matrice di rotazione)
	var desired_rotation_basis = Basis(Vector3(0,1,0),degree)
	var desired_rotation_basis_outer = Basis(Vector3(0,1,0), atan(0.290/(R+0.2)) )
	# Ottieni la trasformazione del nodo padre
	var parent_transform = parent.global_transform
	#
	#print("inner: ",degree/PI*180)
	#print("outer: ", atan(0.290/(R+0.2))/PI*180)
	# Imposta la rotazione del nodo figlio combinando la rotazione del nodo padre con quella desiderata
	
	if(degree>0):
		left.global_transform.basis = parent_transform.basis * desired_rotation_basis
		ruota_left.global_transform.basis = parent_transform.basis * desired_rotation_basis
	
		right.global_transform.basis = parent_transform.basis * desired_rotation_basis_outer
		ruota_right.global_transform.basis = parent_transform.basis * desired_rotation_basis_outer
		
	else:
		left.global_transform.basis = parent_transform.basis * desired_rotation_basis_outer
		ruota_left.global_transform.basis = parent_transform.basis * desired_rotation_basis_outer
	
		right.global_transform.basis = parent_transform.basis * desired_rotation_basis
		ruota_right.global_transform.basis = parent_transform.basis * desired_rotation_basis
		
func apply_forces(value):
	left_front_wheel.set_force(value)
	right_front_wheel.set_force(value)

func _physics_process(_delta):

	rotate_front_steer(counter_degree)
	apply_forces(counter_speed)
	pass


func _process(_delta):
	
	var speed
	var _x = prec_x - $Body.global_position.x
	var _z = prec_z - $Body.global_position.z
	
	prec_x= $Body.global_position.x
	prec_z= $Body.global_position.z
	
	var _distance=sqrt(_x * _x + _z * _z)
	var current_speed=_distance/_delta
	speed=current_speed*prec_direction
	
	var dx = list_of_point[current_target][0]-$Body.global_position.x
	var dz = list_of_point[current_target][1]-$Body.global_position.z 
	
	var direction=1
	
	# di base va da 0 a 180 e poi da -180 a 0 
	var heading_angle=$Body.global_rotation.y + PI
	
	var target_heading= atan2(-dz,dx)
	
	var angle=target_heading+PI
	var angle_for_direction=angle-heading_angle
	
	if angle_for_direction>=-PI/2 and angle_for_direction<PI/2:
		#print("avanti")
		pass
	else:
		#print("indietro")
		heading_angle=heading_angle+PI
		direction=-1
	
	var distance=sqrt(dx * dx + dz * dz)
	
	if(distance<0.3):
		current_target=current_target+1
		if current_target==len(list_of_point):
			print("finito")
			stay_still=true
			current_target=current_target-1
			
	if stay_still:
		distance=0
		
	distance=distance*direction
	
	speed=current_speed*direction
	
		
	var v_target = my_proportional_linear.PID_evaluate_error(_delta, distance)

	var w_target = my_proportional_angular.PID_evaluate(_delta, angle,heading_angle)
	
	counter_degree=w_target *direction
	counter_speed = my_pid_torque.PID_evaluate(_delta, v_target, speed)
	
	counter_speed=-counter_speed
	
	prec_direction=direction
func _integrate_forces(state):
	pass


func _on_world_start():
	list_of_point.append([$Body.global_position.x,$Body.global_position.y])
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("http://127.0.0.1:5000/get_path")
	pass # Replace with function body.
