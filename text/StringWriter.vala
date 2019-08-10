namespace GText {
	public class StringWriter : Writer {
		MemoryOutputStream mos;
		
		construct {
			mos = new MemoryOutputStream.resizable();
		}
		
		public override void write (unichar u) throws GLib.Error {
			mos.write (u.to_string().data);
		}
		
		public override bool can_seek() {
			return mos.can_seek();
		}
		
		public override bool can_truncate() {
			return mos.can_truncate();
		}
		
		public override int64 tell() {
			return mos.tell();
		}
		
		public override bool seek (int64 offset, GLib.SeekType seek_type, GLib.Cancellable? cancellable = null) throws GLib.Error {
			return mos.seek (offset, seek_type, cancellable);
		}
		
		public override bool truncate (int64 offset, GLib.Cancellable? cancellable = null) throws GLib.Error {
			return mos.truncate (offset, cancellable);
		}
		
		public string text {
			owned get {
				return (string)mos.get_data();
			}
		}
	}
}
