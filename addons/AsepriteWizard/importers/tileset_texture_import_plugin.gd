@tool
extends EditorImportPlugin

##
## Tileset texture importer.
## Imports Aseprite tileset layers as an AtlasTexture
##

const result_codes = preload("../config/result_codes.gd")
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()

var config = preload("../config/config.gd").new()
var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()


func _get_importer_name():
	return "aseprite_wizard.plugin.tileset-texture"


func _get_visible_name():
	return "Aseprite Tileset Texture"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "PortableCompressedTexture2D"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_TILESET_TEXTURE_NAME else 0.9


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return [
		{"name": "layer/exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "layer/only_visible_layers",    "default_value": false},
		{
			"name": "sheet/sheet_type",
			"default_value": "columns",
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "columns,horizontal,vertical,packed",
		},
		{
			"name": "sheet/sheet_columns",
			"default_value": 12,
		},
		{
			"name": "sheet/frame_padding",
			"default_value": 0,
		},
	]

func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)
	var source_path = source_file.get_base_dir()
	var source_basename = source_file.substr(source_path.length()+1, -1)
	source_basename = source_basename.substr(0, source_basename.rfind('.'))

	var aseprite_opts = {
		"exception_pattern": options['layer/exclude_layers_pattern'],
		"only_visible_layers": options['layer/only_visible_layers'],
		"output_filename": '',
		"output_folder": source_path,
		"sheet_type": options["sheet/sheet_type"],
		"frame_padding": options["sheet/frame_padding"],
		"sheet_columns": options["sheet/sheet_columns"],
	}

	var result = _generate_texture(absolute_source_file, aseprite_opts)

	if not result.is_ok:
		var extra_error_info = ""
		if result.code == result_codes.ERR_INVALID_ASEPRITE_SPRITESHEET:
			extra_error_info = " Make sure your Aseprite file contains at least one Tilemap layer."

		printerr("ERROR - Could not import aseprite file: %s.%s" % [result_codes.get_error_message(result.code), extra_error_info])
		return FAILED

	var sprite_sheet = result.content.sprite_sheet
	var data = result.content.data

	return _save_resource(sprite_sheet, save_path, result.content.data_file, data.meta.size)


func _generate_texture(absolute_source_file: String, options: Dictionary) -> Dictionary:
	var result = _aseprite_file_exporter.generate_tileset_files(absolute_source_file, options)

	if not result.is_ok:
		return result

	var sprite_sheet = result.content.sprite_sheet

	var data_result = _aseprite_file_exporter.load_json_content(result.content.data_file)

	if not data_result.is_ok:
		return data_result

	var data = data_result.content

	return result_codes.result({
		"data_file": result.content.data_file,
		"sprite_sheet": sprite_sheet,
		"data": data
	})


func _save_resource(sprite_sheet: String, save_path: String, data_file_path: String, size: Dictionary) -> int:
	var image = Image.load_from_file(ProjectSettings.globalize_path(sprite_sheet))

	var tex := PortableCompressedTexture2D.new()
	tex.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	var exit_code = ResourceSaver.save(tex, "%s.%s" % [save_path, _get_save_extension()])

	if config.should_remove_source_files():
		DirAccess.remove_absolute(data_file_path)
		DirAccess.remove_absolute(sprite_sheet)

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED

	return OK
