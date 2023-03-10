extends Node2D

var USER = "";
var PASSWORD = "";
var HOST = "";
var DATABASE = "";
var PORT = 0;
var SIZE = 0;
var isConn = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Load Globals");
	print("Load Console Commands");
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
		
#	OS.window_borderless = true;
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

func reset_windowSize():
	OS.window_size = Vector2(1024, 600);

func exit_game():
	get_tree().quit();
