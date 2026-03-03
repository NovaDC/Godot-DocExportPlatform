@tool
class_name DocExportPlatformPlugin
extends EditorPlugin

## The http host to download the default [code]sphinx_conf[/code] from.
const SPHINXCONF_HOST := "https://codeload.github.com"
## The http path to download the default [code]sphinx_conf[/code] from.
const SPHINXCONF_PATH := "/godotengine/godot-docs/zip/refs/heads/master"

## The http host to download the default [code]make_rst.py[/code] file from.
const MAKE_RST_HOST := "https://raw.githubusercontent.com"
## The http path to download the default [code]make_rst.py[/code] file from.
const MAKE_RST_PATH := "/godotengine/godot/refs/heads/master/doc/tools/make_rst.py"
## The http host to download the default [code]methods.py[/code] file
## from (dependency of [code]make_rst.py[/code]).
const METHODS_HOST := "https://raw.githubusercontent.com"
## The http path to download the default [code]methods.py[/code] file
## from (dependency of [code]make_rst.py[/code]).
const METHODS_PATH := "/godotengine/godot/refs/heads/master/methods.py"
## The http host to download the default [code]platform_methods.py[/code] file
## from (dependency of [code]make_rst.py[/code]).
const PLATFROM_METHODS_HOST := "https://raw.githubusercontent.com"
## The http path to download the default [code]platform_methods.py[/code] file
## from (dependency of [code]make_rst.py[/code]).
const PLATFROM_METHODS_PATH := "/godotengine/godot/refs/heads/master/platform_methods.py"

const PLUGIN_NAME := "doc_export_platform"
## The internal name of this plugin.

var _export_platform_ref:DocEditorExportPlatform = null

const _MAKE_RST_DOWNLOAD_PATH_DEFAULT := "res://doc_export/make_rst.py"
const _SPHINX_CONF_DOWNLOAD_PATH_DEFAULT := "res://doc_export/"

const _MAKE_RST_DOWNLOAD_PATH_SETTING_NAME = PLUGIN_NAME_INTERNAL + "/make_rst_download_path"
const _SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME = PLUGIN_NAME_INTERNAL + "/sphinx_conf_download_path"

static func _add_project_setting(name:String, type:Variant.Type, default:Variant = null, hint := PROPERTY_HINT_NONE, hint_string := "", basic := true) -> bool:
	if ProjectSettings.has_setting(name):
		return false

	ProjectSettings.set_setting(name, default)
	ProjectSettings.add_property_info({
		"name" : name,
		"type" : type,
		"hint" : hint,
		"hint_string" : hint_string,
	})
	ProjectSettings.set_as_basic(name, basic)
	ProjectSettings.set_initial_value(name, default)

	return true

static func _try_remove_project_setting(name:String) -> bool:
	if not ProjectSettings.has_setting(name):
		return false
	ProjectSettings.set_setting(name, null)
	return true

## Return the path that [code]make_rst.py[/code] should be downloaded to, using the setting in [ProjectSettings]
## if possible, or falling back to the default in cases where the path is invalid or unset.
static func get_make_rst_download_path() -> String:
	var ret = _MAKE_RST_DOWNLOAD_PATH_DEFAULT
	if ProjectSettings.has_setting(_MAKE_RST_DOWNLOAD_PATH_SETTING_NAME):
		ret = ProjectSettings.get_setting_with_override(_MAKE_RST_DOWNLOAD_PATH_SETTING_NAME)
		ret = NovaTools.normalize_path_absolute(ret, false)
		if ret.is_empty():
			ret = _MAKE_RST_DOWNLOAD_PATH_DEFAULT
	return ret

## Return the path that Godot's sphinx conf should be downloaded to, using the setting in [ProjectSettings]
## if possible, or falling back to the default in cases where the path is invalid or unset.
static func get_sphinx_conf_download_path() -> String:
	var ret = _SPHINX_CONF_DOWNLOAD_PATH_DEFAULT
	if ProjectSettings.has_setting(_SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME):
		ret = ProjectSettings.get_setting_with_override(_SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME)
		ret = NovaTools.normalize_path_absolute(ret, false)
		if ret.is_empty():
			ret = _SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME
	return ret

## A builtin function that downloads [code]make_rst.py[/code]
## (and it's dependencies, [code]methods.py[/code] and [code]platform_methods.py[/code]) to
## and generates an appropriate [code]version.py[/code] file in
## a location determined by a file selector.[br]
## This command is effectively the equivalent to clicking the setup make rst command
## in the [kbd]Project > NovaTools[/kbd] menu.
static func setup_make_rst():
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	var on_conf := func(at_path:String):
		if at_path == "":
			return OK

		at_path = NovaTools.normalize_path_absolute(at_path, false)

		var err :=  NovaTools.ensure_absolute_dir_exists(at_path)
		if err != OK:
			return err

		err = NovaTools.generate_version_py(at_path)
		if err != OK:
			return err

		err = await NovaTools.download_http_async(at_path.rstrip("/") + "/make_rst.py",
											  MAKE_RST_HOST,
											  MAKE_RST_PATH
											 )
		if err != OK:
			return err

		err = await NovaTools.download_http_async(at_path.rstrip("/") + "/methods.py",
											  METHODS_HOST,
											  METHODS_PATH
											 )
		if err != OK:
			return err

		return await NovaTools.download_http_async(at_path.rstrip("/") + "/platform_methods.py",
											   PLATFROM_METHODS_HOST,
											   PLATFROM_METHODS_PATH
											  )

	NovaTools.quick_editor_file_dialog(on_conf, "Save Make RST To...", PackedStringArray(),
								   get_make_rst_download_path(),
								   EditorFileDialog.FILE_MODE_OPEN_DIR,
								   EditorFileDialog.ACCESS_RESOURCES
								  )

## A builtin function that downloads the default latest
## [code]godot-docs[/code] [code]sphinx_conf[/code]
## file to a location determined from a file selector popup.[br]
## This command is effectively the equivalent to clicking the setup sphinx conf command
## in the [kbd]Project > NovaTools[/kbd] menu.
static func download_sphinx_conf():
	if not Engine.is_editor_hint():
		return ERR_UNAVAILABLE

	var on_conf := func (to_path:String):
		if to_path == "":
			return OK

		to_path = NovaTools.normalize_path_absolute(to_path, false)

		var down_func := NovaTools.download_http_async.bind(to_path + "/master.zip",
														SPHINXCONF_HOST,
														SPHINXCONF_PATH
													   )
		var err := await NovaTools.show_wait_window_while_async("Please wait for the download...",
															down_func
														   )
		if err != OK:
			return err
		var decomp_func := NovaTools.decompress_zip_async.bind(to_path + "/master.zip",
														   to_path + "/"
														  )
		err = await NovaTools.show_wait_window_while_async("Please wait for decompression...",
													   decomp_func
													  )
		if err != OK:
			return err

		return DirAccess.remove_absolute(to_path.rstrip("/") + "/master.zip")

	NovaTools.quick_editor_file_dialog(on_conf,
								   "Save Sphinx Conf To...",
								   PackedStringArray(),
								   get_sphinx_conf_download_path(),
								   EditorFileDialog.FILE_MODE_OPEN_DIR,
								   EditorFileDialog.ACCESS_RESOURCES
								  )


func _get_plugin_name():
	return PLUGIN_NAME

func _get_plugin_icon():
	return NovaTools.get_editor_icon_named("Help", Vector2i.ONE * 16)

func _enter_tree():
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME):
		_try_init_platform()

func _enable_plugin():
	_try_init_platform()

func _disable_plugin():
	_try_deinit_platform()

func _exit_tree():
	_try_deinit_platform()

func _try_init_platform():
	NovaTools.try_init_python_prefix_editor_setting()
	_add_project_setting(_MAKE_RST_DOWNLOAD_PATH_SETTING_NAME,
							TYPE_STRING,
							_MAKE_RST_DOWNLOAD_PATH_DEFAULT,
							PROPERTY_HINT_GLOBAL_SAVE_FILE,
							"*.py"
	)
	_add_project_setting(_SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME,
							TYPE_STRING,
							_SPHINX_CONF_DOWNLOAD_PATH_DEFAULT,
							PROPERTY_HINT_GLOBAL_DIR,
	)
	if _export_platform_ref == null:
		add_tool_menu_item("Download rst Document Genorator...", setup_make_rst)
		add_tool_menu_item("Download Default Sphinx Configuration...", download_sphinx_conf)
		_export_platform_ref = DocEditorExportPlatform.new()
		add_export_platform(_export_platform_ref)

func _try_deinit_platform():
	NovaTools.try_deinit_python_prefix_editor_setting()
	_try_remove_project_setting(_MAKE_RST_DOWNLOAD_PATH_SETTING_NAME)
	_try_remove_project_setting(_SPHINX_CONF_DOWNLOAD_PATH_SETTING_NAME)
	if _export_platform_ref != null:
		remove_tool_menu_item("Download rst document genorator...")
		remove_tool_menu_item("Download default sphinx configuration...")
		remove_export_platform(_export_platform_ref)
		_export_platform_ref = null
