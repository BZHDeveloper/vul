namespace GJson.Bson {
	public class DataStream : Stream {
		GLib.File tmp_file;
		GLib.FileIOStream iostream;
		
		construct {
			try {
				tmp_file = File.new_tmp (null, out iostream);
			}
			catch {}
		}
		
		public override int read (uint8[] data) throws GLib.Error {
			return (int)iostream.input_stream.read (data);
		}
		
		public override int write (uint8[] data) throws GLib.Error {
			return (int)iostream.output_stream.write (data);
		}
		
		public override int64 position {
			get {
				return iostream.tell();
			}
			set {
				try {
					iostream.seek (value, SeekType.SET);
				}
				catch {}
			}
		}
		
		public override int64 size {
			get {
				try {
					int64 pos = iostream.tell();
					iostream.seek (0, SeekType.END);
					int64 s = iostream.tell();
					iostream.seek (pos, SeekType.SET);
					return s;
				}
				catch {
					return -1;
				}
			}
		}
		
		public uint8[] data {
			owned get {
				uint8[] buffer = new uint8[0];
				try {
					FileUtils.get_data (tmp_file.get_path(), out buffer);
				} catch {}
				return buffer;
			}
		}
	}
}
