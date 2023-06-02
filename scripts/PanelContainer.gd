extends PanelContainer

func _ready():
	var content = Globals.rFile("ScreenSize.txt");
	var args = Array();
	args = content.split(',', 0);
	if args.empty():
		Globals.wFile("1024, 600", "ScreenSize.txt");
		OS.window_size = Vector2(1024, 600);
		rect_size = OS.window_size; 
	else:
		OS.window_size = Vector2(int(args[0]), int(args[1]));
		rect_size = OS.window_size;
	Globals.SIZE = OS.window_size;
	set_process(true)

func _process(_delta):
	rect_size = OS.window_size;
	update();

