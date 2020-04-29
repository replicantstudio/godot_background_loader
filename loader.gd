extends Node

# Signals
signal resource_loaded
signal queue_finished

# Priority queue of resources to load
var _queue = []

# Dictionary of resources that have already been loaded
var _resources = {}

# Used to check whether file paths exist
var _file = File.new()

# Data of resource currently being loaded
var _curr_loader = null
var _curr_id = null
var _curr_path = null

# Constants
const LOGGING_ENABLED = true

# Add a resource to the back of the loading queue
func queue(id, path, push_front=false):
	if path == null or path == "" or not _file.file_exists(path):
		_log("Error: Trying to load invalid path %s" % path)
		return

	var data = {
		"id": id,
		"path": path
	}

	if push_front:
		_queue.push_front(data)
	else:
		_queue.push_back(data)

	set_process(true)

# Get a new instance of the resource with the given ID
# If it hasn't been loaded yet, it is loaded immediately in a blocking manner
func instance(id):
	if not _resources.has(id):
		_load_now(id)

	if not _resources.has(id):
		_log("Error: Trying to retrieve resource but ID not found: '%s'" % id)
		return null

	var data = _resources[id]
	var resource = data["resource"]
	var path = data["path"]

	# TODO: endswith?
	if path.ends_with(".gd"):
		return resource.new()
	else:
		return resource.instance()

# Clear queue
func clear_queue():
	_queue.clear()

# Clear resources
func clear_resources():
	_resources = {}

# Get the progress of the currently loading resource
func get_progress():
	if _curr_loader == null:
		return -1

	return float(_curr_loader.get_stage()) / float(_curr_loader.get_stage_count())

# Process background loading
func _process(delta):
	if not _curr_loader: # if we're not busy loading something, get the next thing in the queue
		if _queue.empty(): # if both queues are empty, stop
			_log("Queue empty. Stopping background loading for now.")
			emit_signal("queue_finished")
			set_process(false)
			return

		var data = _queue.front()
		_curr_id = data["id"]
		_curr_path = data["path"]

		_queue.pop_front()
		_curr_loader = ResourceLoader.load_interactive(_curr_path)

	var err = _curr_loader.poll()

	# If loading has finished
	if err == ERR_FILE_EOF:
		var resource = _curr_loader.get_resource()

		_resources[_curr_id] = {
			"resource": resource,
			"path": _curr_path
		}

		emit_signal("resource_loaded", _curr_id)
		_log("Resource loaded: '%s' at %s" % [id, path])
		_clear_curr_loader()

	# If error has occurred
	elif err != OK:
		_log("Error: Couldn't load '%s' at %s" % [_curr_id, path])
		_clear_curr_loader()

# Load a resource immediately in a blocking manner
func _load_now(id):
	var was_busy_processing = is_processing()
	if was_busy_processing:
		set_process(false)

	var path = null

	# If this resource is currently being loaded in the bg, stop that
	if _curr_id == id:
		path = _curr_path
		_clear_curr_loader()

	# If this resource is in the queue, remove it
	else:
		for i in range(_queue.size()):
			var data = _queue[i]
			if data["id"] == id:
				path = data["path"]
				queue.erase(i)
				break

	# Couldn't find ID in the queue
	if path == null:
		return

	if _file.file_exists(path):
		_log("Error: Trying to load invalid path %s" % path)
		return

	var resource = load(path)

	_resources[id] = {
		"resource": resource,
		"path": path
	}

	_log("Resource loaded: '%s' at %s" % [id, path])
	emit_signal("resource_loaded", id)

	if was_busy_processing:
		set_process(true)

func _clear_curr_loader():
	_curr_loader = null
	_curr_id = null
	_curr_path = null

func _log(message):
	if LOGGING_ENABLED:
		print(message)