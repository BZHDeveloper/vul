namespace GJson {
	public class VariantWriter : GJson.Writer {
		internal class WriterContext : GLib.Object {
			Gee.ArrayList<Variant> list;
			
			public WriterContext (bool is_array = true) {
				GLib.Object (is_array : is_array);
			}
			
			construct {
				list = new Gee.ArrayList<Variant>();
			}
			
			public Variant property { get; set; }
			
			public bool is_array { get; construct; }
			
			public Gee.List<Variant> variants {
				get {
					return list;
				}
			}
		}
		
		Gee.ArrayQueue<WriterContext> stack;
		
		construct {
			stack = new Gee.ArrayQueue<WriterContext>();
		}

		public void clear() {
			stack.clear();
		}
		
		public override void write_start_array() throws GLib.Error {
			var context = new WriterContext();
			stack.offer_tail (context);
		}
		
		public override void write_start_object() throws GLib.Error {
			var context = new WriterContext (false);
			stack.offer_tail (context);
		}
		
		public override void write_end_array() throws GLib.Error {
			var current = stack.poll_tail();
			result = new Variant.variant (new Variant.array (new VariantType ("v"), current.variants.to_array()));
			if (stack.peek_tail() != null) {
				if (stack.peek_tail().is_array)
					stack.peek_tail().variants.add (result);
				else {
					Variant entry = new Variant.dict_entry (stack.peek_tail().property, result);
					stack.peek_tail().variants.add (entry);
				}
			}
		}
		
		public override void write_end_object() throws GLib.Error {
			var current = stack.poll_tail();
			result = new Variant.variant (new Variant.array (new VariantType ("{sv}"), current.variants.to_array()));
			if (stack.peek_tail() != null) {
				if (stack.peek_tail().is_array)
					stack.peek_tail().variants.add (result);
				else {
					Variant entry = new Variant.dict_entry (stack.peek_tail().property, result);
					stack.peek_tail().variants.add (entry);
				}
			}
		}
		
		static string strescape (string str) {
			StringBuilder builder = new StringBuilder();
			unichar u = 0;
			int position = 0;
			while (str.get_next_char (ref position, out u)) {
				if (u == '\\' || u == '"') {
					builder.append_unichar ('\\');
					builder.append_unichar (u);
				}
				else if ((u > 0 && u < 0x1f) || u == 0x7f) {
					switch (u)
					{
						case '\b':
							builder.append ("\\b");
						break;
						case '\f':
							builder.append ("\\f");
						break;
						case '\n':
							builder.append ("\\n");
						break;
						case '\r':
							builder.append ("\\r");
						break;
						case '\t':
							builder.append ("\\t");
						break;
						default:
							builder.append_printf ("\\u00%02x", u);
						break;
					}
				}
				else
					builder.append_unichar (u);
			}
			return builder.str;
		}
		
		public override void write_string (string str) throws GLib.Error {
			Variant val = new Variant.variant (new Variant.string (str));
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_property_name (string name) throws GLib.Error {
			stack.peek_tail().property = new Variant.string (name);
		}
		
		public override void write_boolean (bool boolean) throws GLib.Error {
			Variant val = new Variant.variant (new Variant.boolean (boolean));
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_double (double d) throws GLib.Error {
			Variant val = new Variant.variant (new Variant.double (d));
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_integer (int64 i) throws GLib.Error {
			Variant val = new Variant.variant (new Variant.int64 (i));
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_null() throws GLib.Error {
			Variant val = new Variant.variant (new Variant.maybe (new VariantType ("s"), null));
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_delimiter() throws GLib.Error {
			
		}
		
		public override void write_binary (Bytes bytes) throws GLib.Error {
			Variant val = new Variant.variant (new Variant.bytestring (Base64.encode (bytes.get_data())));
			
			if (stack.peek_tail() != null) {
				var current = stack.peek_tail();
				if (current.is_array)
					current.variants.add (val);
				else {
					Variant entry = new Variant.dict_entry (current.property, val);
					current.variants.add (entry);
				}
			}
			else
				result = val;
		}
		
		public override void write_indent() throws GLib.Error {}
		public override void write_space() throws GLib.Error {}
		
		public Variant result { get; private set; }
	}
}
