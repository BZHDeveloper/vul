namespace GJson.Bson {
	internal class WriterContext : GLib.Object {
		public WriterContext (GJson.NodeType node_type, int64 position) {
			GLib.Object (node_type : node_type, position : position);
		}
		
		public int64 position { get; construct; }
		
		public GJson.NodeType node_type { get; construct; }
		
		public string identifier { get; set; }
		
		public int index {
			get {
				return int.parse (identifier);
			}
			set {
				identifier = value.to_string();
			}
		}
	}
	
	public class Writer : GJson.Writer {
		Stream stream;
		Gee.ArrayQueue<WriterContext> stack;
		
		public Writer (GJson.Bson.Stream bson_stream) {
			stream = bson_stream;
			stack = new Gee.ArrayQueue<WriterContext>();
		}
		
		public override void write_start_array() throws GLib.Error {
			if (stack.peek_tail() != null) {
				stream.write_byte (4);
				stream.write_cstring (stack.peek_tail().identifier);
			}
			var context = new WriterContext (NodeType.ARRAY, stream.position);
			context.identifier = "0";
			stack.offer_tail (context);
			stream.write (new uint8[4]);
		}
		
		public override void write_start_object() throws GLib.Error {
			if (stack.peek_tail() != null) {
				stream.write_byte (3);
				stream.write_cstring (stack.peek_tail().identifier);
			}
			var context = new WriterContext (NodeType.OBJECT, stream.position);
			stack.offer_tail (context);
			stream.write (new uint8[4]);
		}
		
		public override void write_end_array() throws GLib.Error {
			stream.write_byte (0);
			var context = stack.poll_tail();
			int64 size = stream.position - context.position;
			int64 pos = stream.position;
			stream.position = context.position;
			stream.write_int32 ((int)size);
			stream.position = pos;
		}
		
		public override void write_end_object() throws GLib.Error {
			stream.write_byte (0);
			var context = stack.poll_tail();
			int64 size = stream.position - context.position;
			int64 pos = stream.position;
			stream.position = context.position;
			stream.write_int32 ((int)size);
			stream.position = pos;
		}
		
		public override void write_delimiter() throws GLib.Error {
			if (stack.peek_tail().node_type == NodeType.ARRAY)
				stack.peek_tail().index++;
		}
		
		public override void write_property_name (string name) throws GLib.Error {
			stack.peek_tail().identifier = name;
		}
		
		public override void write_indent() throws GLib.Error {
			
		}
		
		public override void write_space() throws GLib.Error {
			
		}
		
		public override void write_binary (Bytes bytes) throws GLib.Error {
			stream.write_byte (5);
			stream.write_cstring (stack.peek_tail().identifier);
			stream.write_byte (0);
			stream.write_bytes (bytes);
		}
		
		public override void write_regex (Regex regex) throws GLib.Error {
			var flags = regex.get_compile_flags();
			string options = "";
			
			if ((flags & RegexCompileFlags.CASELESS) != 0)
				options += "i";
			if ((flags & RegexCompileFlags.MULTILINE) != 0)
				options += "m";
			if ((flags & RegexCompileFlags.DOTALL) != 0)
				options += "s";
			if (options.length == 0)
				options += "x";
			
			stream.write_byte (11);
			stream.write_cstring (stack.peek_tail().identifier);
			stream.write_cstring (regex.get_pattern());
			stream.write_cstring (options);
		}
		
		public override void write_datetime (DateTime dt) throws GLib.Error {
			stream.write_byte (9);
			stream.write_cstring (stack.peek_tail().identifier);
			int64 ms = dt.to_unix() * 1000;
			stream.write_int64 (ms);
		}
		
		public override void write_null() throws GLib.Error {
			stream.write_byte (10);
			stream.write_cstring (stack.peek_tail().identifier);
		}
		
		public override void write_integer (int64 val) throws GLib.Error {
			if (val < int.MAX) {
				stream.write_byte (16);
				stream.write_cstring (stack.peek_tail().identifier);
				stream.write_int32 ((int)val);
			}
			else {
				stream.write_byte (18);
				stream.write_cstring (stack.peek_tail().identifier);
				stream.write_int64 (val);
			}
		}
		
		public override void write_string (string val) throws GLib.Error {
			stream.write_byte (2);
			stream.write_cstring (stack.peek_tail().identifier);
			stream.write_string (val);
		}
		
		public override void write_boolean (bool val) throws GLib.Error {
			stream.write_byte (8);
			stream.write_cstring (stack.peek_tail().identifier);
			stream.write_byte (val ? 1 : 0);
		}
		
		public override void write_double (double val) throws GLib.Error {
			stream.write_byte (1);
			stream.write_cstring (stack.peek_tail().identifier);
			stream.write_double (val);
		}
	}
}
