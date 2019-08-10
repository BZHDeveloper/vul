namespace GText {
	static int[] n_to_bin (uint8 u)
	{
		var i = 128;
		uint8 tmp = u;
		int[] bin = new int[0];
		while (i >= 1)
		{
			bin += tmp / i;
			tmp -= i * (tmp / i);
			if (i == 1)
				break;
			i /= 2;
		}
		return bin;
	}
	
	public class UnicodeEncoding : Encoding {
		public UnicodeEncoding (bool bom = true, bool big_endian = true) {
			GLib.Object (bom: bom, big_endian: big_endian);
		}
		
		public override uint8[] get_data (string str) throws GLib.Error {
			var data = new ByteArray();
			if (bom)
				if (!big_endian)
					data.append ({ 255, 254 });
				else
					data.append ({ 254, 255 });
			data.append (convert_glib (str.data, big_endian ? "UTF-16BE" : "UTF-16LE", "UTF-8"));
			return data.data;
		}
		
		public override string get_string (uint8[] bytes) throws GLib.Error {
			var array = new uint8[bytes.length];
			for (var i = 0; i < bytes.length; i++)
				array[i] = bytes[i];
			if (bytes.length > 2 && 
			(big_endian && bytes[0] == 254 && bytes[1] == 255 ||
			!big_endian && bytes[1] == 254 && bytes[0] == 255)) {
				array.move (2, 0, bytes.length - 2);
				array.resize (bytes.length - 2);
			}
			return (string)convert_glib (array, "UTF-8", big_endian ? "UTF-16BE" : "UTF-16LE");
		}
		
		public override unichar read_char (InputStream stream) throws GLib.Error {
			var buffer = new uint8[2];
			stream.read (buffer);
			if (buffer[0] == 254 && buffer[1] == 255 && big_endian ||
				buffer[1] == 254 && buffer[0] == 255 && !big_endian)
				stream.read (buffer);
			if (big_endian) {
				var bin = n_to_bin (buffer[0]);
				if (bin[0] == 1 && bin[1] == 1 && bin[2] == 0 && bin[3] == 1 && bin[4] == 1 && bin[5] == 0) {
					var buffer2 = new uint8[2];
					stream.read (buffer2);
					return get_string (new uint8[]{buffer[0], buffer[1], buffer2[0], buffer2[1]}).get_char();
				} else return get_string (buffer).get_char(); 
			} else {
				var bin = n_to_bin (buffer[1]);
				if (bin[0] == 1 && bin[1] == 1 && bin[2] == 0 && bin[3] == 1 && bin[4] == 1 && bin[5] == 0) {
					var buffer2 = new uint8[2];
					stream.read (buffer2);
					return get_string (new uint8[]{buffer[0], buffer[1], buffer2[0], buffer2[1]}).get_char();
				} else return get_string (buffer).get_char(); 
			}
		}
		
		public bool bom { get; construct; }
		public bool big_endian { get; construct; }
		
		public override string name {
			owned get {
				return "UTF-16" + (big_endian ? "BE" : "LE");
			}
		}
	}
}
