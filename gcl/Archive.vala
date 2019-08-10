namespace Gcl {
	public errordomain ArchiveError {
		NULL,
		WARN,
		FAILED,
		FATAL
	}
	
	public enum ArchiveFilter {
		NONE,
		GZIP,
		BZIP2,
		COMPRESS,
		PROGRAM,
		LZMA,
		XZ,
		UU,
		RPM,
		LZIP,
		LRZIP,
		LZOP,
		GRZIP,
		LZ4
	}
	
	[Flags]
	public enum ArchiveFormat {
		BASE_MASK = 0xff0000,
		CPIO = 0x10000,
		CPIO_POSIX = (CPIO | 1),
		CPIO_BIN_LE = (CPIO | 2),
		CPIO_BIN_BE = (CPIO | 3),
		CPIO_SVR4_NOCRC = (CPIO | 4),
		CPIO_SVR4_CRC = (CPIO | 5),
		CPIO_AFIO_LARGE = (CPIO | 6),
		SHAR = 0x20000,
		SHAR_BASE = (SHAR | 1),
		SHAR_DUMP = (SHAR | 2),
		TAR = 0x30000,
		TAR_USTAR = (TAR | 1),
		TAR_PAX_INTERCHANGE = (TAR | 2),
		TAR_PAX_RESTRICTED = (TAR | 3),
		TAR_GNUTAR = (TAR | 4),
		ISO9660 = 0x40000,
		ISO9660_ROCKRIDGE = (ISO9660 | 1),
		ZIP = 0x50000,
		EMPTY = 0x60000,
		AR = 0x70000,
		AR_GNU = (AR | 1),
		AR_BSD = (AR | 2),
		MTREE = 0x80000,
		RAW = 0x90000,
		XAR = 0xA0000,
		LHA = 0xB0000,
		CAB = 0xC0000,
		RAR = 0xD0000,
		SEVEN_ZIP = 0xE0000,
		WARC = 0xF0000
	}
	
	internal class ReadContext {
		public GLib.InputStream input_stream;
		public uint8[] buffer;
		
		public ReadContext (GLib.InputStream input_stream) {
			this.input_stream = input_stream;
			buffer = new uint8[8192];
		}
	}
	
	public class Archive : GLib.Object {
		Entries list;
		
		construct {
			list = new Entries();
		}
		
		public string password { get; set; }
		
		public Gee.List<Gcl.Entry> entries {
			get {
				return list;
			}
		}
		
		static int default_callback (LibArchive.Archive arch, void* data) {
			return LibArchive.Result.OK;
		}
		
		static ssize_t read_callback (LibArchive.Archive arch, void* data, out void* buffer) {
			ReadContext context = (ReadContext)data;
			try {
				ssize_t count = context.input_stream.read (context.buffer);
				buffer = context.buffer;
				return count;
			}
			catch (Error e) {
				arch.set_error (Posix.errno, e.message);
				return 0;
			}
		}
		
		static ssize_t write_callback (LibArchive.Archive arch, void* data, uint8[] buffer) {
			OutputStream stream = (OutputStream)data;
			try {
				return stream.write (buffer);
			}
			catch (Error e) {
				arch.set_error (Posix.errno, e.message);
				return 0;
			}
		}
		
		static ArchiveError error_from_libarchive (LibArchive.Result result, string error_string) {
			if (result == LibArchive.Result.WARN)
				return new ArchiveError.WARN (error_string);
			if (result == LibArchive.Result.FAILED)
				return new ArchiveError.FAILED (error_string);
			if (result == LibArchive.Result.FATAL)
				return new ArchiveError.FATAL (error_string);
			return new ArchiveError.NULL (error_string);
		}
		
		static void write_children (LibArchive.Write write, Gee.List<Entry> children) throws GLib.Error {
			for (var i = 0; i < children.size; i++) {
				var entry = children[i];
				if (entry.name == null)
					throw new IOError.INVALID_DATA ("entry's name cannot be null");
				var aentry = new LibArchive.Entry();
				aentry.set_pathname (entry.path);
				aentry.set_size (entry.size);
				if (entry.group_name != null) {
					unowned Posix.Group? grp = Posix.getgrnam (entry.group_name);
					if (grp != null)
						aentry.set_gid (grp.gr_gid);
				}
				if (entry.user_name != null) {
					unowned Posix.Passwd? pwd = Posix.getpwnam (entry.user_name);
					if (pwd != null)
						aentry.set_uid (pwd.pw_uid);
				}
				if (entry.modification_time != null)
					aentry.set_mtime ((time_t)entry.modification_time.to_unix(), 0);
				if (entry.creation_time != null)
					aentry.set_mtime ((time_t)entry.creation_time.to_unix(), 0);
				if (entry.access_time != null)
					aentry.set_mtime ((time_t)entry.access_time.to_unix(), 0);
				aentry.set_perm (0644);
				if (entry is Directory) {
					aentry.set_filetype ((uint)Posix.S_IFDIR);
					write.write_header (aentry);
					write_children (write, (entry as Directory).children);
				}
				else {
					aentry.set_filetype ((uint)Posix.S_IFREG);
					write.write_header (aentry);
					uint8[] buffer = new uint8[1024];
					ssize_t count = 0;
					while ((count = entry.iostream.input_stream.read (buffer)) > 0) {
						if (count < 1024)
							buffer.resize ((int)count);
						write.write_data (buffer);
						if (write.error_string() != null)
							throw error_from_libarchive (LibArchive.Result.FATAL, write.error_string());
					}
				}
			}
		}
		
		public Gcl.Entry? find (string path) {
			string[] parts = path.split ("/");
			if (parts.length == 0)
				return null;
			if (parts[parts.length - 1].length == 0)
				parts.resize (parts.length - 1);
			if (parts.length == 0)
				return null;
			for (var i = 0; i < entries.size; i++) {
				if (entries[i].name == parts[0]) {
					var entry = entries[i];
					if (entry is Directory && parts.length > 1)
						return (entry as Directory).find (path.substring (1 + path.index_of ("/")));
					if (!(entry is Directory) && parts.length > 1)
						return null;
					return entry;
				}
			}
			return null;
		}
		
		public void write_to (GLib.OutputStream output_stream, Gcl.ArchiveFormat format, Gcl.ArchiveFilter filter = Gcl.ArchiveFilter.NONE) throws GLib.Error {
			var arch = new LibArchive.Write();
			LibArchive.Format fmt = (LibArchive.Format)format;
			LibArchive.Filter ftr = (LibArchive.Filter)filter;
			arch.set_format (fmt);
			arch.add_filter (ftr);
			if (password != null) {
				if (format == ArchiveFormat.ZIP)
					if (arch.set_options ("zip:encryption=zipcrypt") != 0)
						throw error_from_libarchive (LibArchive.Result.FAILED, arch.error_string());
				arch.set_passphrase (password);
			}
			var result = arch.open (output_stream, default_callback, write_callback, default_callback);
			if (result != LibArchive.Result.OK)
				throw error_from_libarchive (LibArchive.Result.FATAL, arch.error_string());
			write_children (arch, entries);
		}
		
		public static Gcl.Archive open_stream (GLib.InputStream input_stream) throws GLib.Error {
			var context = new ReadContext (input_stream);
			var archive = new Archive();
			var arch = new LibArchive.Read();
			arch.support_filter_all();
			arch.support_format_all();
			var res = arch.open (context, default_callback, read_callback, default_callback);
			if (res != LibArchive.Result.OK)
				throw error_from_libarchive (res, arch.error_string());
			unowned LibArchive.Entry e;
			var tmp = new Gee.ArrayList<string>();
			var map = new Gee.HashMap<string, Entry>();
			while ((res = arch.next_header (out e)) == LibArchive.Result.OK) {
				bool isdir = e.pathname()[e.pathname().length - 1] == '/';
				string[] parts = e.pathname().split ("/");
				string name = parts[parts.length - (isdir ? 2 : 1)];
				Entry entry = null;
				if (isdir)
					entry = new Directory (name);
				else {
					var fe = new FileEntry (name);
					uint8[] data = new uint8[(int)e.size()];
					arch.read_data (data);
					fe.iostream.output_stream.write (data);
					fe.seek (0, SeekType.SET);
					entry = fe;
				}
				entry.group_id = e.gid();
				entry.user_id = e.uid();
				entry.access_time = new DateTime.from_unix_local ((int64)e.atime());
				entry.creation_time = new DateTime.from_unix_local ((int64)e.ctime());
				entry.modification_time = new DateTime.from_unix_local ((int64)e.mtime());
				map[e.pathname()] = entry;
				tmp.add (e.pathname());
			}
			if (res != LibArchive.Result.EOF)
				throw error_from_libarchive (res, arch.error_string());
			tmp.sort();
			int index = 0;
			while (index < tmp.size) {
				string path = tmp[index];
				var entry = map[path];
				index++;
				if (entry is Directory)
					(entry as Directory).update_children (tmp, map, path, ref index);
				archive.entries.add (entry);
			}
			return archive;
		}
		
		public static Gcl.Archive open_file (GLib.File file) throws GLib.Error {
			return open_stream (file.read());
		}
		
		public static Gcl.Archive open_path (string filename) throws GLib.Error {
			return open_file (File.new_for_path (filename));
		}
	}
}
