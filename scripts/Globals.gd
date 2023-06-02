extends Node2D

var USER: String = "";
var PASSWORD: String = "";
var HOST: String = "";
var DATABASE: String = "";
var PORT: int = 0;
var SIZE: Vector2 = Vector2.ZERO;
var VERSION: int = 0;
var SYSTEM: String = '';
var ENABLE_EVENT: bool = false;
var SCORE: int = 0;
var ALLOW_INJECT: bool = false;

var arrPerf: Array = [
	"TIME_FPS",
	"TIME_PROCESS",
	"TIME_PHYSICS_PROCESS",
	"MEMORY_STATIC",
	"MEMORY_DYNAMIC",
	"MEMORY_STATIC_MAX",
	"MEMORY_DYNAMIC_MAX",
	"MEMORY_MESSAGE_BUFFER_MAX",
	"OBJECT_COUNT",
	"OBJECT_RESOURCE_COUNT",
	"OBJECT_NODE_COUNT",
	"OBJECT_ORPHAN_NODE_COUNT",
];
var isConn: bool = false;
var scene: String = '';
var rng: RandomNumberGenerator = RandomNumberGenerator.new();
var objectEvent: Sprite;
var alreadyHere: bool = false;
#	Voir pour faire une version utilisant SQLITE


# Pour démarrer/arreter un service sur Linux : 
#	systemctl start/stop postgresql
#	

func _ready():
	scene = get_tree().get_current_scene().get_name();
	Engine.target_fps = 30;
	SYSTEM = OS.get_name();
	print("Load Globals");
	print("Load Console Commands");
	print("Setting Defaults Values");
	Console.add_command('conn', self, 'print_databaseConn')\
		.set_description('Prints default or current connexion param')\
		.add_argument('param', TYPE_STRING)\
		.register()
		
	Console.add_command('window', self, 'manage_windowParam')\
		.set_description('Change border type of window')\
		.add_argument('arg', TYPE_STRING)\
		.add_argument('value', TYPE_STRING)\
		.register()
	Console.add_command('exit', self, 'exit_game')\
		.set_description('Exit application')\
		.register()
	Console.add_command('csvi', self, 'print_csvImport')\
		.set_description('Show Import URL of CSV')\
		.register()
	Console.add_command('perf', self, 'print_perf')\
		.set_description('Show single perf')\
		.add_argument('arg', TYPE_STRING)\
		.register()
	Console.add_command('pg', self, 'postgres_serviceHandler')\
		.set_description('Handle postgres service\nStart, Stop, set, get, search')\
		.add_argument('param', TYPE_STRING)\
		.add_argument('version', TYPE_INT)\
		.register()
	Console.add_command('sql', self, 'sql_settingHandler')\
		.set_description('Handle some sql parameters\n\t inject => true/false')\
		.add_argument('subcommand', TYPE_STRING)\
		.add_argument('arg', TYPE_INT)\
		.register()
	Console.add_command('project', self, 'project_sceneHandler')\
		.set_description('handle print and change of scenes')\
		.add_argument('subcommand', TYPE_STRING)\
		.add_argument('arg', TYPE_STRING)\
		.register()
	Console.add_command('event', self, 'manage_event')\
		.set_description('enable event with true or false')\
		.add_argument('value', TYPE_BOOL)\
		.register()
	Console.add_command('getscore', self, 'get_eventScore')\
		.set_description('print the current score')\
		.register()
	Console.add_command('dabr', self, 'anim_barrelRoll')\
		.set_description('do a barrel roll')\
		.register()
	Console.add_command('cc', self, 'manage_cheatCode')\
		.set_description('manage codes')\
		.add_argument('pwd', TYPE_STRING)\
		.add_argument('code', TYPE_STRING)\
		.register()
	OS.set_window_title("UtilitairePGSQL");
	var file = rFile("DefaultLogs.txt");
	var args = file.split(',', 0);
	if args.empty():
		args.append('postgres');
		args.append('postgres');
		args.append('postgres');
		args.append('127.0.0.1');
		args.append(5432);
	Globals.DATABASE = str(args[0]);
	Globals.USER = str(args[1]);
	Globals.PASSWORD = str(args[2]);
	Globals.HOST = str(args[3]);
	Globals.PORT = int(args[4]);
	if Globals.VERSION == 0:
		var output = [];
		var regex = RegEx.new();
		regex.compile("\\w-(\\d+)");
		var _res = OS.execute('cmd.exe', ['/c', 'sc queryex type= service state= all | find /i "SERVICE_NAME: postgres"'], true, output);
		if _res != 0:
			return;
		var results = str(output).split('\n', false);
		for services in results:
			var result = regex.search(services);
			if result:
				Globals.VERSION = services.split(' ', false)[1].split('-', false)[2];

func _physics_process(_delta: float) -> void:
	if scene != get_tree().get_current_scene().get_name() and !scene.empty():
		alreadyHere = false;
		randomize();
		if ENABLE_EVENT:
			$TimerEvent.start();
		var timeDict = OS.get_time();
		var dateDict = Time.get_date_dict_from_system();
		var month = dateDict['month'];
		if str(month).length() == 1:
			month = str('0',month);
		rwFile(str(
			dateDict['year'],'-',
			month,'-',
			dateDict['day'],'-', 
			timeDict.hour, ':', 
			timeDict.minute, ':', 
			timeDict.second, '=>', scene), 'HistoriqueNavigation.txt');
		createIconButton();
	scene = get_tree().get_current_scene().get_name();

func rFile(url):
	url = str("user://", url);
	var file = File.new();
	if !file.file_exists(url):
		print("Read_ ", url, " can't find");
	var err = file.open(url, File.READ);
	if err == OK:
		print("Read_ ", url, " oppened");
	var content = file.get_as_text();
	file.close();
	return content;

func wFile(toStore, url):
	url = str("user://", url);
	var file = File.new();
	if !file.file_exists(url):
		print("Write_ ", url, " can't find");
	var err = file.open(url, File.WRITE);
	if err == OK:
		print("Write_ ", url, " oppened");
	file.store_string(str(toStore));
	file.close();

func rwFile(toStore, url):
	url = str("user://", url);
	var file = File.new();
	if !file.file_exists(url):
		print("Save_ ", url, " can't find");
	var err = file.open(url, File.READ_WRITE);
	if err == OK:
		print("Save_ ", url, " oppened");
	var content = file.get_as_text();
	if content.find(toStore) != -1:
		return 0;
	if content.empty():
		file.store_string(str(toStore));
	else:
		file.store_string(str(content, "\n", toStore));
	file.close();

func wrFile(toStore, url):
	url = str("user://", url);
	var file = File.new();
	if !file.file_exists(url):
		print("Save_ ", url, " can't find");
	var err = file.open(url, File.WRITE_READ);
	if err == OK:
		print("Save_ ", url, " oppened");
	var content = file.get_as_text();
	if content.find(toStore) != -1:
		return 0;
	if content.empty():
		file.store_string(str(toStore));
	else:
		file.store_string(str(content, "\n", toStore));
	file.close();

func get_filelist(scan_dir : String, filter_exts : Array = []) -> Array:
	var my_files : Array = []
	var dir := Directory.new()
	if dir.open(scan_dir) != OK:
		printerr("Warning: could not open directory: ", scan_dir)
		return []

	if dir.list_dir_begin(true, true) != OK:
		printerr("Warning: could not list contents of: ", scan_dir)
		return []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			my_files += get_filelist(dir.get_current_dir() + "/" + file_name, filter_exts)
		else:
			if filter_exts.size() == 0:
				my_files.append(dir.get_current_dir() + "/" + file_name)
			else:
				for ext in filter_exts:
					if file_name.get_extension() == ext:
						my_files.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()
	return my_files

func randomEvent():
	var sprite: Sprite = Sprite.new();
	var btn: Button = Button.new();
	rng.randomize();
	var randPos: Vector2 = Vector2(
		rng.randf_range(32,SIZE.x-32), 
		rng.randf_range(32,SIZE.y-32));
	btn.modulate = Color(1.0, 1.0, 1.0, 0.0);
	btn.set_position(-Vector2(16, 16));
	btn.set_size(Vector2(32, 32));
	var _err = btn.connect("pressed", self, '_on_ButtonEvent_pressed');
	sprite.set_position(randPos);
	sprite.texture = load('res://graphics/Events/Gift1_64x64.png');
	sprite.add_child(btn);
	sprite.scale = Vector2(0.7, 0.7);
	sprite.show();
	get_tree().get_current_scene().add_child(sprite);
	objectEvent = sprite;
	alreadyHere = true;

func createIconButton():
	var sprite = Sprite.new();
	var btn = Button.new();
	btn.modulate = Color(1.0, 1.0, 1.0, 0.0);
	btn.set_position(-Vector2(16, 16));
	btn.set_size(Vector2(32, 32));
	var _err =  btn.connect("pressed", self, '_on_ButtonIcon_pressed');
	sprite.set_position(Vector2(1000, 48));
	sprite.texture = load('res://graphics/Icons/Button.png');
	sprite.add_child(btn);
	sprite.scale = Vector2(0.7, 0.7);
	sprite.hide();
	get_tree().get_current_scene().add_child(sprite);

func print_databaseConn(param: String = ""):
	param = param.to_lower();
	match param:
		"user", "u":
			Console.write_line('User : ' + USER);
		"database", "db", "d":
			Console.write_line('Database : ' + DATABASE);
		"port", "p":
			Console.write_line('Port : ' + str(PORT));
		"server", "serv", "s":
			Console.write_line('Server : ' + HOST);
		"password", "mdp", "pwd", "m":
			Console.write_line('Password : ' + PASSWORD);
		"":
			Console.write_line('Conn : postgresql://%s:%s@%s:%d/%s'
		% [USER, PASSWORD, HOST, PORT, DATABASE]);

func print_csvImport():
	var csvPath = str(OS.get_user_data_dir(), '/CSV/');
	var csvPathSplited = csvPath.split('/');
	csvPath = str(csvPathSplited[0], '/', csvPathSplited[1], '/Public/');
	Console.write_line('Path by default : %s'
		% [csvPath]);

func print_perf(arg: String):
	arg = arg.to_lower();
	var arrUniteMemo: Array = ['Kio', 'Mio'];
	var arrUniteTemp: Array = ['ms', 'us'];
	var index: int = 0
	match arg:
		"all", "*":
			while index < arrPerf.size():
				var perf: float = Performance.get_monitor(index);
				var output: String;
				# Si la donnée est temporelle
				var indexTemp: int = 0;
				while perf > 0 and perf < 1:
					perf *= 1000;
					output = str(perf, arrUniteTemp[indexTemp]);
					indexTemp += 1;
				# Si la donnée est une qte mémoire
				var indexMemo: int = 0;
				while int(perf) >= 1000 and index < 8:
					perf /= 1000;
					output = str(perf, arrUniteMemo[indexMemo]);
					indexMemo += 1;
				if output.empty():
					output = str(perf);
				Console.write_line(arrPerf[index] + '[' + str(index) + '] : ' + str(output));
				index += 1;
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11":
			var value: int = int(arg);
			var perf: float = Performance.get_monitor(value);
			var output: String;
			# Si la donnée est temporelle
			var indexTemp: int = 0;
			var indexMemo: int = 0;
			while perf > 0 and perf < 1:
				perf *= 1000;
				output = str(perf, arrUniteTemp[indexTemp]);
				indexTemp += 1;
			# Si la donnée est une qte mémoire
			while int(perf) >= 1000 and value < 8:
				perf /= 1000;
				output = str(perf, arrUniteMemo[indexMemo]);
				indexMemo += 1;
			if output.empty():
				output = str(perf);
			Console.write_line(arrPerf[value] + ' : ' + str(output));
		_:
			Console.write_line(arg + " n'est pas un argument valide");

func sql_settingHandler(subcommand: String, arg: String):
	subcommand = subcommand.to_lower()
	arg = arg.to_lower();
	match subcommand:
		"inject", "i":
			match arg:
				"true", "t", "1":
					Globals.ALLOW_INJECT = true;
				"false", "f", "0":
					Globals.ALLOW_INJECT = false;
				_:
					Console.write_line('Argument ' + arg + ' invalide');

func manage_windowParam(arg: String, value: String = ''):
	arg = arg.to_lower();
	value = value.to_lower();
	match arg:
		"border":
			match value:
				"true", "t", "1":
					OS.window_borderless = false;
				"false", "f", "0":
					OS.window_borderless = true;
				_:
					Console.write_line('Argument ' + value + ' invalide');
		"size":
			if ',' in value:
				var values: Array = value.split(',', true);
				OS.window_size = Vector2(float(values[0]), float(values[1]));
				Console.write_line('window size set to ' + values[0] + 'x' +  values[1]);
		"reset":
			OS.window_size = Vector2(1024, 600);
			Console.write_line('window size set to 1024x600');
		"get":
			Console.write_line(str(OS.window_size));

func postgres_serviceHandler(arg: String, version: int = Globals.VERSION):
	arg = arg.to_lower();
	var strVersion: String = str('net start postgresql-x64-', version);
	var output: Array = [];
	match arg:
		"start":
			var _res = OS.execute('cmd.exe', ['/c', strVersion], false);
			if _res != 0:
				return;
			Console.write_line('postgresql-x64-' + strVersion + ' running');
		"stop":
			var _res = OS.execute('cmd.exe', ['/c', strVersion], false);
			if _res != 0:
				return;
			Console.write_line('postgresql-x64-' + strVersion + ' stopped');
		"state":
			strVersion = str('sc query postgresql-x64-', version, ' | findstr /i "STATE"');
			var _res: int = OS.execute('cmd.exe', ['/c', strVersion], true, output);
			if _res != 0:
				return;
			var state = str(output[0]).split(' ', 0)[3];
			Console.write_line('State of postgresql-x64-' + str(Globals.VERSION) + ' is ' + state);
		"set":
			Globals.VERSION = version;
		"get":
			Console.write_line('Version used : ' + str(Globals.VERSION));
		"search":
			var regex = RegEx.new();
			regex.compile("\\w-(\\d+)");
			var _res = OS.execute('cmd.exe', ['/c', 'sc queryex type= service state= all | find /i "SERVICE_NAME: postgres"'], true, output);
			if _res != 0:
				return;
			var results = str(output).split('\n', false);
			for services in results:
				var result = regex.search(services);
				if result:
					Console.write_line('name ' + services.split(' ', false)[1] + ' version ' + services.split(' ', false)[1].split('-', false)[2]);

func manage_event(value):
	ENABLE_EVENT = value;

func get_eventScore():
	Console.write_line('Score : ' + str(Globals.SCORE));

func project_sceneHandler(arg: String, value: String = 'Login'):
	arg = arg.to_lower();
	var dictScenes: Dictionary = {
		"Utilisateurs" : [
			'CreationUtilisateur',
			'SuppressionUtilisateur',
			'GestionUtilisateur'
		],
		"Base de données" : [
			'CreationDatabase',
			'GestionDatabase',
			'ExportImport'
		],
		"Tables" : [
			'CreationTable',
			'GestionTable'
		],
		"Requêtes" : [
			'RequeteEcrite',
			'RequereFormulaire',
			'RequeteVisualisation'
		],
		"Options" : [
			'Login',
			'Information',
			'Option'
		],
		"Divers" : [
			'Contact',
			'Tutoriel'
		]
	};
	
	match arg:
		"list", "l":
			var files= get_filelist("res://scene/", ["tscn"])
			for local_scene in files:
				local_scene = local_scene.split('/', 0)[2].split('.', 0)[0];
				Console.write_line(local_scene);
		"goto", "g":
			var path = str("res://scene/", value, ".tscn");
			var _changeScene = get_tree().change_scene(path);
		"tree", "t":
			var output: String = '';
			for mainScene in dictScenes:
				var title: String = str(mainScene);
				var content: String = '';
				for index in dictScenes[mainScene].size():
					print(dictScenes[mainScene][index])
					content += str("\n\t[url=goto ", dictScenes[mainScene][index], "]", dictScenes[mainScene][index], "[/url]");
				content += '\n';
				output += str(title, content)
			Console.write_line(output);

func manage_cheatCode(pwd: String, code: String):
	if pwd != str(Globals.PASSWORD, '@cheat'):
		return;
	match code:
		'konami':
			print('konami')
	
func anim_barrelRoll():
	var tween: Tween = Tween.new();
	var getScene: Node = get_tree().get_current_scene();
	getScene.add_child(tween);
	var res1 = tween.interpolate_property(getScene, "rotation_degrees",
		0.0, 360.0, 3,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	var res2 = tween.start();
	Console.write_line('init ' + str(res1) + ' start ' + str(res2));
	yield(get_tree().create_timer(3.0), "timeout")
	tween.queue_free()

func exit_game():
	get_tree().quit();

func _on_ButtonEvent_pressed():
	SCORE += 1;
	print(SCORE);
	alreadyHere = false;
	objectEvent.queue_free();
	$TimerEvent.start();

func _on_ButtonIcon_pressed():
	var _changeScene = get_tree().change_scene("res://scene/Login.tscn");

func _on_TimerEvent_timeout():
	rng.randomize()
	$TimerEvent.set_wait_time(rng.randf_range(10.0,15.0));
	if !alreadyHere:
		randomEvent();

func replace_value(text, to_replace, replace_with):
	var sanitized_replace_with = RegEx.new().sub(replace_with, "$1")
	text = text.replace(to_replace, sanitized_replace_with)
	return text
