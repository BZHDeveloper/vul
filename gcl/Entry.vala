namespace Gcl {
	public abstract class Entry : GLib.Object, Gee.Hashable<Gcl.Entry> {
		public virtual bool equal_to (Gcl.Entry entry) {
			return str_equal (path, entry.path);
		}
		
		public virtual uint hash() {
			return str_hash (path);
		}
		
		public virtual void seek (int64 offset, GLib.SeekType seek_type, Cancellable? cancel = null) throws GLib.Error {
			if (iostream == null)
				return;
			if (iostream is Seekable)
				(iostream as Seekable).seek (offset, seek_type, cancel);
			else if (iostream.input_stream is Seekable)
				(iostream.input_stream as Seekable).seek (offset, seek_type, cancel);
			else if (iostream.output_stream is Seekable)
				(iostream.output_stream as Seekable).seek (offset, seek_type, cancel);
		}
		
		public virtual int64 tell() {
			if (iostream == null)
				return -1;
			if (iostream is Seekable)
				return (iostream as Seekable).tell();
			if (iostream.input_stream is Seekable)
				return (iostream.input_stream as Seekable).tell();
			if (iostream is Seekable)
				return (iostream.input_stream as Seekable).tell();
			return -1;
		}
		
		public DateTime access_time { get; set; }
		public DateTime creation_time { get; set; }
		public DateTime modification_time { get; set; }
		
		public ulong group_id { get; set; }
		public ulong user_id { get; set; }
		
		public string group_name {
			owned get {
				unowned Posix.Group? grp = Posix.getgrgid (group_id);
				if (grp != null)
					return grp.gr_name;
				return "";
			}
			set {
				unowned Posix.Group? grp = Posix.getgrnam (value);
				if (grp != null)
					group_id = grp.gr_gid;
			}
		}
		
		public string user_name {
			owned get {
				unowned Posix.Passwd? pwd = Posix.getpwuid (user_id);
				if (pwd != null)
					return pwd.pw_name;
				return "";
			}
			set {
				unowned Posix.Passwd? pwd = Posix.getpwnam (value);
				if (pwd != null)
					user_id = pwd.pw_uid;
			}
		}
		
		public abstract IOStream iostream { get; }
		
		public abstract int64 size { get; }
		
		public string name { get; set construct; }
		
		internal Entry parent_entry;
		
		public Entry parent {
			get {
				return parent_entry;
			}
		}
		
		public string path {
			owned get {
				if (parent_entry == null)
					return name;
				return parent_entry.path + "/" + name;
			}
		}
	}
	
	public class FileEntry : Entry {
		public FileEntry (string name) {
			GLib.Object (name : name);
		}
		
		File tmp_file;
		FileIOStream tmp_stream;
		
		construct {
			tmp_file = File.new_tmp (null, out tmp_stream);
			access_time = new DateTime.now_local();
			modification_time = new DateTime.now_local();
			creation_time = new DateTime.now_local();
		}
		
		public override int64 size {
			get {
				int64 pos = tmp_stream.tell();
				tmp_stream.seek (0, SeekType.END);
				int64 len = tmp_stream.tell();
				tmp_stream.seek (pos, SeekType.SET);
				return len;
			}
		}
		
		public override IOStream iostream {
			get {
				access_time = new DateTime.now_local();
				return tmp_stream;
			}
		}
		
		public static FileEntry open_stream (GLib.InputStream input_stream) throws GLib.Error {
			var entry = new FileEntry ("");
			entry.iostream.output_stream.splice (input_stream, OutputStreamSpliceFlags.NONE);
			entry.seek (0, SeekType.SET);
			entry.modification_time = new DateTime.now_local();
			return entry;
		}
		
		public static FileEntry open (GLib.File file) throws GLib.Error {
			var info = file.query_info ("standard::*", FileQueryInfoFlags.NONE);
			if (info.get_file_type() == FileType.DIRECTORY)
				throw new IOError.FAILED ("invalid file");
			// file info
			var entry = open_stream (file.read());
			entry.name = file.get_basename();
			entry.modification_time = new DateTime.from_timeval_local (info.get_modification_time());
			return entry;
		}
		
		public static FileEntry open_path (string filename) throws GLib.Error {
			return open (File.new_for_path (filename));
		}
	}
	
	public class Directory : Entry {
		public Directory (string name) {
			GLib.Object (name : name);
		}
		
		Entries list;
		IOStream dummy;
		
		construct {
			list = new Entries();
			list.added.connect (entry => {
				entry.parent_entry = this;
			});
			list.changed.connect ((entry, index) => {
				entry.parent_entry = this;
			});
			list.inserted.connect ((entry, index) => {
				entry.parent_entry = this;
			});
		}
		
		public override int64 size {
			get {
				return 0;
			}
		}
		
		public override IOStream iostream {
			get {
				return dummy;
			}
		}
		
		public override bool equal_to (Gcl.Entry entry) {
			if (!(entry is Directory))
				return false;
			var dir = entry as Directory;
			if (list.size != dir.children.size)
				return false;
			for (var i = 0; i < list.size; i++)
				if (!list[i].equal_to (dir.children[i]))
					return false;
			return true;
		}
		
		public Gcl.Entry? find (string path_string) {
			string[] parts = path_string.split ("/");
			if (parts.length == 0)
				return null;
			if (parts[parts.length - 1].length == 0)
				parts.resize (parts.length - 1);
			if (parts.length == 0)
				return null;
			for (var i = 0; i < list.size; i++) {
				if (list[i].name == parts[0]) {
					var entry = list[i];
					if (entry is Directory && parts.length > 1)
						return (entry as Directory).find (path_string.substring (1 + path_string.index_of ("/")));
					if (!(entry is Directory) && parts.length > 1)
						return null;
					return entry;
				}
			}
			return null;
		}
		
		public Gee.List<Gcl.Entry> children {
			get {
				return list;
			}
		}
		
		internal void update_children (Gee.List<string> tmp, Gee.Map<string, Entry> map, string path, ref int index) {
			list.clear();
			while (index < tmp.size) {
				var p = tmp[index];
				var e = map[p];
				if (!p.has_prefix (path))
					break;
				index++;
				e.parent_entry = this;
				if (e is Directory)
					(e as Directory).update_children (tmp, map, p, ref index);
				list.add (e);
			}
		}
	}
}
