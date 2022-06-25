extends Label

var stats = []
var variables = []
var debug_text: String
	
func add_stat(var_name: String, variable):
	if !var_name in variables:
		stats.append([var_name, str(variable)])
		variables.append(var_name)

		
func display():
	var debug_text = ""
	for s in stats:
		debug_text += s[0] + ": " + s[1] + "\n"
	self.text = debug_text
	variables = []
	stats = []
