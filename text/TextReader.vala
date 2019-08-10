namespace GText {
	public class TextReader : Reader {
		Reader reader;
		
		public TextReader (Reader reader) {
			this.reader = reader;
		}
		
		public override unichar peek() {
			return reader.peek();
		}
		
		public override unichar read() {
			unichar current = reader.read();
			if (current == '\n') {
				column = 0;
				line++;
			}
			else
				column++;
			return current;
		}
		
		public override bool can_seek() {
			return reader.can_seek();
		}
		
		public override bool can_truncate() {
			return reader.can_truncate();
		}
		
		public override int64 tell() {
			return reader.tell();
		}
		
		public override bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error {
			return reader.seek (offset, seek_type, cancellable);
		}
		
		public override bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error {
			return reader.truncate (offset, cancellable);
		}
		
		public int column { get; private set; }
		public int line { get; private set; }
	}
}
