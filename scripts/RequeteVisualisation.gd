extends Node2D

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();

#var nodeGraph = preload("res://addons/easy_charts/examples/line_chart/Control.tscn");
var nodeCharts = preload("res://addons/easy_charts/control_charts/chart.tscn");

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

onready var input = $PanelContainer/MainPanel/Inputs/NameUser/InputData;

var dictValues = {};
var dictQueries = {};
var dictNameValues = {};
var arrContent: Array = [];
var _error;
var page: int;
var maxPage: int;

enum TypeFunction {
	LINEAR,
	STAIR,
	SPLINE
}

enum TypeGraph {
	SCATTER,
	LINE,
	AREA,
	PIE,
	BAR,
	SIMPLE
}

enum TypeMarker {
	NONE,
	CIRCLE,
	TRIANGLE,
	SQUARE,
	CROSS
}
func _init() -> void:
	pass
	
func _ready():
	_error = database.connect("connection_established", self, "_query") 
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")
	var mb = $PanelContainer/MainPanel/SettingGraph/typeFunction/TypeFunction;
	var popup = mb.get_popup();
	popup.add_item("Linéaire", TypeFunction.LINEAR);
	popup.add_item("Escalier", TypeFunction.STAIR);
	popup.add_item("Spline", TypeFunction.SPLINE);
	mb = $PanelContainer/MainPanel/SettingGraph/typeChart/TypeChart;
	popup = mb.get_popup();
	popup.add_item("Points", TypeGraph.SCATTER);
	popup.add_item("Lignes", TypeGraph.LINE);
	popup.add_item("Zone", TypeGraph.AREA);
	popup.add_item("Camembert (WIP)", TypeGraph.PIE);
	popup.add_item("Barres", TypeGraph.BAR);
	popup.add_item("Simple", TypeGraph.SIMPLE);

	mb = $PanelContainer/MainPanel/SettingGraph/typeMarker/TypeMarker;
	popup = mb.get_popup();
	popup.add_item("Aucun", TypeMarker.NONE);
	popup.add_item("Cercle", TypeMarker.CIRCLE);
	popup.add_item("Triangle", TypeMarker.TRIANGLE);
	popup.add_item("Carré", TypeMarker.SQUARE);
	popup.add_item("Croix", TypeMarker.CROSS);
	
func _physics_process(_delta: float) -> void:
	database.poll();

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func loginDatabase() -> void:
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func createTab(var valName):
	valName = valName.replace('"', '');
	var tabContain = $PanelContainer/MainPanel/Resultats/TabContainer;
	var indexTab = 0;
	var dictTabName = {};
#	Charger les noms de tous les onglets
	while indexTab < tabContain.get_child_count():
		dictTabName[dictTabName.size()] = tabContain.get_tab_title(indexTab);
		indexTab += 1;
	var tabs = $PanelContainer/MainPanel/Inputs/NameUser2/Onglet/VBoxContainer;
	var tab = Tabs.new();
	var pan = Panel.new();
	var scrollContain = ScrollContainer.new();
	var vBox = VBoxContainer.new();
	var btnPanel = Button.new();
	var btnTab = Button.new();
	_error = btnPanel.connect("pressed", self, "_on_ButtonPanel_pressed", [tab]);
	_error = btnTab.connect("pressed", self, "_on_ButtonTab_pressed", [tab, btnTab]);
	scrollContain.rect_size = Vector2(460, 450);
	scrollContain.rect_position = Vector2(10, 10);
	btnPanel.text = "delete";
	btnPanel.rect_position = Vector2(190,465);
	btnPanel.rect_size = Vector2(100,20);
	tab.rect_position = Vector2(4,32);
	tab.rect_size = Vector2(480, 484);
	pan.rect_position = Vector2(5, 0);
	pan.rect_size = Vector2(470, 465);
	tab.add_tab(valName);
	scrollContain.add_child(vBox);
	pan.add_child(scrollContain);
	tab.add_child(pan);
	tab.add_child(btnPanel);
	tabContain.add_child(tab);
	tabContain.set_tab_title(
		tabContain.get_child_count()-1, valName);
#	Vérifier si existe déjà
	var values = dictTabName.values();
	indexTab = 0;
	var tempValName = valName;
	for val in values:
		if val == tabContain.get_tab_title(tabContain.get_child_count()-1):
			tabContain.set_tab_title(tabContain.get_child_count()-1, str(valName, indexTab+1));
			tempValName = str(valName, indexTab+1);
			indexTab += 1;
	btnTab.rect_size = Vector2(128,20);
	btnTab.text = tempValName;
	btnTab.toggle_mode = true;
	tabs.add_child(btnTab);
	var tempDict: Dictionary;
	if dictValues.size() == 0:
		tempDict = dictValues[dictValues.size()];
	else:
		tempDict = dictValues[dictValues.size()-1];
	for index in tempDict:
		for val in tempDict[index]:
			var label = Label.new();
			label.text = str(tempDict[index][val]);
			vBox.add_child(label);

func _query():
	var execData = executeQuery(input.text);
	var res = getResult(execData);
	var dataName = input.text.split('FROM')[0].split('.')[1];
	dictValues[dictValues.size()] = res;
	createTab(dataName);
	for index in dictValues:
		for val in dictValues[index]:
			pass

func getResult(var datas):
	var dictResult = {}; 
	var index = 0;
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			var numberOfColumn = 0;
			var tempDictionnary = {};
			for value in row: # List each data row
				if typeof(value) == TYPE_RAW_ARRAY :
					value = value.get_string_from_utf8();
				var columnName = data.row_description[numberOfColumn]["field_name"];
				tempDictionnary.merge({columnName:value}, true);
				numberOfColumn += 1;
			dictResult.merge({index:tempDictionnary}, true);
			index += 1;
	return dictResult;

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	return database.execute(_query);

func _on_ButtonExec_pressed():
	var dict = {};
	var indexDict = dictQueries.size();
	var toskip = false;
	if !dictQueries.empty():
		for index in dictQueries:
			if dictQueries[index] == input.text:
				toskip = true;
			continue;
	else:
		toskip = false;
	if !toskip:
		dictQueries[indexDict] = input.text;
	if input.text.find('SELECT') == 0:
		if !',' in input.text.split('FROM')[0] and !toskip:
			_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])
	elif input.text.replace(' ', '').find('{') == 0:
		var regex = RegEx.new();
#		Trouver les indices chiffrés
		var localInput = input.text.strip_escapes().replace(' ', '').replace('{', '\n{');
		regex.compile('({.+:.+})');
		var result = regex.search_all(localInput);
		var dataName = '';
		for args in result:
			var arg = args.get_string().substr(1, args.get_string().length()-2);
			arg = arg.replace('{', '').replace('}', '');
			var first = str(arg.split(':')[0]);
			var second = str(arg.split(':')[1]);
			if !'"' in first:
				first = str('"', first, '"');
			if !'"' in second:
				second = str('"', second, '"');
			dataName = first;
			dict[str('"', dict.size(), '"')] = {first : second};
		if !toskip:
			dictValues[indexDict] = dict;
			createTab(dataName);
	for index in dictValues:
		if dictValues[index].empty():
			continue;
		for val in dictValues[index]:
			pass

func _on_ButtonEmpty_pressed():
	input.text = '';

func _on_ButtonPanel_pressed(var node):
	var parent: Object = node.get_parent();
	var nameNode: String = parent.get_tab_title(parent.current_tab);
	var btnTabs: Array = $PanelContainer/MainPanel/Inputs/NameUser2/Onglet/VBoxContainer.get_children();
	var index: int = 0;
	for btn in btnTabs:
		if btn.text == nameNode:
			btn.queue_free();
			break;
		index += 1;
	dictQueries.erase(index);
	dictValues.erase(index);
	node.queue_free();

func _on_ButtonTab_pressed(var tab, var btn):
	if !is_instance_valid(tab):
		btn.queue_free();

func _on_ButtonCalc_pressed():
	var rowButtons: Array = $PanelContainer/MainPanel/Inputs/NameUser2/Onglet/VBoxContainer.get_children();
	var tabs: Object = $PanelContainer/MainPanel/Resultats/TabContainer;
	var arrBtn: Array = [];
	arrContent = [];
	for btn in rowButtons:
		if btn.pressed == true:
			arrBtn.append(btn);
	if arrBtn.empty():
		return;
	var index: int = 0;
	var indexDict: int = 0;
	for tab in tabs.get_children():
		for btn in arrBtn:
			if tabs.get_tab_title(index) == btn.text:
				dictNameValues[indexDict] = tabs.get_tab_title(index);
				var labels = tab.get_child(0).get_child(0).get_child(0).get_children();
				var content = {};
				for label in labels:
					content[content.size()] = label.text;
				arrContent.append(content);
				indexDict += 1;
		index += 1;
	for content in arrContent:
		if content.empty():
			return;
	removeAndCreateGraph(arrContent);

func removeAndCreateGraph(var contents):
	var allTabs: Object = $PanelContainer/MainPanel/Resultats/TabContainer;
	var indexTabs: int = 0;
	for tabs in allTabs.get_children():
		if allTabs.get_tab_title(indexTabs) == 'calc': 
			tabs.queue_free();
		indexTabs += 1;
	var nc: Chart = nodeCharts.instance();
	var cp: ChartProperties = ChartProperties.new()
	var functions: Array = [];
	var tab: Tabs = Tabs.new();
	var pan: Panel = Panel.new();
	var btn: Button = Button.new();
	var X: Array = [];
	var Y: Array = [];
	var colors: Array = ["#ff0000", "#ff6200", "#ffe600", "#6fff00", "#00ffd5", "#006eff", "#aa00ff", "#ff00d4", "#ffffff", "#828282"];
	var index: int = 0;
	var sum: Array = [];
	var maxVal: int = int($PanelContainer/MainPanel/SettingGraph/nbVals/input.text);
	var offset: int = int($PanelContainer/MainPanel/SettingGraph/nbOffset/input.text);
	var zoom: bool = $PanelContainer/MainPanel/SettingGraph/typeZoom/CheckBox.pressed;
	X.resize(contents.size());
	Y.resize(contents.size());
	for element in contents:
		X[index] = [];
		Y[index] = [];
		index += 1
	index = 0;
	var typeFunction: int = $PanelContainer/MainPanel/SettingGraph/typeFunction/TypeFunction.selected;
	var typeChart: int = $PanelContainer/MainPanel/SettingGraph/typeChart/TypeChart.selected;
	var typeMarker: int = $PanelContainer/MainPanel/SettingGraph/typeMarker/TypeMarker.selected;

	var AxScale: Vector2 = Vector2(
		float($PanelContainer/MainPanel/SettingGraph/nbValX/inputX.text),
		float($PanelContainer/MainPanel/SettingGraph/nbValY/inputY.text)
	)
	if typeChart == 4:
		offset = 0;
	if AxScale.x == 0:
		AxScale.x = contents[0].size()-(1+offset);
		if AxScale.x >= 10:
			AxScale.x = 10;
	if AxScale.y == 0:
		AxScale.y = 9-offset;
		if AxScale.y >= 20:
			AxScale.y = 20;
	if zoom:
		maxVal = 9;
		AxScale.y = 10;
		AxScale.x = 10;
	else:
		page = 0;
	if page > 0:
		offset = offset+(page*maxVal);
	if maxVal == 0:
		maxPage = 0;
	else:
		maxPage = int(round((contents[0].size()-1.0/maxVal)/10.0));
	_error = btn.connect("pressed", self, "_on_ButtonPanel_pressed", [tab]);
	btn.text = "delete";
	btn.rect_position = Vector2(190,465);
	btn.rect_size = Vector2(100,20);
	tab.rect_position = Vector2(4,32);
	tab.rect_size = Vector2(480, 484);
	pan.rect_position = Vector2(5, 0);
	pan.rect_size = Vector2(470, 465);
	for content in contents:
		var indexColor: int = index;
		if offset > content.size()-2:
			offset = content.size()-2;
		if indexColor >= colors.size():
			indexColor = indexColor - colors.size();
		for key in content:
			if X[index].size() >= maxVal and maxVal > 1:
				AxScale.x = maxVal-1;
				break;
			X[index].append(float(key));
			Y[index].append(int(content[key]));
			if key < offset and offset != 0:
				X[index].remove(0);
				Y[index].remove(0);
		if typeChart != 4:
			functions.append(
				defineFunctionChart(
					[X[index], Y[index]],
					dictNameValues[index],
					[
						Color(colors[index]),  
						typeChart,
						typeFunction,
						typeMarker
					] 
				)
			);
		else:
			maxPage = 0;
			zoom = false;
			var local_index: int = 0;
			sum.resize(Y[index].size());
			for element in Y[index]:
				if sum[local_index] == null:
					sum[local_index] = 0;
				sum[local_index] += element;
				local_index += 1;
			if index == contents.size()-1:
				functions.resize(1);
				functions[0] = defineFunctionChart(
					[X[index], sum],
					dictNameValues[0],
					[
						Color(colors[0]),  
						typeChart,
						typeFunction,
						typeMarker
					] 
				);
		index += 1;
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.transparent
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.whitesmoke
	cp.draw_bounding_box = false
	cp.x_label = "Index"
	cp.y_label = "Values"
	cp.x_scale = int(AxScale.x)
	cp.y_scale = int(AxScale.y)
	cp.offset = int(offset);
	cp.interactive = true
	cp.zoom = zoom;
	nc.rect_size = Vector2(1, 0);
	pan.add_child(nc);
	tab.add_tab('calc');
	tab.add_child(pan);
	tab.add_child(btn);
	$PanelContainer/MainPanel/Resultats/TabContainer.add_child(tab);
	nc.plot(functions, cp)
	allTabs.set_tab_title(allTabs.get_child_count()-1, 'calc');
	allTabs.current_tab = allTabs.get_child_count()-1;
	
func defineFunctionChart(values, nameFunc, arrFunc):
	var typeChart = arrFunc[1];
	"""
	Si l'interpolation n'est pas défini, alors on met une interpolation par défaut
	"""
	if arrFunc[2] == -1:
		arrFunc[2] = 0;
	match typeChart:
#		SCATTER
		0:
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{ 
					color = arrFunc[0], 
					marker = arrFunc[3]
				}
			);
#		LINE
		1:
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{ 
					color = arrFunc[0], 
					type = Function.Type.LINE, 
					marker = arrFunc[3], 
					interpolation = arrFunc[2]
				}
			);
#			AREA
		2:
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{ 
					color = arrFunc[0], 
					type = Function.Type.AREA, 
					marker = arrFunc[3], 
					interpolation = arrFunc[2]
				}
			);
#			PIE
		3:
			var gradient: Gradient = Gradient.new()
			gradient.set_color(0, arrFunc[0])
			gradient.set_color(1, arrFunc[0].inverted())
			for index in values[0]:
				values[0][index] = str(values[0][index]);
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{ 
					gradient = gradient, 
					type = Function.Type.PIE
				}
			);
#			BAR
		4:
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{ 
					color = arrFunc[0], 
					bar_size = 5, 
					type = Function.Type.BAR
				}
			);
#			SIMPLE
		_:
			return Function.new(
				values[0], 
				values[1], 
				nameFunc, 
				{  
					color = arrFunc[0], 
					marker = arrFunc[3]
				}
			);

func _on_ButtonLast_pressed():
	if page <= 0:
		return;
	else:
		page -= 1
		removeAndCreateGraph(arrContent);

func _on_ButtonNext_pressed():
	if page >= maxPage-1:
		return;
	else:
		page += 1;
		removeAndCreateGraph(arrContent);
