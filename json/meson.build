conf = configuration_data()
conf.set ('prefix', get_option('prefix'))
conf.set ('libdir', get_option('libdir'))
conf.set ('PCDEPS', 'gtext-1.0 gee-0.8')
conf.set ('DEPS', 'gtext-1.0\ngee-0.8\n')

configure_file(input : 'deps.meson',
	output : 'gjson-1.0.deps',
	configuration : conf,
	install : true,
	install_dir : vapidir)
	
configure_file(input : 'pc.meson',
	output : 'gjson-1.0.pc',
	configuration : conf,
	install : true,
	install_dir : join_paths(get_option('libdir'), 'pkgconfig'))

sources = [
	'Array.vala',
	'BsonDataStream.vala',
	
	'BsonIOStream.vala',
	'BsonReader.vala',
	'BsonStream.vala',
	'BsonWriter.vala',
	'Container.vala',
	'Node.vala',
	'Object.vala',
	'Path.vala',
	'Reader.vala',
	'Serialize.vala',
	'StringSet.vala',
	'TextReader.vala',
	'TextWriter.vala',
	'Writer.vala',
	'VariantReader.vala',
	'VariantWriter.vala',
	'schema/Schema.vala',
	'schema/SchemaArray.vala',
	'schema/SchemaNumber.vala',
	'schema/SchemaObject.vala',
	'schema/SchemaString.vala'
]

cc = meson.get_compiler('c')
lm = cc.find_library('m')

gjson = library('gjson-1.0',
	sources,
	version : meson.project_version(),
	vala_header : 'gjson.h',
	vala_vapi : 'gjson-1.0.vapi',
	vala_gir : 'GJson-1.0.gir',
	dependencies : [ lm, gtext_dep ],
	install : true,
	install_dir : [
		get_option('libdir'),
		join_paths(get_option('includedir'), 'gjson-1.0'),
		vapidir,
		true
	])
	
gjson_dep = declare_dependency(
	dependencies : [ gtext_dep ],
	link_with : gjson,
	include_directories : include_directories('.')
)	

g_ir_compiler = find_program('g-ir-compiler')
custom_target('gjson-typelib',
	command: [
		g_ir_compiler,
		'--includedir', join_paths(meson.current_build_dir(), '..', 'text'),
		'--shared-library', 'libgjson-1.0.so.0',
		'--output', '@OUTPUT@', 
		join_paths(meson.current_build_dir(), 'GJson-1.0.gir')
	],
	output: 'GJson-1.0.typelib',
	depends: gjson,
	install: true,
	install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
