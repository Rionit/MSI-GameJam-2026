@tool
extends Node3D
class_name DynamicCable

@export_range(2, 50) var link_count := 10:
	set(value):
		link_count = value
		if Engine.is_editor_hint():
			_generate_chain()

@export var link_length := 0.3:
	set(value):
		link_length = value
		if Engine.is_editor_hint():
			_generate_chain()

@export var link_radius := 0.05:
	set(value):
		link_radius = value
		if Engine.is_editor_hint():
			_generate_chain()

@export var slack := 1.0:
	set(value):
		slack = value
		if Engine.is_editor_hint():
			_generate_chain()

@export var end_target: NodePath:
	set(value):
		end_target = value
		if Engine.is_editor_hint():
			_generate_chain()

@export_flags_3d_physics var cable_collision_layer := 2:
	set(value):
		cable_collision_layer = value
		if Engine.is_editor_hint():
			_generate_chain()

@export_flags_3d_physics var cable_collision_mask := 1:
	set(value):
		cable_collision_mask = value
		if Engine.is_editor_hint():
			_generate_chain()

var anchor: StaticBody3D
var link_container: Node3D

var links: Array[RigidBody3D] = []
var joints: Array[Generic6DOFJoint3D] = []

func _ready() -> void:
	_setup_nodes()
	_generate_chain()

func _setup_nodes() -> void:
	if has_node("Anchor"):
		anchor = $Anchor
	else:
		anchor = StaticBody3D.new()
		anchor.name = "Anchor"
		add_child(anchor)
		if Engine.is_editor_hint():
			anchor.owner = self

	if has_node("LinkContainer"):
		link_container = $LinkContainer
	else:
		link_container = Node3D.new()
		link_container.name = "LinkContainer"
		add_child(link_container)
		if Engine.is_editor_hint():
			link_container.owner = self

func _generate_chain():
	if not link_container:
		return
		
	for link in links:
		if is_instance_valid(link):
			link.queue_free()
	links.clear()
	joints.clear()
	
	for child in link_container.get_children():
		child.queue_free()
	
	var cylinder_height = (link_length - (2.0 * link_radius)) * slack
	var top_cap_offset = (link_length * 0.5) - link_radius
	
	for i in range(link_count):
		var link = _create_link(i)
		link_container.add_child(link)
		if Engine.is_editor_hint():
			link.owner = self
		links.append(link)
		link.position = Vector3(0, -top_cap_offset - (i * cylinder_height), 0)
	
	await get_tree().process_frame
	if not is_inside_tree():
		return
	
	for i in range(link_count):
		var body_a = anchor if i == 0 else links[i - 1]
		var body_b = links[i]
		
		if not is_instance_valid(body_a) or not is_instance_valid(body_b):
			continue
			
		var joint = _create_joint(body_a)
		body_b.add_child(joint)
		if Engine.is_editor_hint():
			joint.owner = self
		
		joint.node_a = joint.get_path_to(body_a)
		joint.node_b = NodePath("..")
		
		joints.append(joint)
		
	# Attach the final link to an optional second body/target (e.g., dynamic end point)
	if not end_target.is_empty() and has_node(end_target):
		var target_node = get_node(end_target)
		if target_node and links.size() > 0:
			var last_link = links[links.size() - 1]
			var end_joint = _create_joint(last_link)
			end_joint.name = "Joint_to_EndTarget"
			target_node.add_child(end_joint)
			if Engine.is_editor_hint():
				end_joint.owner = self
			end_joint.node_a = end_joint.get_path_to(last_link)
			end_joint.node_b = NodePath("..")
			joints.append(end_joint)

func _create_link(index: int) -> RigidBody3D:
	var link = RigidBody3D.new()
	link.name = "Link_" + str(index)
	
	link.mass = 0.2
	link.gravity_scale = 1.0
	link.linear_damp = 0.5
	link.angular_damp = 0.5
	
	link.collision_layer = cable_collision_layer
	link.collision_mask = cable_collision_mask
	
	var mesh_instance = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.height = link_length
	capsule.radius = link_radius
	mesh_instance.mesh = capsule
	link.add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = self
	
	var collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = link_length
	shape.radius = link_radius
	collision_shape.shape = shape
	link.add_child(collision_shape)
	if Engine.is_editor_hint():
		collision_shape.owner = self
	
	return link

func _create_joint(body_a: Node3D) -> Generic6DOFJoint3D:
	var joint = Generic6DOFJoint3D.new()
	joint.name = "Joint_to_" + body_a.name
	joint.position = Vector3(0, (link_length * 0.5) - link_radius, 0)
	
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	
	var angular_limit_rad = deg_to_rad(30.0)
	var twist_limit_rad = deg_to_rad(15.0)

	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)

	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -angular_limit_rad)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -twist_limit_rad)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -angular_limit_rad)
	
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_limit_rad)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, twist_limit_rad)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_limit_rad)
	
	return joint
