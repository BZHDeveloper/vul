namespace GJson {
	public class VariantReader : GJson.Reader {
		internal class Item : GLib.Object {
			public Item (GJson.TokenType token_type) {
				GLib.Object (token_type : token_type);
			}
			
			public GJson.TokenType token_type { get; construct; }
			public Variant variant { get; set; }
		}
		
		public VariantReader (Variant variant) {
			GLib.Object (variant : variant);
		}
		
		Gee.ArrayList<Item> items;
		int index;
		
		construct {
			decode_unicode = true;
			unescape = true;
			index = 0;
			items = new Gee.ArrayList<Item>();
			if (!parse (variant))
				items.clear();
		}
		
		
		bool parse_binary (Variant v) {
			var item = new Item (GJson.TokenType.BINARY);
			item.variant = v;
			items.add (item);
			return true;
		}
		
		bool parse_null() {
			var item = new Item (GJson.TokenType.NULL);
			items.add (item);
			return true;
		}
		
		bool parse_boolean (Variant v) {
			var item = new Item (GJson.TokenType.BOOLEAN);
			item.variant = v;
			items.add (item);
			return true;
		}
		
		bool parse_double (Variant v) {
			var item = new Item (GJson.TokenType.DOUBLE);
			item.variant = v;
			items.add (item);
			return true;
		}
		
		bool parse_integer (Variant v) {
			var item = new Item (GJson.TokenType.INTEGER);
			item.variant = v;
			items.add (item);
			return true;
		}
		
		bool parse_string (Variant v) {
			var item = new Item (GJson.TokenType.STRING);
			item.variant = v;
			items.add (item);
			return true;
		}
		
		bool parse_object (Variant v) {
			items.add (new Item (GJson.TokenType.START_OBJECT));
			if (v.n_children() > 0) {
				var key = new Item (GJson.TokenType.PROPERTY_NAME);
				key.variant = v.get_child_value (0).get_child_value (0);
				items.add (key);
				items.add (new Item (GJson.TokenType.COLON));
				if (!parse (v.get_child_value (0).get_child_value (1))) {
					items.clear();
					return false;
				}
			}
			for (var i = 1; i < v.n_children(); i++) {
				items.add (new Item (GJson.TokenType.DELIMITER));
				var key = new Item (GJson.TokenType.PROPERTY_NAME);
				key.variant = v.get_child_value (i).get_child_value (0);
				items.add (key);
				items.add (new Item (GJson.TokenType.COLON));
				if (!parse (v.get_child_value (i).get_child_value (1))) {
					items.clear();
					return false;
				}
			}
			items.add (new Item (GJson.TokenType.END_OBJECT));
			return true;
		}
		
		bool parse_array (Variant v) {
			items.add (new Item (GJson.TokenType.START_ARRAY));
			if (v.n_children() > 0) {
				if (!parse (v.get_child_value (0))) {
					items.clear();
					return false;
				}
			}
			for (var i = 1; i < v.n_children(); i++) {
				items.add (new Item (GJson.TokenType.DELIMITER));
				if (!parse (v.get_child_value (i))) {
					items.clear();
					return false;
				}
			}
			items.add (new Item (GJson.TokenType.END_ARRAY));
			return true;
		}
		
		bool parse (Variant v) {
			if (v.get_type_string() == "v")
				return parse (v.get_variant());
			if (v.get_type_string() == "ay")
				return parse_binary (v);
			if (v.get_type_string().has_prefix ("a{s"))
				return parse_object (v);
			if (v.get_type_string().has_prefix ("a"))
				return parse_array (v);
			if (v.get_type_string() == "m")
				return parse_null();
			if (v.get_type_string() == "b")
				return parse_boolean (v);
			if (v.get_type_string() == "n" || v.get_type_string() == "q" || v.get_type_string() == "i" || v.get_type_string() == "u" || 
				v.get_type_string() == "x" || v.get_type_string() == "t" || v.get_type_string() == "h")
				return parse_integer (v);
			if (v.get_type_string() == "d")
				return parse_double (v);
			if (v.get_type_string() == "s" || v.get_type_string() == "o")
				return parse_string (v);
			return false;
		}
		
		public override GJson.TokenType peek_token() {
			if (index >= items.size)
				return GJson.TokenType.EOF;
			return items[index].token_type;
		}
		
		public override GJson.TokenType read_token() {
			if (index >= items.size)
				return GJson.TokenType.EOF;
			var tt = items[index].token_type;
			index++;
			return tt;
		}
		
		string read_str (string s) {
			var reader = new GText.StringReader (s);
			StringBuilder builder = new StringBuilder();
			while (!reader.eof) {
				if (reader.peek() == '\\') {
					reader.read();
					if (reader.peek() == 'u' && decode_unicode) {
						reader.read();
						unichar a = reader.read();
						if (a == 0) {
							builder.append_unichar ('\\');
							builder.append_unichar ('u');
							break;
						}
						unichar b = reader.read();
						if (b == 0) {
							builder.append_unichar (a);
							break;
						}
						unichar c = reader.read();
						if (c == 0) {
							builder.append_unichar (b);
							break;
						}
						unichar d = reader.read();
						if (d == 0) {
							builder.append_unichar (c);
							break;
						}
						string uni = "0x%s%s%s%s".printf (a.to_string(), b.to_string(), c.to_string(), d.to_string());
						int64 i = 0;
						if (!int64.try_parse (s, out i)) {
							builder.append_unichar ('\\');
							builder.append_unichar ('u');
							builder.append_unichar (a);
							builder.append_unichar (b);
							builder.append_unichar (c);
							builder.append_unichar (d);
							continue;
						}
						builder.append_unichar ((unichar)i);
					}
					else {
						builder.append_unichar ('\\');
						builder.append_unichar (reader.read());
					}
				}
				else
					builder.append_unichar (reader.read());
			}
			if (unescape)
				return builder.str.compress();
			return builder.str;
		}
		
		public override void read_start_object() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_start_object : invalid items size");
			if (items[index].token_type != GJson.TokenType.START_OBJECT)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_start_object : invalid token. 'start-object' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			index++;
		}
		
		public override void read_start_array() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_start_array : invalid items size");
			if (items[index].token_type != GJson.TokenType.START_ARRAY)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_start_array : invalid token. 'start-array' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			index++;
		}
		
		public override string read_property_name() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_property_name : invalid items size");
			if (items[index].token_type != GJson.TokenType.PROPERTY_NAME)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_property_name : invalid token. 'property-name' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			string str = read_str (items[index].variant.get_string());
			index++;
			return str;
		}
		
		public override string read_string() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_string : invalid items size");
			if (items[index].token_type != GJson.TokenType.STRING)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_string : invalid token. 'string' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			string str = read_str (items[index].variant.get_string());
			index++;
			return str;
		}
		
		public override void read_null() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_null : invalid items size");
			if (items[index].token_type != GJson.TokenType.NULL)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_null : invalid token. 'null' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			index++;
		}
		
		public override Bytes read_binary() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_binary : invalid items size");
			if (items[index].token_type != GJson.TokenType.BINARY)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_binary : invalid token. 'binary' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			string str = items[index].variant.get_bytestring();
			var data = Base64.decode (str);
			var bytes = new Bytes (data);
			index++;
			return bytes;
		}
		
		public override double read_double() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_double : invalid items size");
			if (items[index].token_type != GJson.TokenType.DOUBLE)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_double : invalid token. 'double' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			double d = items[index].variant.get_double();
			index++;
			return d;
		}
		
		public override bool read_boolean() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_boolean : invalid items size");
			if (items[index].token_type != GJson.TokenType.BOOLEAN)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_boolean : invalid token. 'boolean' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			bool b = items[index].variant.get_boolean();
			index++;
			return b;
		}
		
		public override int64 read_integer() throws GLib.Error {
			if (items.size == 0)
				throw new ReaderError.LENGTH ("GJson.VariantReader.read_integer : invalid items size");
			if (items[index].token_type != GJson.TokenType.INTEGER)
				throw new ReaderError.TOKEN ("GJson.VariantReader.read_integer : invalid token. 'integer' expected but '%s' was found".printf (items[index].token_type.get_nick()));
			string vt = items[index].variant.get_type_string();
			int64 val = 0;
			if (vt == "n")
				val = items[index].variant.get_int16();
			if (vt == "q")
				val = (int64)items[index].variant.get_uint16();
			if (vt == "i")
				val = items[index].variant.get_int32();
			if (vt == "u")
				val = (int64)items[index].variant.get_uint32();
			if (vt == "x")
				val = items[index].variant.get_int64();
			if (vt == "t")
				val = (int64)items[index].variant.get_uint64();
			if (vt == "h")
				val = items[index].variant.get_handle();
			if (vt == "y")
				val = items[index].variant.get_byte();
			index++;
			return val;
		}
		
		public bool decode_unicode { get; set; }
		public bool unescape { get; set; }
		public Variant variant { get; construct; }
	} 
}
