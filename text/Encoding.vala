[CCode (gir_namespace = "GText", gir_version = "1.0")]
namespace GText {}

namespace GText {
	internal class SimpleEncoding : Encoding {
		string ename;
		
		public SimpleEncoding (string name) {
			ename = name;
		}
		
		public override string name {
			owned get {
				return ename;
			}
		}
		
		public override unichar read_char (GLib.InputStream stream) throws GLib.Error {
			var byte = new uint8[1];
			stream.read (byte);
			return (unichar)byte[0];
		}
	}
	
	public abstract class Encoding : GLib.Object {
		public static Encoding utf8 {
			owned get {
				return new Utf8Encoding();
			}
		}
		
		public static Encoding cp1252 {
			owned get {
				return new SimpleEncoding ("CP1252");
			}
		}
		
		public static Encoding latin1 {
			owned get {
				return new SimpleEncoding ("ISO-8859-1");
			}
		}
		
		public static Encoding ascii {
			owned get {
				return new SimpleEncoding ("US-ASCII");
			}
		}
		
		public static Encoding utf16be {
			owned get {
				return new UnicodeEncoding (false);
			}
		}
		
		public static Encoding utf16le {
			owned get {
				return new UnicodeEncoding (false, false);
			}
		}
		
		static string? guess_encoding (string? filename, uint8[]? data = null) {
			if (filename == null && data == null)
				return null;
			if (filename != null) {
				string output;
				string err;
				try {
					Process.spawn_command_line_sync ("file --mime-encoding %s".printf (filename), out output, out err);
				}
				catch {
					return "utf-8";
				}
				return output.split ("\n")[0].split (": ")[1];
			}
			FileIOStream tmp_stream;
			try {
				File tmp_file = File.new_tmp (null, out tmp_stream);
				tmp_stream.output_stream.write (data);
				string output;
				string err;
				Process.spawn_command_line_sync ("file --mime-encoding %s".printf (tmp_file.get_path()), out output, out err);
				tmp_file.delete();
				return output.split ("\n")[0].split (": ")[1];
			} catch {
				
			}
			return "utf-8";
		}
		
		public static Encoding guess (string? filename, uint8[]? data = null) {
			var mime = guess_encoding (filename, data);
			if (mime == null)
				return new Utf8Encoding();
			if (mime == "utf-8")
				return new Utf8Encoding();
			if (mime == "utf-16le")
				return new UnicodeEncoding (true, false);
			if (mime == "utf-16be")
				return new UnicodeEncoding();
			var enc = Encoding.get (mime);
			if (enc != null)
				return enc;
			uint8[] buffer;
			if (data != null)
				buffer = data;
			else
				try {
					FileUtils.get_data (filename, out buffer);
				} catch {
					return new Utf8Encoding();
				}
			if (buffer.length >= 3 && buffer[0] == 239 && buffer[1] == 187 && buffer[2] == 191)
				return new Utf8Encoding();
			if (buffer.length >= 2 && buffer[0] == 255 && buffer[1] == 254) 
				return new UnicodeEncoding (true, false);
			if (buffer.length >= 2 && buffer[0] == 254 && buffer[1] == 255) 
				return new UnicodeEncoding();
			if (buffer.length >= 2 && buffer[0] > 0 && buffer[1] == 0)
				return new UnicodeEncoding (false, false);
			if (buffer.length >= 2 && buffer[0] == 0 && buffer[1] > 0)
				return new UnicodeEncoding (false);
			if (buffer.length >= 4) {
				if (buffer[0] >= 216 && buffer[0] <= 219 && buffer[2] >= 220 && buffer[2] <= 223)
					return new UnicodeEncoding (false);
				if (buffer[1] >= 216 && buffer[1] <= 219 && buffer[3] >= 220 && buffer[3] <= 223)
					return new UnicodeEncoding (false, false);
			}
			return new Utf8Encoding();
		}
		
		public static Encoding guess_file (GLib.File file) throws GLib.Error {
			uint8[] contents;
			file.load_contents (null, out contents, null);
			return guess (null, contents);
		}
		
		public static new Encoding? get (string name) {
			if (name.down() == "utf-16le")
				return new UnicodeEncoding (true, false);
			if (name.down() == "utf-16be")
				return new UnicodeEncoding();
			IConv ic = IConv.open (name, "UTF-8");
			if (ic.close() != 0)
				return null;
			return new SimpleEncoding (name);
		}
		
		internal static uint8[] convert_glib (uint8[] data, string src, string dest) throws GLib.Error {
			size_t br = 0, bw = 0;
			string res = GLib.convert ((string)data, data.length, dest, src, out br, out bw);
			uint8[] buffer = new uint8[(int)br];
			for (var i = 0; i < (int)br; i++)
				buffer[i] = (uint8)res[i];
			return buffer;
		}
		
		public static uint8[] convert_data (uint8[] data, Encoding source, Encoding destination) throws GLib.Error {
			return convert_glib (data, source.name, destination.name);
		}
		
		public static Bytes convert (Bytes bytes, Encoding source, Encoding destination) throws GLib.Error {
			return new Bytes (convert_data (bytes.get_data(), destination, source));
		}
		
		public virtual new uint8[] get_data (string str) throws GLib.Error {
			return convert_glib (str.data, name, "UTF-8");
		}
		
		public virtual string get_string (uint8[] bytes) throws GLib.Error {
			return (string)convert_glib (bytes, "UTF-8", name);
		}
		
		public Bytes get_bytes (string str) throws GLib.Error {
			return new Bytes (get_data (str));
		}
		
		public abstract unichar read_char (GLib.InputStream stream) throws GLib.Error;
		
		public abstract string name { owned get; }
	}
}
