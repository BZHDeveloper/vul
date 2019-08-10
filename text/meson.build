conf = configuration_data()
conf.set ('prefix', get_option('prefix'))
conf.set ('libdir', get_option('libdir'))
conf.set ('DEPS', 'gio-2.0 gee-0.8')
conf.set ('VALADEPS', 'gio-2.0\ngee-0.8\n')

configure_file(input : 'deps.meson',
	output : 'gtext-1.0.deps',
	configuration : conf,
	install : true,
	install_dir : vapidir)
	
configure_file(input : 'pc.meson',
	output : 'gtext-1.0.pc',
	configuration : conf,
	install : true,
	install_dir : join_paths(get_option('libdir'), 'pkgconfig'))

sources = [
	'Guid.vala',
	'Encoding.vala',
	'Reader.vala',
	'StreamReader.vala',
	'StreamWriter.vala',
	'StringReader.vala',
	'StringWriter.vala',
	'TextReader.vala',
	'UnicodeEncoding.vala',
	'Utf8Encoding.vala',
	'Writer.vala'
]

gtext = library('gtext-1.0',
	sources,
	version : meson.project_version(),
	vala_header : 'gtext.h',
	vala_vapi : 'gtext-1.0.vapi',
	vala_gir : 'GText-1.0.gir',
	dependencies : [ gio, gee ],
	install : true,
	install_dir : [
		true,
		join_paths(get_option('includedir'), 'gtext-1.0'),
		vapidir,
		true
	])
	
gtext_dep = declare_dependency(
	dependencies : [ gio, gee ],
	link_with : gtext,
	include_directories : include_directories('.')
)	

g_ir_compiler = find_program('g-ir-compiler')
custom_target('gtext-typelib',
	command: [
		g_ir_compiler,
		'--shared-library', 'libgtext-1.0.so.0',
		'--output', '@OUTPUT@', 
		join_paths(meson.current_build_dir(), 'GText-1.0.gir')
	],
	output: 'GText-1.0.typelib',
	depends: gtext,
	install: true,
	install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
