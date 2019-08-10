namespace GText {
	public abstract class Reader : GLib.Object, GLib.Seekable {
		public abstract unichar peek();
		public abstract unichar read();
		
		public abstract bool can_seek();
		public abstract bool can_truncate();
		public abstract int64 tell();
		public abstract bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public abstract bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error;
		
		public string? read_line() {
			StringBuilder builder = null;
			while (!eof) {
				if (builder == null)
					builder = new StringBuilder();
				if (peek() == '\n')
					break;
				builder.append_unichar (read());
			}
			if (builder == null)
				return null;
			return builder.str;
		}
		
		public string? read_to_end() {
			StringBuilder builder = null;
			while (!eof) {
				if (builder == null)
					builder = new StringBuilder();
				builder.append_unichar (read());
			}
			if (builder == null)
				return null;
			return builder.str;
		}
		
		public async unichar read_async() {
			unichar[] result = new unichar[1];
			new Thread<bool>("read-async", () => {
				result[0] = read();
				Idle.add (read_async.callback);
				return true;
			});
			yield;
			return result[0];
		}
		
		public async string? read_line_async() {
			string? result = null;
			new Thread<bool>("read-line-async", () => {
				result = read_line();
				Idle.add (read_line_async.callback);
				return true;
			});
			yield;
			return result;
		}
		
		public async string? read_to_end_async() {
			string? result = null;
			new Thread<bool>("read-to-end-async", () => {
				result = read_line();
				Idle.add (read_to_end_async.callback);
				return true;
			});
			yield;
			return result;
		}
		
		public virtual bool eof {
			get {
				return peek() == 0;
			}
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
