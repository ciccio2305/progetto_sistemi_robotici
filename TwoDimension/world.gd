extends Node3D

var ob =preload("res://obstacle.tscn")
var robot =preload("res://robot.tscn")
var rng = RandomNumberGenerator.new()
var my_ready=true
signal start
@export var number_of_obj:int
# Called when the node enters the scene tree for the first time.
func _ready():
	var list_of_ob=[]
	

	var http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_request_completed)
	add_child(http_request)
	http_request.request("http://127.0.0.1:5000/get_obstacles")
	
	pass # Replace with function body.

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	print(json["points"])
	for x in json["points"]:
		var new_ob=ob.instantiate()
		self.add_child(new_ob)
		new_ob.global_position.x=x[0][0]/100 * 18 - 9
		new_ob.global_position.y=0
		new_ob.global_position.z=x[0][1]/100 * 18 - 9
		new_ob.scale=Vector3(x[1]/100*18,x[1]/100*18,x[1]/100*18)
	my_ready=false
	var http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_request_completed2)
	add_child(http_request)
	http_request.request("http://127.0.0.1:5000/get_path")

func _on_request_completed2(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	$Robot.global_position.x=json["points"][0][0]/100 * 18 - 9

	$Robot.global_position.y=0.229
	$Robot.global_position.z=json["points"][0][1]/100 * 18 - 9
	start.emit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
