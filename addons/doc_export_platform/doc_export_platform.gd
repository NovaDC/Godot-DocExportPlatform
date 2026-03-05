@tool
class_name DocEditorExportPlatform
extends ToolEditorExportPlatform

## DocEditorExportPlatform
##
## A export platform for godot used to export formatted api documents automatically during export.
## This plugin expects that a python executable is available to the environment under the terminal
## alias of [code]python[/code] or for the [code]python_prefix[/code] editor setting to be set.
## This also expects for that python environment to already have the [code]sphinx[/code] module
## available when exporting formats other than [code]rst[/code] or [code]xml[/code].[br]
## Requires the NovaTools plugin as a dependency.

## Command line argument used when godot when exporting xml documents.
const GODOT_EXPORT_DOC_FLAG := "--doctool"
## Command line argument used when godot when exporting xml documents.[br]
## Used to eliminate base types from being exported.
const GODOT_EXPORT_NO_BASE_TYPES_FLAG := "--no-docbase"
## Command line argument used when godot when exporting xml documents.[br]
## Used to export gdextention docs instead.
const GODOT_EXPORT_GDEXTENTION_FLAG := "--gdextention"
## Command line argument used when godot when exporting xml documents.[br]
## Used to export gdscript docs instead.
const GODOT_EXPORT_GDSCRIPT_FLAG := "--gdscript-docs"

## A command line argument for [code]make_rst.py[/code] used to specify the output path.
const RST_CONVERTER_OUTPUT_FLAG := "-o"
## A command line argument for [code]make_rst.py[/code] used to enable verbose output.
const RST_CONVERTER_VERBOSE_FLAG := "--verbose"

## The name of the sphinx module in python.[br]
## Used to invoke [code]sphinx-build[/code] when using the module directly as an entry point.
const SPHINX_MODULE_NAME := "sphinx"
## The cli flag for sphinx to specify the same of the builder to use.
const SPHINX_BUILDER_NAME_FLAG := "-M"
## The cli flag for sphinx to manually specify the configuration directory location.
const SPHINX_CONF_DIR_FLAG := "--conf-dir"
## A list of select preinstalled sphinx builders to use for inspector suggestions.
const SPHINX_COMMON_FORMATS:Array[String] = ["applehelp",
												"devhelp",
												"dirhtml",
												"epub",
												"gettext",
												"html",
												"htmlhelp",
												"latex",
												"man",
												"qthelp",
												"singlehtml",
												"texinfo",
												"text",
											]

## A function used to export builtin xml docs.[br]
## [param to_path] is the directory the builtin's xml docs will be exported to.[br]
## If [param include_base_types] is set, base [Variant] type's docs will also be exported.[br]
## If [param keep_open] is set, the terminal window will not automaticaly close,
## instead waiting for the user to close it.
static func export_builtin_xml(to_path:String,
								include_base_types:=true,
								keep_open := true
								) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	NovaTools.ensure_absolute_dir_exists(to_path)

	var args:Array = [GODOT_EXPORT_DOC_FLAG, to_path]
	if not include_base_types:
		args.append(GODOT_EXPORT_NO_BASE_TYPES_FLAG)

	await NovaTools.launch_editor_instance_async(args, "", keep_open)
	return OK

## Function used to export loaded gdextention xml docs.[br]
## There is currently no way to select certain loaded GDExtensions.[br]
## [param to_path] is the directory all loaded gdextention's xml docs
## will be exported to.[br]
## If [param keep_open] is set, the terminal window will not automaticaly close,
## instead waiting for the user to close it.
static func export_gdextention_xml(to_path:String, keep_open := true) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	NovaTools.ensure_absolute_dir_exists(to_path)

	var args = [GODOT_EXPORT_DOC_FLAG, to_path, GODOT_EXPORT_GDEXTENTION_FLAG]
	await NovaTools.launch_editor_instance_async(args, "", keep_open)
	return OK

## Function used to export loaded gdscript xml docs.[br]
## [param to_path] is the directory all relevant gdscript's xml docs
## will be exported to.[br]
## [param from_path] is the base directory for all gdscripts that will be documented.
## If this is set to the root of the project (as is by default),
## all gdscripts will be documented.[br]
## If [param keep_open] is set, the terminal window will not automaticaly close,
## instead waiting for the user to close it.
static func export_gdscript_xml(to_path:String,
								from_path := NovaTools.normalize_path_absolute("res://", false),
								keep_open := true
								) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	NovaTools.ensure_absolute_dir_exists(to_path)

	var args = [GODOT_EXPORT_DOC_FLAG, to_path, GODOT_EXPORT_GDSCRIPT_FLAG, from_path]
	await NovaTools.launch_editor_instance_async(args, "", keep_open)
	return OK

## Function used to run [code]make_rst.py[/code].[br]
## [param xml_root_path] is the root directory of the xml docs to convert.[br]
## [param out_path] is the directory that the rst docs will be placed in.[br]
## [param make_rst_script_path] is path to the [code]make_rst.py[/code] file itself.[br]
## If [param keep_open] is set, the terminal window will not automaticaly close,
## instead waiting for the user to close it.[br]
## Errors may occur if [code]python_prefix[/code] is not set in [EditorSettings].
static func doc_xml_to_rst(xml_root_path:String,
							out_path:String,
							make_rst_script_path:String,
							keep_open := true
							) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	xml_root_path = NovaTools.normalize_path_absolute(xml_root_path, false)
	out_path = NovaTools.normalize_path_absolute(out_path, false)
	make_rst_script_path = NovaTools.normalize_path_absolute(make_rst_script_path, false)

	if make_rst_script_path.is_empty():
		return ERR_FILE_NOT_FOUND

	var err:int = NovaTools.ensure_absolute_dir_exists(out_path)
	if err != OK:
		return err

	var args = [xml_root_path]
	args += Array(NovaTools.get_children_dir_recursive(xml_root_path, true))
	args += [RST_CONVERTER_OUTPUT_FLAG, out_path, RST_CONVERTER_VERBOSE_FLAG]
	await NovaTools.launch_python_file_async(make_rst_script_path,
																args,
																"",
																keep_open
															)
	return OK

## Function used to run [code]sphinx[/code] on generated rst documents.[br]
## [param rst_path] is the root directory of the rst docs to convert.[br]
## [param out_path] is the directory that the converted will be placed in.[br]
## [param builder_name] is the specific name of the sphinx builder to use for doc conversion.
## [param builder_name]s included by default in sphinx are listed here
## [url]https://www.sphinx-doc.org/en/master/usage/builders/index.html[url], and
## all installed sphinx extensions should also work as is.[br]
## [param conf_path] is the directory to the sphinx conf to use when converting.
## Note that godot's docs may not properly convert without a sphinx conf that
## accounts for the specific markup used.
## A good choice would be to use the sphinx conf already used by Godot's docs.[br]
## Errors may occur if [code]python_prefix[/code] is not set in [EditorSettings].
static func doc_rst_to_other(rst_path:String,
								out_path:String,
								builder_name := "",
								conf_path := "",
								keep_open := true
							) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	if not builder_name.is_empty():
		builder_name = builder_name.strip_edges().strip_escapes()
		if builder_name.is_empty():
			return ERR_INVALID_PARAMETER

	rst_path = NovaTools.normalize_path_absolute(rst_path, false)
	out_path = NovaTools.normalize_path_absolute(out_path, false)
	conf_path = NovaTools.normalize_path_absolute(conf_path, false)

	if conf_path.is_empty() or not DirAccess.dir_exists_absolute(conf_path):
		return ERR_DOES_NOT_EXIST

	var args:Array = []
	if builder_name != "":
		args = [SPHINX_BUILDER_NAME_FLAG, builder_name]
	args += [rst_path, out_path]
	if conf_path != "":
		args = args + [SPHINX_CONF_DIR_FLAG, conf_path]

	await NovaTools.launch_python_module_async(SPHINX_MODULE_NAME,
																args,
																"",
																keep_open
																)
	return OK

func _get_name():
	return "Docs"

func _get_logo():
	var size = Vector2i.ONE * floori(32 * EditorInterface.get_editor_scale())
	return NovaTools.get_editor_icon_named("Help", size)

func _get_export_option_visibility(preset: EditorExportPreset, option: String) -> bool:
	match (option):
		var s when s.begins_with("formats/rst/"):
			return preset.get_or_env("formats/xml/export_as_xml", "")
		var s when s.begins_with("formats/sphinx/"):
			return (preset.get_or_env("formats/xml/export_as_xml", "") and
					preset.get_or_env("formats/rst/export_as_rst", "")
					)
		_:
			return true

func _get_export_options():
	return [
		{
			"name": "keep_console_open",
			"type": TYPE_BOOL,
			"default_value": true
		},
		{
			"name": "domains/export_gdscript",
			"type": TYPE_BOOL,
			"default_value": true
		},
		{
			"name": "domains/export_gdextention",
			"type": TYPE_BOOL,
			"default_value": true
		},
		{
			"name": "domains/export_builtin",
			"type": TYPE_BOOL,
			"default_value": true
		},

		{
			"name": "formats/xml/export_as_xml",
			"type": TYPE_BOOL,
			"default_value": true,
			"update_visibility": true
		},

		{
			"name": "formats/rst/export_as_rst",
			"type": TYPE_BOOL,
			"default_value": true,
			"update_visibility": true
		},
		{
			"name": "formats/rst/make_rst_script_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"default_value": DocExportPlatformPlugin.get_make_rst_download_path()
		},

		{
			"name": "formats/sphinx/export_as_other_formats",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d/%d:%s" % [TYPE_STRING,
											PROPERTY_HINT_ENUM_SUGGESTION,
											",".join(SPHINX_COMMON_FORMATS)
											],
			"default_value": []
		},
		{
			"name": "formats/sphinx/sphinx_conf_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"default_value": DocExportPlatformPlugin.get_sphinx_conf_download_path().path_join(DocExportPlatformPlugin.SPHINX_CONF_ROOT_DIR).simplify_path()
		},
	] + super._get_export_options()

func _get_export_option_warning(preset: EditorExportPreset, option: StringName) -> String:
	match (option):
		"formats/sphinx/export_as_other_formats":
			var sphinx_formats := _normalize_wanted_sphinx_builds(preset)
			if "xml" in sphinx_formats or "pseudoxml" in sphinx_formats:
				return ("Note that xml and pseudoxml formats provided by sphinx " +
						"are not the same as godot's xml formatting."
						)
	return ""

func _has_valid_project_configuration(preset: EditorExportPreset):
	var is_valid := true
	var using_sphinx:bool = _normalize_wanted_sphinx_builds(preset).size() > 0
	var sphinx_conf_path = preset.get_or_env("formats/sphinx/sphinx_conf_path", "")
	sphinx_conf_path = NovaTools.normalize_path_absolute(sphinx_conf_path, false)
	var make_rst_script_path = preset.get_or_env("formats/rst/make_rst_script_path", "")
	make_rst_script_path = NovaTools.normalize_path_absolute(sphinx_conf_path, false)

	if not (preset.get_or_env("domains/export_gdscript", "")
			or preset.get_or_env("domains/export_gdextention", "")
			or preset.get_or_env("domains/export_builtin", "")
			):
		add_config_error("Must export at least one domain of docs.")
		is_valid = false
	if not (preset.get_or_env("formats/xml/export_as_xml", "")
			or preset.get_or_env("formats/rst/export_as_rst", "")
			or using_sphinx
			):
		add_config_error("Must export at least one format of docs.")
		is_valid = false

	if preset.get_or_env("formats/rst/export_as_rst", "") and (make_rst_script_path.is_empty() or
							not DirAccess.dir_exists_absolute(make_rst_script_path)
						):
		add_config_error("Invalid make_rst script path. Ensure this tool is installed.")
		is_valid = false
	if using_sphinx and not sphinx_conf_path.is_empty() and not DirAccess.dir_exists_absolute(sphinx_conf_path):
		add_config_error("Invalid sphinx conf path. Ensure this the path is correct, or leave it empty to not use.")
		is_valid = false

	return is_valid

func _normalize_wanted_sphinx_builds(preset:EditorExportPreset) -> PackedStringArray:
	var builds = preset.get_or_env("formats/sphinx/export_as_other_formats", "")
	match(typeof(builds)):
		TYPE_NIL, TYPE_MAX:
			return PackedStringArray()
		TYPE_PACKED_STRING_ARRAY:
			builds = Array(builds)
		var t when NovaTools.typeof_is_any_array(t):
			builds = Array(builds.map(str))
		_:
			builds = [str(builds)]
	builds = builds.map(func (b): return b.strip_escapes().strip_edges())
	builds = builds.filter(func (b): return not b.is_empty())
	return PackedStringArray(builds)

func _export_hook(preset: EditorExportPreset, path: String):
	path = NovaTools.normalize_path_absolute("res://".path_join(path), false)

	var keep_open:bool = preset.get_or_env("keep_console_open", "")

	#resolved paths for the exports of certain formats,
	#regardless or weather or not they are desired
	var xml_path := path.path_join("xml")
	var rst_path := path.path_join("rst")

	#actually desired outputs, not including the ones made for the sake of further generation
	var want_xml = preset.get_or_env("formats/rst/export_as_xml", "")
	var want_rst = preset.get_or_env("formats/rst/export_as_rst", "")
	var wanted_sphinx_builds := _normalize_wanted_sphinx_builds(preset)

	var err:int = OK

	#as we know we aren't running with no desired outputs and all steps originate from xml,
	#no need to check
	if preset.get_or_env("domains/export_gdscript", ""):
		err = await export_gdscript_xml(xml_path,
										NovaTools.normalize_path_absolute("res://", false),
										keep_open
										)
		if err != OK:
			return err
	if preset.get_or_env("domains/export_gdextention", ""):
		err = await export_gdextention_xml(xml_path, keep_open)
		if err != OK:
			return err
	if preset.get_or_env("domains/export_builtin", ""):
		err = await export_builtin_xml(xml_path, true, keep_open)
		if err != OK:
			return err

	if want_rst or wanted_sphinx_builds.size() > 0:
		err = await doc_xml_to_rst(xml_path,
									rst_path,
									preset.get_or_env("formats/rst/make_rst_script_path", ""),
									keep_open
									)
		if err != OK:
			return err

	for sphinx_format in wanted_sphinx_builds:
		var sphinx_format_stripped = sphinx_format.replace("/", "").replace(" ", "").to_lower()
		var sphinx_path := path.path_join(sphinx_format_stripped)
		err = await doc_rst_to_other(rst_path,
										sphinx_path,
										sphinx_format,
										preset.get_or_env("formats/sphinx/sphinx_conf_path", ""),
										keep_open
									)
		if err != OK:
			return err

	if err == OK and not want_xml and DirAccess.dir_exists_absolute(xml_path):
		err = DirAccess.remove_absolute(xml_path)

	if err == OK and not want_rst and DirAccess.dir_exists_absolute(rst_path):
		err = DirAccess.remove_absolute(rst_path)

	return err
