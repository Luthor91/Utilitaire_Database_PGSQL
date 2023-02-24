extends Panel

func _ready():
	var content = Globals.rFile("ColorPanel.txt");
	var args = Array();
	args = content.split(',', 0);
	if args.empty():
		for _i in range(3):
			args.append(1);
		Globals.rwFile("1,1,1,1", "ColorPanel.txt");
	
	modulate = Color(args[0],args[1],args[2],1);
	set_process(true)

func _process(_delta):
	update();
