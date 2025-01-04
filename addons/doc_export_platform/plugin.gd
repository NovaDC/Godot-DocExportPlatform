@tool
class_name DocExportPlatformPlugin
extends EditorPlugin


## The deafult resource path to download or find [code]make_rst.py[/code] and it's related files in.
const MAKE_RST_DEFAULT_DOWNLOAD_PATH := "res://doc_export/make_rst.py"
## The deafult resource path to download or find the [code]sphinx_conf[/code] directory in.
const SPHINX_CONF_DEFAULT_DOWNLOAD_PATH := "res://doc_export"

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

## The name of this plugin.
const PLUGIN_NAME := "doc_export_platform"

var _export_platform_ref:DocEditorExportPlatform = null

## A builtin function that downloads [code]make_rst.py[/code]
## (and it's dependencies, [code]methods.py[/code] and [code]platform_methods.py[/code]) to
## and generares an appropriate [code]version.py[/code] file in
## a location determined by a file selector.[br]
## This command is effectively the equivlent to clicking the setup make rst command
## in the [kbd]Project > NovaTools[/kbd] menu.
static func setup_make_rst():
	assert(Engine.is_editor_hint())
	
	var on_conf := func(at_path:String):
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
								   MAKE_RST_DEFAULT_DOWNLOAD_PATH,
								   EditorFileDialog.FILE_MODE_OPEN_DIR,
								   EditorFileDialog.ACCESS_RESOURCES
								  )

## A builtin function that downloads the default latest
## [code]godot-docs[/code] [code]sphinx_conf[/code]
## file to a location determined from a file selector popup.[br]
## This command is effectively the equivlent to clicking the setup sphinx conf command
## in the [kbd]Project > NovaTools[/kbd] menu.
static func download_sphinx_conf():
	assert(Engine.is_editor_hint())
	
	var on_conf := func (to_path:String):
		if to_path == "":
			return OK
		
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
								   SPHINX_CONF_DEFAULT_DOWNLOAD_PATH,
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
	if _export_platform_ref == null:
		NovaTools.try_init_python_prefix_editor_setting()
		add_tool_menu_item("Download rst Document Genorator...", setup_make_rst)
		add_tool_menu_item("Download Default Sphinx Configuration...", download_sphinx_conf)
		_export_platform_ref = DocEditorExportPlatform.new()
		add_export_platform(_export_platform_ref)

func _try_deinit_platform():
	if _export_platform_ref != null:
		NovaTools.try_deinit_python_prefix_editor_setting()
		remove_tool_menu_item("Download rst document genorator...")
		remove_tool_menu_item("Download default sphinx configuration...")
		remove_export_platform(_export_platform_ref)
		_export_platform_ref = null
