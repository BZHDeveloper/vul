conf = configuration_data()
conf.set ('prefix', get_option('prefix'))
conf.set ('libdir', get_option('libdir'))
conf.set ('VALADEPS', 'gio-2.0\ngee-0.8')
conf.set ('PCDEPS', 'gio-2.0 gee-0.8')

configure_file(input : 'deps.meson',
	output : 'gcl-1.0.deps',
	configuration : conf,
	install : true,
	install_dir : vapidir)
	
configure_file(input : 'pc.meson',
	output : 'gcl-1.0.pc',
	configuration : conf,
	install : true,
	install_dir : join_paths(get_option('libdir'), 'pkgconfig'))

sources = [
	'Entry.vala',
	'Entries.vala',
	'Archive.vala'
]

gcl = library('gcl-1.0',
	sources,
	version : meson.project_version(),
	vala_header : 'gcl.h',
	vala_vapi : 'gcl-1.0.vapi',
	vala_gir : 'Gcl-1.0.gir',
	vala_args : [
		'--vapidir', '@0@/vapis'.format(meson.current_source_dir())
	],
	dependencies : [ gio, gee, arch ],
	install : true,
	install_dir : [
		get_option('libdir'),
		join_paths(get_option('includedir'), 'gcl-1.0'),
		vapidir,
		true
	])

g_ir_compiler = find_program('g-ir-compiler')
custom_target('gcl-typelib',
	command: [
		g_ir_compiler,
		'--shared-library', 'libgcl-1.0.so.0',
		'--output', '@OUTPUT@', 
		join_paths(meson.current_build_dir(), 'Gcl-1.0.gir')
	],
	output: 'Gcl-1.0.typelib',
	depends: gcl,
	install: true,
	install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
