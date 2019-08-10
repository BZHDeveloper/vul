namespace GText {
	public class StreamReader : Reader {
		public StreamReader (GLib.InputStream input_stream, GText.Encoding encoding = GText.Encoding.utf8) {
			GLib.Object (input_stream : input_stream, encoding : encoding);
		}
		
		public StreamReader.from_file (GLib.File file, GText.Encoding? encoding = null) throws GLib.Error {
			Encoding enc = (encoding == null) ? Encoding.guess_file (file) : encoding;
			InputStream stream = file.read();
			GLib.Object (input_stream : stream, encoding : enc);
		}
		
		public StreamReader.from_path (string filename, GText.Encoding? encoding = null) throws GLib.Error {
			this.from_file (File.new_for_path (filename), encoding);
		}
		
		public StreamReader.from_uri (string uri, GText.Encoding? encoding = null) throws GLib.Error {
			this.from_file (File.new_for_uri (uri), encoding);
		}
		
		Seekable seekable;
		unichar current;
		int64 pos;
		
		construct {
			pos = 0;
			if (input_stream is Seekable)
				seekable = input_stream as Seekable;
			try {
				current = encoding.read_char (input_stream);
			}
			catch {
				current = 0;
			}
		}
		
		public override unichar peek() {
			return current;
		}
		
		public override unichar read() {
			if (current == 0)
				return 0;
			pos = -1;
			if (seekable != null)
				pos = seekable.tell();
			unichar u = current;
			try {
				current = encoding.read_char (input_stream);
			}
			catch {
				current = 0;
			}
			return u;
		}
		
		public override int64 tell() {
			return pos;
		}
		
		public override bool can_seek() {
			if (seekable != null)
				return seekable.can_seek();
			return false;
		}
			
		public override bool can_truncate() {
			if (seekable != null)
				return seekable.can_truncate();
			return false;
		}
		
		public override bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (seekable == null)
				return false;
			bool res = seekable.seek (offset, seek_type, cancellable);
			if (res) {
				pos = seekable.tell();
				try {
					current = encoding.read_char (input_stream);
				}
				catch {
					current = 0;
				}
			}
			return res;
		}
		
		public override bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (seekable == null)
				return false;
			bool res = seekable.truncate (offset, cancellable);
			if (res) {
				pos = seekable.tell();
				current = 0;
			}
			return res;
		}
		
		public GText.Encoding encoding { get; construct; }
		public GLib.InputStream input_stream { get; construct; }
	}
}
