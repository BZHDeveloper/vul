namespace GText {
	public class StreamWriter : Writer {
		public StreamWriter (GLib.OutputStream output_stream, GText.Encoding encoding = GText.Encoding.utf8) {
			GLib.Object (output_stream : output_stream, encoding : encoding);
		}
		
		Seekable seekable;
		
		construct {
			if (output_stream is Seekable)
				seekable = output_stream as Seekable;
		}
		
		public override void write (unichar u) throws GLib.Error {
			string str = u.to_string();
			var bytes = encoding.get_bytes (str);
			output_stream.write_bytes (bytes);
		}
		
		public override int64 tell() {
			if (seekable != null)
				return seekable.tell();
			return -1;
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
			return seekable.seek (offset, seek_type, cancellable);
		}
		
		public override bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (seekable == null)
				return false;
			return seekable.truncate (offset, cancellable);
		}
		
		public GText.Encoding encoding { get; construct; }
		public GLib.OutputStream output_stream { get; construct; }
	}
}
