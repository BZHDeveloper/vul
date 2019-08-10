namespace GJson {
	internal static GJson.Node value_to_node (GLib.Value? val) {
		if (val != null && val.type() == typeof (Variant)) {
			Variant variant = (Variant)val;
			try {
				var reader = new VariantReader (variant);
				var node = GJson.Node.load (reader);
				return node;
			}
			catch {}
		}
		
		if (val != null && val.type().is_a (typeof (Node))) {
			var node = (Node)val;
			return node;
		}
		
		if (val != null && val.type().is_a (typeof (Property))) {
			var prop = (Property)val;
			return prop.node;
		}
		return new Node (val);
	}
	
	public enum NodeType {
		NULL,
		ARRAY,
		OBJECT,
		BOOLEAN,
		STRING,
		DOUBLE,
		INTEGER,
		REGEX,
		DATETIME,
		BINARY
	}
	
	public class Node : GJson.Item {
		public static GJson.Node load (GJson.Reader reader) throws GLib.Error {
			var node = reader.read_node();
			if (reader.peek_token() != GJson.TokenType.EOF)
				throw new ReaderError.INVALID ("GJson.Node.parse : extra content at end of node. '%s' token.".printf (reader.peek_token().get_nick()));
			return node;
		}
		
		public static async GJson.Node load_async (GJson.Reader reader) throws GLib.Error {
			GJson.Node node = null;
			ThreadFunc<void*> func = () => {
				node = load (reader);
				Idle.add (load_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return node;
		}
		
		public static GJson.Node parse (string data) {
			string json = data.strip();
			var reader = new GJson.TextReader.from_string (json);
			try {
				return load (reader);
			}
			catch {}
			return new GJson.Node (null);
		}
		
		public static async GJson.Node parse_async (string data) throws GLib.Error {
			GJson.Node node = null;
			ThreadFunc<void*> func = () => {
				node = parse (data);
				Idle.add (parse_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return node;
		}
		
		GJson.Array array;
		GJson.Object object;
		string str;
		string number_str;
		bool boolean;
		int64 integer;
		Bytes binary;
		Regex regex;
		DateTime datetime;
		
		internal string property_name;
		internal Container container;
		
		Regex reg;
		
		public Node (GLib.Value? val = null) {
			if (val != null)
				this.value = val;
				
			try {
				reg = new Regex("");
			}
			catch {
				// unreachable code.
			}
		}
		
		internal Node.from (Type vtype, void* data) {
			try {
				reg = new Regex("");
			}
			catch {
				// unreachable code.
			}
			if (data == null)
				this.node_type = GJson.NodeType.NULL;
			else if (vtype == typeof (bool)) {
				this.boolean = (bool)data;
				this.node_type = GJson.NodeType.BOOLEAN;
			}
			else if (vtype == typeof (string)) {
				this.str = (string)data;
				this.node_type = GJson.NodeType.STRING;
			}
			else if (vtype == typeof (int))
				this.value = (int)data;
			else if (vtype == typeof (uint))
				this.value = (uint)data;
			else if (vtype == typeof (int8))
				this.value = (int8)data;
			else if (vtype == typeof (uint8))
				this.value = (uint8)data;
			else if (vtype == typeof (int))
				this.value = (int)data;
			else if (vtype == typeof (uint))
				this.value = (uint)data;
			else if (vtype == typeof (long))
				this.value = (long)data;
			else if (vtype == typeof (long))
				this.value = (long)data;
			else if (vtype == typeof (int64)) {
				int64? ptr = (int64?)data;
				this.value = int64.parse (("%" + int64.FORMAT).printf (ptr));
			}
			else if (vtype == typeof (uint64)) {
				uint64? ptr = (uint64?)data;
				this.value = uint64.parse (("%" + uint64.FORMAT).printf (ptr));
			}
			else if (vtype == typeof (double)) {
				double? ptr = (double?)data;
				double d = double.parse ("%g".printf (ptr));
				this.value = d;
			}
			else if (vtype == typeof (float)) {
				float? ptr = (float?)data;
				double d = double.parse ("%g".printf (ptr));
				this.value = d;
			}
			else if (vtype.is_a (typeof (GJson.Node))) {
				var node = (GJson.Node)data;
				if (node.node_type == NodeType.NULL)
					node_type = NodeType.NULL;
				else
					this.value = node.value;
			}
			else if (vtype.is_a (typeof (GJson.Array)))
				this.value = (GJson.Array)data;
			else if (vtype.is_a (typeof (GJson.Object)))
				this.value = (GJson.Object)data;
			else if (vtype == typeof (Regex))
				this.value = (Regex)data;
			else if (vtype == typeof (DateTime))
				this.value = (DateTime)data;
			else if (vtype == typeof (Date)) {
				Date* ptr = (Date*)data;
				this.value = *ptr;
			}
			else if (vtype == typeof (Time)) {
				Time* ptr = (Time*)data;
				this.value = *ptr;
			}
			else if (vtype == typeof (Bytes))
				this.value = (Bytes)data;
			else if (vtype == typeof (ByteArray))
				this.value = (ByteArray)data;
			else if (vtype == typeof (Value)) {
				Value? ptr = (Value?)data;
				this.value = value_to_node (ptr);
			}
		}
		
		static int real_length (string str) {
			int count = 0;
			int pos = 0;
			unichar u;
			while (str.get_next_char (ref pos, out u))
				count++;
			return count;
		}
		
		void validate_string (JsonSchema.Schema schema) throws GLib.Error {
			if (!(schema is JsonSchema.SchemaString))
				throw new JsonSchema.SchemaError.INVALID ("current schema isn't string.");
			var sc = schema as JsonSchema.SchemaString;
			if (sc.pattern != null && !sc.pattern.match (str))
				throw new JsonSchema.SchemaError.INVALID ("current string doesn't match regular expression.");
			int str_length = real_length (str);
			if (str_length > sc.max_length)
				throw new JsonSchema.SchemaError.INVALID ("current string length is larger than allowed");
			if (str_length < sc.min_length)
				throw new JsonSchema.SchemaError.INVALID ("current string length is smaller than allowed");
		}
		
		void validate_integer (JsonSchema.Schema schema) throws GLib.Error {
			if (!(schema is JsonSchema.SchemaInteger))
				throw new JsonSchema.SchemaError.INVALID ("current schema isn't integer.");
			var sc = schema as JsonSchema.SchemaInteger;
			if (integer % sc.multiple_of != 0)
				throw new JsonSchema.SchemaError.INVALID ("current number isn't a multiple of requested number.");
			if (integer > sc.maximum && sc.exclusive_maximum || integer >= sc.maximum && !sc.exclusive_maximum)
				throw new JsonSchema.SchemaError.INVALID ("current number is outside range.");
			if (integer > sc.minimum && sc.exclusive_minimum || integer >= sc.minimum && !sc.exclusive_minimum)
				throw new JsonSchema.SchemaError.INVALID ("current number is outside range.");
		}
		
		void validate_number (JsonSchema.Schema schema) throws GLib.Error {
			if (!(schema is JsonSchema.SchemaNumber))
				throw new JsonSchema.SchemaError.INVALID ("current schema isn't number.");
			var sc = schema as JsonSchema.SchemaNumber;
			if (as_double() % sc.multiple_of != 0)
				throw new JsonSchema.SchemaError.INVALID ("current number isn't a multiple of requested number.");
			if (as_double() > sc.maximum && sc.exclusive_maximum || as_double() >= sc.maximum && !sc.exclusive_maximum)
				throw new JsonSchema.SchemaError.INVALID ("current number is outside range.");
			if (as_double() > sc.minimum && sc.exclusive_minimum || as_double() >= sc.minimum && !sc.exclusive_minimum)
				throw new JsonSchema.SchemaError.INVALID ("current number is outside range.");
		}
		
		[Version (experimental = true)]
		public void validate (JsonSchema.Schema schema) throws GLib.Error {
			if (array != null)
				array.validate (schema);
			if (object != null)
				object.validate (schema);
			if (node_type == NodeType.INTEGER)
				validate_integer (schema);
			if (node_type == NodeType.DOUBLE)
				validate_number (schema);
			if (node_type == NodeType.STRING)
				validate_string (schema);
		}
		
		public bool foreach (Gee.ForallFunc<GJson.Node> func) {
			if (node_type == NodeType.ARRAY)
				return as_array().foreach (node => {
					return func (node);
				});
			if (node_type == NodeType.OBJECT)
				return as_object().foreach (prop => {
					return func (prop.node);
				});
			return false;
		}
		
		public override GJson.Node get (GLib.Value index) {
			Value i = -1;
			index.transform (ref i);
			int idx = (int)i;
			if (node_type == NodeType.OBJECT) {
				if (index.type() == typeof (string)) {
					string key = (string)index;
					return object[key];
				}
				if (idx >= 0 && idx < object.size)
					return object.to_array()[idx].node;
			}
			if (node_type == NodeType.ARRAY) {
				var array = as_array();
				if (idx >= 0 && idx < array.size)
					return array[idx];
			}
			return new Node();
		}
		
		public void set (GLib.Value index, GLib.Value? val) {
			Value i = -1;
			index.transform (ref i);
			int idx = (int)i;
			if (node_type == NodeType.OBJECT) {
				if (index.type() == typeof (string)) {
					string key = (string)index;
					object[key] = val;
				}
				if (idx >= 0 && idx < object.size) {
					string key = object.properties.to_array()[idx].name;
					object[key] = val;
				}
			}
			else if (node_type == NodeType.ARRAY)
				if (idx >= 0 && idx < array.size)
					array[idx] = val;
		}
		
		public GJson.Array as_array() {
			if (node_type == GJson.NodeType.ARRAY)
				return array;
			return new GJson.Array();
		}
		
		public GJson.Object as_object() {
			if (node_type == GJson.NodeType.OBJECT)
				return object;
			return new GJson.Object();
		}
		
		public string as_string() {
			if (node_type == GJson.NodeType.STRING)
				return str;
			if (node_type == GJson.NodeType.REGEX)
				return regex.get_pattern();
			return "";
		}
		
		public bool as_boolean() {
			if (node_type == GJson.NodeType.BOOLEAN)
				return boolean;
			if (node_type == GJson.NodeType.INTEGER)
				return integer == 1;
			if (node_type == GJson.NodeType.DOUBLE)
				return str_equal (number_str, "1");
			return false;
		}
		
		public int64 as_integer() {
			if (node_type == GJson.NodeType.DOUBLE) {
				int64 i = 0;
				if (int64.try_parse (number_str, out i))
					return i;
			}
			if (node_type == GJson.NodeType.BOOLEAN)
				return (boolean ? 1 : 0);
			return integer;
		}
		
		public double as_double() {
			if (node_type == GJson.NodeType.INTEGER) {
				string s = integer.to_string();
				double d = 0;
				if (double.try_parse (s, out d))
					return d;
			}
			if (node_type == GJson.NodeType.BOOLEAN)
				return (boolean ? 1 : 0);
			if (node_type == GJson.NodeType.DOUBLE)
				return double.parse (number_str);
			return 0;
		}
		
		public Regex as_regex() {
			if (node_type == GJson.NodeType.REGEX)	
				return regex;
			if (node_type == GJson.NodeType.STRING) {
				try {
					return new Regex (str);
				}
				catch {
					
				}
			}
			return reg;
		}
		
		public Bytes as_binary() {
			if (node_type == GJson.NodeType.BINARY)
				return binary;
			if (node_type == GJson.NodeType.STRING)
				return new Bytes (Base64.decode (str));
			return new Bytes (new uint8[0]);
		}
		
		public DateTime as_datetime() {
			if (node_type == GJson.NodeType.DATETIME)
				return datetime;
			if (node_type == GJson.NodeType.STRING) {
				var dt = new DateTime.from_iso8601 (str, new TimeZone.local());
				if (dt != null)
					return dt;
			}
			return new DateTime.now_local();
		}
		
		static string escape (string str) {
			StringBuilder builder = new StringBuilder ("\"");
			unichar u = 0;
			int index = 0;
			while (str.get_next_char (ref index, out u)) {
				if (u == '"') {
					builder.append_unichar ('\\');
				}
				builder.append_unichar (u);
			}
			builder.append_unichar ('"');
			return builder.str;
		}
		
		public override string to_string() {
			/*
			if (node_type == NodeType.ARRAY)
				return as_array().to_string();
			if (node_type == NodeType.OBJECT)
				return as_object().to_string();
			if (node_type == NodeType.STRING)
				return "\"" + strescape (str) + "\"";
			return value.strdup_contents();
			*/
			var twriter = new GText.StringWriter();
			try {
				var writer = new TextWriter (twriter);
				writer.write_node (this);
			} catch {}
			return twriter.text;
		}
		
		public bool equal (GLib.Value? val) {
			return equal_to (value_to_node (val));
		}
		
		public override bool equal_to (GJson.Item item) {
			if (!(item is GJson.Node))
				return false;
			var node = item as GJson.Node;
			if (node_type != node.node_type)
				return false;
			if (node_type == NodeType.OBJECT)
				return as_object().equal_to (node.as_object());
			if (node_type == NodeType.ARRAY)
				return as_array().equal_to (node.as_array());
			return str_equal (to_string(), node.to_string());
		}
		
		public GJson.NodeType node_type { get; private set; }
		
		public GJson.Container parent {
			get {
				return container;
			}
		}
		
		public GLib.Value value {
			owned get {
				if (node_type == NodeType.OBJECT)
					return object;
				if (node_type == NodeType.ARRAY)
					return array;
				if (node_type == NodeType.STRING)
					return str;
				if (node_type == NodeType.BOOLEAN)
					return boolean;
				if (node_type == NodeType.INTEGER)
					return integer;
				if (node_type == NodeType.DOUBLE)
					return double.parse (number_str);
				if (node_type == NodeType.REGEX)
					return regex;
				if (node_type == NodeType.DATETIME)
					return datetime;
				if (node_type == NodeType.BINARY)
					return binary;
				return 0;
			}
			set {
				if (value.type().is_a (typeof (GJson.Node))) {
					var node = (GJson.Node)value;
					this.value = node.value;
				}
				else if (value.type().is_a (typeof (GJson.Object))) {
					node_type = GJson.NodeType.OBJECT;
					object = (GJson.Object)value;
				}
				else if (value.type().is_a (typeof (GJson.Array))) {
					node_type = GJson.NodeType.ARRAY;
					array = (GJson.Array)value;
				}
				else if (value.type() == typeof (string[])) {
					node_type = GJson.NodeType.ARRAY;
					array = new GJson.Array();
					string[] strv = (string[])value;
					foreach (string str in strv)
						array.add (str);
				}
				else if (value.type().is_a (typeof (Gee.Map))) {
					var map = (Gee.Map<void*,void*>)value;
					object = serialize_map (map);
					node_type = GJson.NodeType.OBJECT;
				}
				else if (value.type().is_a (typeof (Gee.Traversable))) {
					var ptr = (Gee.Traversable<void*>)value;
					array = serialize_traversable_internal (ptr);
					node_type = GJson.NodeType.ARRAY;
				}
				else if (value.type() == typeof (bool)) {
					node_type = GJson.NodeType.BOOLEAN;
					boolean = (bool)value;
				}
				else if (value.type() == typeof (string)) {
					str = (string)value;
					if (str == null)
						node_type = GJson.NodeType.NULL;
					else
						node_type = GJson.NodeType.STRING;
				}
				else if (value.type() == typeof (int)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int)value;
				}
				else if (value.type() == typeof (uint)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int64)(uint)value;
				}
				else if (value.type() == typeof (int64)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int64)value;
				}
				else if (value.type() == typeof (uint64)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int64)(uint64)value;
				}
				else if (value.type() == typeof (int8)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int8)value;
				}
				else if (value.type() == typeof (uint8)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int64)(uint8)value;
				}
				else if (value.type() == typeof (long)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (long)value;
				}
				else if (value.type() == typeof (ulong)) {
					node_type = GJson.NodeType.INTEGER;
					integer = (int64)(ulong)value;
				}
				else if (value.type() == typeof (double)) {
					node_type = GJson.NodeType.DOUBLE;
					number_str = "%g".printf ((double)value);
				}
				else if (value.type() == typeof (float)) {
					node_type = GJson.NodeType.DOUBLE;
					number_str = "%g".printf ((float)value);
				}
				else if (value.type() == typeof (Regex)) {
					node_type = GJson.NodeType.REGEX;
					regex = (Regex)value;
				}
				else if (value.type() == typeof (Bytes)) {
					node_type = GJson.NodeType.BINARY;
					binary = (Bytes)value;
				}
				else if (value.type() == typeof (ByteArray)) {
					node_type = GJson.NodeType.BINARY;
					var bytes = (ByteArray)value;
					binary = new Bytes (bytes.data);
				}
				else if (value.type() == typeof (DateTime)) {
					node_type = GJson.NodeType.DATETIME;
					datetime = (DateTime)value;
				}
				else if (value.type() == typeof (Date)) {
					node_type = GJson.NodeType.DATETIME;
					Date date = (Date)value;
					Time t;
					date.to_time (out t);
					datetime = new DateTime.from_unix_local ((int64)t.mktime());
				}
				else if (value.type() == typeof (Time)) {
					node_type = GJson.NodeType.DATETIME;
					Time t = (Time)value;
					datetime = new DateTime.from_unix_local ((int64)t.mktime());
				}
			}
		}
	}
}
