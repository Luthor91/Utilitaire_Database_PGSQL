extends Object
class_name PGSQL_Utilities


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _init():  
   pass  

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func sanitizeQuery(query: String):
	pass
	
func isSafe(query: String) -> bool:
	var regex = RegEx.new()
	regex.compile('(SELECT|DELETE|TRUNCATE|UPDATE|\\/\\*|\\*\\/|--)');
	if regex.search(query.to_lower()):
		return false;
	return true;
