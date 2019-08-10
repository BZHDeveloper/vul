namespace GText {
	
	public class Utf8Encoding : Encoding {
		public override string get_string (uint8[] data) throws GLib.Error {
			return (string)data;
		}
		
		public override uint8[] get_data (string str) throws GLib.Error {
			return str.data;
		}
		
		public override unichar read_char (InputStream stream) throws GLib.Error {
			var byte = new uint8[1];
			string s = "";
			int i = 0;
			unichar u = 0;
			stream.read (byte);
			if (byte[0] < 128)
				return (unichar)byte[0];
			if (byte[0] >= 0xC2 && byte[0] < 0xE0) {
				var byte1 = new uint8[1];
				stream.read (byte1);
				s = (string)new uint8[]{byte[0], byte1[0]};
			}
			else if (byte[0] >= 0xE0 && byte[0] < 0xEF) {
				var byte1 = new uint8[2];
				stream.read (byte1);
				s = (string)new uint8[]{byte[0], byte1[0], byte1[1]};
			}
			else if (byte[0] >= 0xEF) {
				var byte1 = new uint8[2];
				stream.read (byte1);
				if (byte[0] == 239 && byte1[0] == 187 && byte1[1] == 191)
					return read_char (stream);
				var byte2 = new uint8[1];
				stream.read (byte2);
				s = (string)new uint8[]{byte[0], byte1[0], byte1[1], byte2[0]};
			}
			else
				return 0;
			s.get_next_char (ref i, out u);
			return u;
		}
		
		public override string name {
			owned get {
				return "UTF-8";
			}
		}
	}
}
