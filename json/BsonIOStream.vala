namespace GJson.Bson {
	public class IOStream : Stream {
		GLib.IOStream iostream;
		GLib.Seekable seekable;
		
		public IOStream (GLib.IOStream iostream) throws GLib.Error
		{
			this.iostream = iostream;
			if (iostream is Seekable)
				seekable = iostream as Seekable;
			else if (iostream.input_stream is Seekable)
				seekable = iostream.input_stream as Seekable;
			else if (iostream.output_stream is Seekable)
				seekable = iostream.output_stream as Seekable;
			else 
				throw new IOError.FAILED ("stream not seekable.");
			if (!seekable.can_seek())
				throw new IOError.FAILED ("stream not seekable.");
		}
		
		public override int read (uint8[] data) throws GLib.Error {
			return (int)iostream.input_stream.read (data);
		}
		
		public override int write (uint8[] data) throws GLib.Error {
			return (int)iostream.output_stream.write (data);
		}
		
		public override int64 position {
			get {
				return seekable.tell();
			}
			set {
				try {
					seekable.seek (value, SeekType.SET);
				}
				catch {}
			}
		}
		
		public override int64 size {
			get {
				try {
					int64 pos = seekable.tell();
					seekable.seek (0, SeekType.END);
					int64 s = seekable.tell();
					seekable.seek (pos, SeekType.SET);
					return s;
				}
				catch {
					return -1;
				}
			}
		}
	}
}
