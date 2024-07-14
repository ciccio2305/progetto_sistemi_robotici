extends Node3D

var ob =preload("res://obstacle.tscn")
var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	var list_of_ob=[]
	for x in range(100):
		var cord_x = rng.randf_range(-8.0, 8.0)
		var cord_z = rng.randf_range(-8.0, 8.0)
		
		var new_ob=ob.instantiate()
		self.add_child(new_ob)
		new_ob.global_position.x=cord_x
		new_ob.global_position.y=0
		new_ob.global_position.z=cord_z
		list_of_ob.append([cord_x,cord_z])
	
	var json = JSON.stringify(list_of_ob)
	var headers = ["Content-Type: application/json"]
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request("http://127.0.0.1:5000/post_data", headers, HTTPClient.METHOD_POST, json)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
