@tool
extends ToolEditorExportPlatform
class_name DocEditorExportPlatform

## DocEditorExportPlatform
##
## A export platform for godot used to export formated api documents automatically during export.
## This plugin expects that a python executable is available to the environment under the termanal
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
## Used to invode [code]sphinx-build[/code] when using the module directly as an entry point.
const sphinx_MODULE_NAME := "sphinx"
## The cli flag for sphinx to specify the same of the builder to use.
const sphinx_BUILDERNAME_FLAG := "-M"
## The cli flag for sphinx to manually specify the configuration directory location.
const sphinx_CONF_DIR_FLAG := "--conf-dir"

## Function used to export builtin xml docs.
static func export_builtin_xml(to_path:String, include_base_types:=true,
							   keep_open := true
							  ) -> Error:
	assert(Engine.is_editor_hint())
	
	NovaTools.ensure_absolute_dir_exists(to_path)
	
	var args := [GODOT_EXPORT_DOC_FLAG, to_path]
	if not include_base_types:
		args.append(GODOT_EXPORT_NO_BASE_TYPES_FLAG)
	
	return await NovaTools.launch_editor_instance_async(args, "", keep_open)

## Function used to export loaded gdextention xml docs.
static func export_gdextention_xml(to_path:String, keep_open := true) -> Error:
	assert(Engine.is_editor_hint())
	
	NovaTools.ensure_absolute_dir_exists(to_path)

	var args = [GODOT_EXPORT_DOC_FLAG, to_path, GODOT_EXPORT_GDEXTENTION_FLAG]
	return await NovaTools.launch_editor_instance_async(args, "", keep_open)

## Function used to export loaded gdscript xml docs.
static func export_gdscript_xml(to_path:String,
								from_path := ProjectSettings.globalize_path("res://").rstrip("/"),
								keep_open := true
							   ) -> Error:
	assert(Engine.is_editor_hint())
	
	NovaTools.ensure_absolute_dir_exists(to_path)

	var args = [GODOT_EXPORT_DOC_FLAG, to_path, GODOT_EXPORT_GDSCRIPT_FLAG, from_path]
	return await NovaTools.launch_editor_instance_async(args, "", keep_open)


## Function used to run [code]make_rst.py[/code].
## This is best used when the [code]python_prefix[/code] is set in editor settings.
static func doc_xml_to_rst(xml_root_path:String,
						   outpath:String,
						   rst_converter_script_path:String,
						   keep_open := true
						  ) -> Error:
	assert(Engine.is_editor_hint())
	
	xml_root_path = ProjectSettings.globalize_path(xml_root_path).rstrip("/")
	outpath = ProjectSettings.globalize_path(outpath).rstrip("/")
	
	var err := NovaTools.ensure_absolute_dir_exists(outpath)
	if err != OK:
		return err
	
	var args = [xml_root_path]
	args += Array(NovaTools.get_children_dir_recursive(xml_root_path, true))
	args + [RST_CONVERTER_OUTPUT_FLAG, outpath, RST_CONVERTER_VERBOSE_FLAG]
	var ret_code := await NovaTools.launch_python_file_async(rst_converter_script_path,
														 args,
														 "",
														 keep_open
														)
	return OK if ret_code == 0 else FAILED

## Function used to run [code]sphinx[/code] on generated rst documents.
## This is best used when the [code]python_prefix[/code] is set in editor settings.
## [code]builder_name[/code]s included by default in sphinx are listed here
## [url]https://www.sphinx-doc.org/en/master/usage/builders/index.html[url].
static func doc_rst_to_other(rst_path:String,
							 outpath:String,
							 builder_name := "",
							 conf_path := "",
							 keep_open := true
							) -> Error:
	rst_path = ProjectSettings.globalize_path(rst_path)
	outpath = ProjectSettings.globalize_path(outpath)
	conf_path = ProjectSettings.globalize_path(conf_path)
	
	var args := []
	if builder_name != "":
		args = [sphinx_BUILDERNAME_FLAG, builder_name]
	args += [rst_path, outpath]
	if conf_path != "":
		args = args + [sphinx_CONF_DIR_FLAG, conf_path]
	
	var ret_code := await NovaTools.launch_python_module_async(sphinx_MODULE_NAME,
															   args,
															   "",
															   keep_open
															  )
	
	return OK if ret_code == 0 else FAILED

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
			"default_value": DocExportPlatformPlugin.MAKE_RST_DEFAULT_DOWNLOAD_PATH
		},
		
		{
			"name": "formats/sphinx/export_as_other_formats",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_TYPE_STRING,
			"hint_string": "%d:"%[TYPE_STRING],
			"default_value": []
		},
		{
			"name": "formats/sphinx/sphinx_conf_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"default_value": DocExportPlatformPlugin.SPHINX_CONF_DEFAULT_DOWNLOAD_PATH
		},
	] + super._get_export_options()

func _has_valid_project_configuration(preset: EditorExportPreset):
	var is_valid := true
	if not (preset.get_or_env("domains/export_gdscript", "")
			or preset.get_or_env("domains/export_gdextention", "")
			or preset.get_or_env("domains/export_builtin", "")
		   ):
		add_config_error("Must export at least one domain of docs.")
		is_valid = false
	if not (preset.get_or_env("formats/xml/export_as_xml", "")
			or preset.get_or_env("formats/rst/export_as_rst", "")
			or preset.get_or_env("formats/sphinx/export_as_other_formats", "").size() > 0
		   ):
		add_config_error("Must export at least one format of docs.")
		is_valid = false
	if preset.get_or_env("formats/sphinx/export_as_other_formats", "").size() > 0 and (
							 preset.get_or_env("formats/sphinx/sphinx_conf_path", "") is not String
							 or not DirAccess.dir_exists_absolute(
											preset.get_or_env("formats/sphinx/sphinx_conf_path", "")
							 									 )
																					  ):
		add_config_error("Invalid sphinx conf path.")
		is_valid = false
	return is_valid

func _export_hook(preset: EditorExportPreset, path: String):
	path = ProjectSettings.globalize_path("res://" + path)
	
	var keep_open:bool = preset.get_or_env("keep_console_open", "")
	
	#resolved paths for the exports of certian formats,
	#regardless or weather or not they are desired
	var xml_path := path.path_join("xml")
	var rst_path := path.path_join("rst")
	
	#actually desired outputs, not including the ones made for the sake of further generation
	var want_xml := preset.get_or_env("formats/rst/export_as_xml", "")
	var want_rst := preset.get_or_env("formats/rst/export_as_rst", "")
	var wanted_sphinx_builds = preset.get_or_env("formats/sphinx/export_as_other_formats", "")
	
	var err := OK
	
	#as we know we aren't running with no desired outputs and all steps originate from xml,
	#no need to check
	if preset.get_or_env("domains/export_gdscript", ""):
		err = await export_gdscript_xml(xml_path,
										ProjectSettings.globalize_path("res://").rstrip("/"),
										keep_open
									   )
		if err != OK:
			return err
	if preset.get_or_env("domains/export_gdextention", ""):
		err = await export_gdextention_xml(xml_path, keep_open)
		if err != OK:
			return err
	if preset.get_or_env("domains/export_builtin", ""):
		err = await export_builtin_xml(xml_path, keep_open)
		if err != OK:
			return err
	
	if want_rst or wanted_sphinx_builds.size() > 0:
		err = await doc_xml_to_rst(xml_path,
								   rst_path,
								   ProjectSettings.globalize_path(
										   preset.get_or_env("formats/rst/make_rst_script_path", "")
																 ),
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
	
	if not want_xml and DirAccess.dir_exists_absolute(xml_path):
		err = DirAccess.remove_absolute(xml_path)
		if err != OK:
			return err
	
	if not want_rst and DirAccess.dir_exists_absolute(rst_path):
		err = DirAccess.remove_absolute(rst_path)
		if err != OK:
			return err
	
	return OK
