namespace GText {
	public class StringReader : Reader {
		public StringReader (string text) {
			GLib.Object (text : text);
		}
		
		int pos;
		
		public override unichar peek() {
			int p = pos;
			unichar u = 0;
			text.get_next_char (ref p, out u);
			return u;
		}
		
		public override unichar read() {
			unichar u = 0;
			text.get_next_char (ref pos, out u);
			return u;
		}
		
		public override bool can_seek() {
			return true;
		}
		
		public override bool can_truncate() {
			return false;
		}
		
		public override bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error {
			if (cancellable.is_cancelled())
				return false;
			if (seek_type == SeekType.SET)
				pos = (int)offset;
			else if (seek_type == SeekType.CUR) {
				pos += (int)offset;
				if (pos < 0)
					pos = 0;
			}
			else if (seek_type == SeekType.END) {
				pos = (int)(text.length + offset);
				if (pos < 0)
					pos = 0;
			}
			else
				return false;
			return true;
		}
		
		public override int64 tell() {
			return pos;
		}
		
		public override bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error {
			return false;
		}
		
		public string text { get; construct; }
	}
}
