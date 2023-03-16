extends Node2D

var USER = "";
var PASSWORD = "";
var HOST = "";
var DATABASE = "";
var PORT = 0;
var SIZE = 0;
var VERSION = 0;
var SYSTEM = '';

var isConn = false;
var scene = '';

#	Voir pour faire une version utilisant SQLITE
#
#

# Pour démarrer/arreter un service sur Linux : 
#	systemctl start/stop postgresql
#	

func _ready():
	var scene = get_tree().get_current_scene().get_name();
	SYSTEM = OS.get_name();
	print("Load Globals");
	print("Load Console Commands");
	print("Setting Defaults Values");
	Console.add_command('user', self, 'print_user')\
		.set_description('Prints default or current User')\
		.register()
	Console.add_command('password', self, 'print_password')\
		.set_description('Prints default or current Password')\
		.register()
	Console.add_command('server', self, 'print_server')\
		.set_description('Prints default or current Server')\
		.register()
	Console.add_command('database', self, 'print_database')\
		.set_description('Prints default or current Database')\
		.register()
	Console.add_command('port', self, 'print_port')\
		.set_description('Prints default or current Port')\
		.register()
	Console.add_command('conn', self, 'print_connexion')\
		.set_description('Prints default or current full connexion')\
		.register()
	Console.add_command('wBorder', self, 'set_windowBorder')\
		.set_description('Change border type of window')\
		.add_argument('value', TYPE_STRING)\
		.register()
	Console.add_command('wSize', self, 'set_windowSize')\
		.set_description('Change size of window')\
		.add_argument('sizeX', TYPE_INT)\
		.add_argument('sizeY', TYPE_INT)\
		.register()
	Console.add_command('wReset', self, 'reset_windowSize')\
		.set_description('Reset window size')\
		.register()
	Console.add_command('exit', self, 'exit_game')\
		.set_description('Exit application')\
		.register()
	Console.add_command('csvi', self, 'print_csvImport')\
		.set_description('Show Import URL of CSV')\
		.register()
	Console.add_command('pgstart', self, 'start_servicePostgres')\
		.set_description('Start Postgres service, need run as admin, if argument is empty, start the service by default')\
		.add_argument('version', TYPE_STRING)\
		.register()
	Console.add_command('pgstop', self, 'stop_servicePostgres')\
		.set_description('Stop Postgres service, need run as admin, if argument is empty, stop the service by default')\
		.add_argument('version', TYPE_STRING)\
		.register()
	Console.add_command('pgstate', self, 'print_serviceStatePostgres')\
		.set_description('Print Postgres service, need run as admin, if argument is empty, stop the service by default')\
		.add_argument('version', TYPE_STRING)\
		.register()
	Console.add_command('setpg', self, 'set_versionPostgres')\
		.set_description('Set Postgres version to use (x64)')\
		.add_argument('version', TYPE_STRING)\
		.register()
	Console.add_command('getpg', self, 'get_versionPostgres')\
		.set_description('Get Postgres version to use')\
		.register()
	Console.add_command('goto', self, 'goTo_scene')\
		.set_description('Load the scene')\
		.add_argument('scene', TYPE_STRING)\
		.register()
	Console.add_command('listscene', self, 'get_sceneName')\
		.set_description('List all scenes')\
		.register()
	Console.add_command('searchpg', self, 'search_servicePostgres')\
		.set_description('search the services postgres')\
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
		var results = str(output).split('\n', false);
		for services in results:
			var result = regex.search(services);
			if result:
				Globals.VERSION = services.split(' ', false)[1].split('-', false)[2];

func _physics_process(_delta: float) -> void:
	if scene != get_tree().get_current_scene().get_name() and !scene.empty():
		var timeDict = OS.get_time();
		var dateDict = Time.get_date_dict_from_system();
		var year = dateDict['year'];
		var month = dateDict['month'];
		var day = dateDict['day'];
		var hour = timeDict.hour;
		var minute = timeDict.minute;
		var seconds = timeDict.second;
		if str(month).length() == 1:
			month = str('0',month);
		rwFile(str(year,'-',month,'-',day,'-', hour, ' ', minute, ':', seconds, '=>', scene), 'HistoriqueNavigation.txt');
		scene = get_tree().get_current_scene().get_name();
	else:
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

func print_user():
	Console.write_line('User : ' + USER);
	
func print_database():
	Console.write_line('Database : ' + DATABASE);
	
func print_port():
	Console.write_line('Port : ' + PORT);
	
func print_server():
	Console.write_line('Server : ' + HOST);

func print_password():
	Console.write_line('Password : ' + PASSWORD);

func print_connexion():
	Console.write_line('Conn : postgresql://%s:%s@%s:%d/%s'
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
		
func print_csvImport():
	var csvPath = str(OS.get_user_data_dir(), '/CSV/');
	var csvPathSplited = csvPath.split('/');
	csvPath = str(csvPathSplited[0], '/', csvPathSplited[1], '/Public/');
	Console.write_line('Path by default : %s'
		% [csvPath]);
	
func set_windowBorder(value):
	if value.to_lower() == 'false':
		OS.window_borderless = true;
	elif value.to_lower() == 'true':
		OS.window_borderless = false;
	else:
		Console.write_line('Argument ' + value + ' invalide');

func set_windowSize(sizeX, sizeY):
	OS.window_size = Vector2(sizeX, sizeY);
	Console.write_line('window size set to ' + str(sizeX) + 'x' +  str(sizeY));

func reset_windowSize():
	OS.window_size = Vector2(1024, 600);
	Console.write_line('window size set to 1024x600');

func start_servicePostgres(version = Globals.VERSION):
	version = str('net start postgresql-x64-', version);
	var _res = OS.execute('cmd.exe', ['/c', version], false);
	Console.write_line('postgresql-x64-' + version + ' running');
	
func stop_servicePostgres(version = Globals.VERSION):
	version = str('net stop postgresql-x64-', version);
	var _res = OS.execute('cmd.exe', ['/c', version], false);
	Console.write_line('postgresql-x64-' + version + ' stopped');

func print_serviceStatePostgres(version = Globals.VERSION):
	var output = [];
	version = str('sc query postgresql-x64-', version, ' | findstr /i "STATE"');
	var _res = OS.execute('cmd.exe', ['/c', version], true, output);
	var state = str(output[0]).split(' ', 0)[3];
	Console.write_line('State of postgresql-x64-' + str(Globals.VERSION) + ' is ' + state);

func set_versionPostgres(version):
	Globals.VERSION = version;

func get_versionPostgres():
	Console.write_line('Version used : ' + Globals.VERSION);

func search_servicePostgres():
	var output = [];
	var regex = RegEx.new();
	regex.compile("\\w-(\\d+)");
	var _res = OS.execute('cmd.exe', ['/c', 'sc queryex type= service state= all | find /i "SERVICE_NAME: postgres"'], true, output);
	var results = str(output).split('\n', false);
	for services in results:
		var result = regex.search(services);
		if result:
			Console.write_line('name ' + services.split(' ', false)[1] + ' version ' + services.split(' ', false)[1].split('-', false)[2]);

func get_sceneName():
	var files= get_filelist("res://scene/", ["tscn"])
	for scene in files:
		scene = scene.split('/', 0)[2].split('.', 0)[0];
		Console.write_line(scene);
		print(scene);
	
func goTo_scene(scene):
	var path = str("res://scene/", scene, ".tscn");
	var _changeScene = get_tree().change_scene(path);

func exit_game():
	get_tree().quit();
