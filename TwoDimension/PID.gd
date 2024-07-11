extends Node

class_name PID 

#proportional
var kp
func set_kp(input_kp):
	kp=input_kp
func proportional_evaluate(target, current):
	var error=target-current
	return kp*error
func proportional_evaluate_error(error):
	return kp*error

#integral
var ki
var integral_output
func set_ki(input_ki):
	ki=input_ki
	integral_output=0
func integral_evaluate(delta_t,target, current):
	var error=target-current
	integral_output=integral_output+ ki*error*delta_t
	return integral_output
func integral_evaluate_error(delta_t,error):
	integral_output=integral_output+ ki*error*delta_t
	return integral_output
	
#derivative
var kd
var prev_error
func set_kd(input_kd):
	kd=input_kd
	prev_error=0
func derivative_evaluate(delta_t,target, current):
	var error=target-current
	var derivative = (error - prev_error) / delta_t
	prev_error=error
	return derivative*kd
func derivative_evaluate_error(delta_t,error):
	var derivative = (error - prev_error) / delta_t
	prev_error=error
	return derivative*kd
	
#PID with saturation
var saturation
var antiwindup=false
var in_saturation=false

func create_pid(input_kp,input_ki,input_kd,input_saturation,input_antiwindup=false):
	set_kp(input_kp)
	set_ki(input_ki)
	set_kd(input_kd)
	saturation=input_saturation
	antiwindup=input_antiwindup
	
func PID_evaluate(delta_t, target, current):
	var error = target - current
	if not (antiwindup):
		integral_evaluate(delta_t, target, current)
	elif not (in_saturation):
		integral_evaluate(delta_t, target, current)
		
	var output = proportional_evaluate(target, current) + integral_output + derivative_evaluate(delta_t, target, current)
	
	if output > saturation:
		output = saturation
		in_saturation = true
	elif output < - saturation:
		output = - self.saturation
		in_saturation = true
	else:
		in_saturation = false
	
	return output
		
func PID_evaluate_error(delta_t, error):
	
	if not (antiwindup):
		integral_evaluate_error(delta_t,error)
	elif not (in_saturation):
		integral_evaluate_error(delta_t,error)
		
	var output = proportional_evaluate_error(error) + integral_output + derivative_evaluate_error(delta_t, error)
	
	if output > saturation:
		output = saturation
		in_saturation = true
	elif output < - saturation:
		output = - self.saturation
		in_saturation = true
	else:
		in_saturation = false
	
	return output
		
		
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
