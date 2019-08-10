namespace GText {
	public abstract class Writer : GLib.Object, GLib.Seekable {
		public abstract void write (unichar u) throws GLib.Error;
		
		public abstract bool can_seek();
		public abstract bool can_truncate();
		public abstract int64 tell();
		public abstract bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public abstract bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error;
		
		public void write_string (string str) throws GLib.Error {
			int position = 0;
			unichar u = 0;
			while (str.get_next_char (ref position, out u))
				write (u);
		}
		
		public void copy (GText.Reader reader) throws GLib.Error {
			while (!reader.eof)
				write (reader.read());
		}
		
		public async void write_async (unichar u) throws GLib.Error {
			new Thread<bool>("write-async", () => {
				write (u);
				Idle.add (write_async.callback);
				return true;
			});
			yield;
		}
		
		public async void write_string_async (string str) throws GLib.Error {
			new Thread<bool>("write-string-async", () => {
				write_string (str);
				Idle.add (write_string_async.callback);
				return true;
			});
			yield;
		}
		
		public int64 position {
			get {
				return tell();
			}
			set {
				try {
					seek (value, SeekType.SET);
				}
				catch {
				
				}
			}
		}
	}
}
