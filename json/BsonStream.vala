namespace GJson.Bson {
	public abstract class Stream : GLib.Object {
		public abstract int64 position { get; set; }
		public abstract int64 size { get; }
		
		public abstract int read (uint8[] data) throws GLib.Error;
		public abstract int write (uint8[] data) throws GLib.Error;
		
		public void write_byte (uint8 byte) throws GLib.Error {
			write (new uint8[]{ byte });
		}
		
		public void write_cstring (string str) throws GLib.Error {
			write (str.data);
			write_byte (0);
		}
		
		public void write_string (string str) throws GLib.Error {
			write_int32 (str.length + 1);
			write (str.data);
			write_byte (0);
		}
		
		public void write_int32 (int val) throws GLib.Error {
			uint8* pointer = (uint8*)(&val);
			uint8[] data = new uint8[4];
			data[0] = pointer[0];
			data[1] = pointer[1];
			data[2] = pointer[2];
			data[3] = pointer[3];
			write (data);
		}
		
		public void write_int64 (int64 val) throws GLib.Error {
			uint8* pointer = (uint8*)(&val);
			write_byte (pointer[0]);
			write_byte (pointer[1]);
			write_byte (pointer[2]);
			write_byte (pointer[3]);
			write_byte (pointer[4]);
			write_byte (pointer[5]);
			write_byte (pointer[6]);
			write_byte (pointer[7]);
		}
		
		public void write_double (double val) throws GLib.Error {
			uint8* pointer = (uint8*)(&val);
			write_byte (pointer[0]);
			write_byte (pointer[1]);
			write_byte (pointer[2]);
			write_byte (pointer[3]);
			write_byte (pointer[4]);
			write_byte (pointer[5]);
			write_byte (pointer[6]);
			write_byte (pointer[7]);
		}
		
		public Bytes read_bytes (int count) throws GLib.Error {
			var data = new uint8[count];
			int rcount = read (data);
			if (rcount < count)
				data.resize (rcount);
			return new Bytes (data);
		}
		
		public int write_bytes (Bytes bytes) throws GLib.Error {
			return write (bytes.get_data());
		}
	}
}
