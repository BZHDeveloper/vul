project('vul',
	['vala', 'c'],
	version : '0.3.0')

vapidir = join_paths(get_option('datadir'), 'vala/vapi')
girdir = join_paths(get_option('datadir'), 'gir-1.0')

gio = dependency('gio-2.0')
gee = dependency('gee-0.8', fallback : [ 'libgee', 'gee_dep' ])
arch = dependency('libarchive', required : false)

subdir('text')
subdir('json')

if(arch.found())
	subdir('gcl')
endif
