# Godot Background Loader

A small library for background loading in Godot 2/3.

This is a simple library which uses ResourceLoader to load things in the background (no multi-threading).

## Installation

Copy the loader.gd script into your project e.g. to `res://addons/loader/loader.gd`

(You can also just copy this into your code and tweak it however you want)

Add loader.gd as an AutoLoad.

## Usage

### Overview

General usage of this library involves the following 2 functions:

**loader.queue(id, path, push_front=false)**

Queue the ".tscn" or ".gd" object for loading and associate it with _id_.
When it has completed loading, the `resource_loaded` signal will be emitted for _id_.
There is an optional "push_front" parameter if you want to prioritize this resource.

**loader.instance(id)**

Get a new instance of the resource associated with _id_.
If you call this method while the resource is being loaded or is still in the queue,
it will be loaded immediately in a blocking way (using the built-in `load()` function).

There's also a `queue_finished` signal which will be emitted when everything in the queue has been loaded.
You can yield to this signal if you want to, for instance, display a loading screen and wait for everything to load.

### Other methods

**loader.clear_queue()**

Clear everything in the queue. If something is busy loading it will finish.

**loader.clear_resources()**

Clear cache of resources that have been loaded already.

**loader.get_progress()**

Get the progress of the currently loading object as a float between 0 and 1.

## Examples

Some common example patterns.

### Basic

```
# Queue a resource for background loading
loader.queue("jimmy", "res://src/characters/jimmy.tscn")

# Later on, whenever you need it, acquire an instance
var jimmy = loader.instance("jimmy")
```

### Signal

```
func _ready():
    loader.connect("resource_loaded", self, "_resource_loaded")

    # Queue a resource for background loading
    loader.queue("jimmy", "res://src/characters/jimmy.tscn")

# When the resource has finished loading, do something with it
func _resource_loaded(id):
    var instance = loader.instance(id)
    # Do something with it ...
```

### Loading screen

If you want to display a loading screen and wait for all resources to finish loading

```
# Display a loading screen
# ...

loader.queue("jimmy", "res://src/characters/jimmy.tscn")
loader.queue("bullet", "res://src/bullet.tscn")
loader.queue("car", "res://src/car.tscn")
loader.queue("slime", "res://src/enemies/slime.tscn")

yield(loader, "queue_finished")

# Display the main screen
# ...
```

## License

WTFPL. Do whatever you want.
