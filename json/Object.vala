namespace GJson {
	public class Property : GJson.Item {
		public Property.with_node (string name, GJson.Node val) {
			GLib.Object (name : name, node : val);
		}
		
		public Property (string name, GLib.Value? val = null) {
			this.with_node (name, value_to_node (val));
		}
		
		construct {
			node.property_name = name;
		}
		
		public void write_to (GJson.Writer writer, int depth = 0) throws GLib.Error {
			writer.write_property (this, depth);
		}
		
		public override string to_string() {
			var twriter = new GText.StringWriter();
			try {
				var writer = new TextWriter (twriter);
				write_to (writer);
			} catch {}
			return twriter.text;
		}
		
		public bool foreach (Gee.ForallFunc<GJson.Node> func) {
			return node.foreach (func);
		}
		
		public override GJson.Node get (GLib.Value index) {
			return node.get (index);
		}
		
		public override bool equal_to (GJson.Item item) {
			if (!(item is GJson.Property))
				return false;
			var prop = item as GJson.Property;
			return str_equal (name, prop.name) && node.equal_to (prop.node);
		}
		
		internal Container container;
		
		public GJson.Container parent {
			get {
				return container;
			}
		}
		
		public GLib.Value value {
			owned get {
				return node.value;
			}
			set {
				node.value = value;
			}
		}
		
		public string name { get; construct; }
		public GJson.Node node { get; construct; }
	}
	
	public class Object : GJson.Container<GJson.Property> {
		public static GJson.Object load (GJson.Reader reader) throws GLib.Error {
			var array = reader.read_object();
			if (reader.peek_token() != TokenType.EOF)
				throw new ReaderError.INVALID ("GJson.Object.parse : extra content at end of object. '%s' token.".printf (reader.peek_token().get_nick()));
			return array;
		}
		
		public static async GJson.Object load_async (GJson.Reader reader) throws GLib.Error {
			GJson.Object object = null;
			ThreadFunc<void*> func = () => {
				object = load (reader);
				Idle.add (load_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return object;
		}
		
		public static GJson.Object parse (string data) throws GLib.Error {
			var reader = new GText.StringReader (data);
			var jreader = new TextReader (reader);
			return load (jreader);
		}
		
		public static async GJson.Object parse_async (string data) throws GLib.Error {
			GJson.Object object = null;
			ThreadFunc<void*> func = () => {
				object = parse (data);
				Idle.add (parse_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return object;
		}
		
		Gee.ArrayList<Property> props;
		
		construct {
			props = new Gee.ArrayList<Property>();
		}
		
		[Version (experimental = true)]
		public void validate (JsonSchema.Schema schema) throws GLib.Error {
			if (!(schema is JsonSchema.SchemaObject))
				throw new JsonSchema.SchemaError.INVALID ("current schema isn't object.");
			var sc = schema as JsonSchema.SchemaObject;
			if (size > sc.max_properties)
				throw new JsonSchema.SchemaError.INVALID ("current object is too big.");
			if (size < sc.min_properties)
				throw new JsonSchema.SchemaError.INVALID ("current object is too small.");
			foreach (var key in sc.required)
				if (!has_key (key))
					throw new JsonSchema.SchemaError.INVALID ("current object doesn't have required key.");
			bool ap = false;
			JsonSchema.Schema sap = null;
			if (sc.additional_properties.type() == typeof (bool))
				ap = (bool)sc.additional_properties;
			if (sc.additional_properties.type().is_a (typeof (JsonSchema.Schema)))
				sap = (JsonSchema.Schema)sc.additional_properties;
			if (sc.properties != null)
				foreach (var key in sc.properties.keys)
					if (has_key (key))
						this[key].validate (sc.properties[key]);
					else if (sap != null || ap == true) {
						
					}
			if (sc.pattern_properties != null)
				foreach (var rg in sc.pattern_properties.keys) {
					var regex = new Regex (rg);
					foreach (string key in keys)
						if (regex.match (key))
							this[key].validate (sc.pattern_properties[rg]);
				}
		}
		
		public void set_map (Gee.Map map) {
			if (map.key_type != typeof (string))
				return;
			props.clear();
			map.foreach (entry => {
				Node node = null;
				if (map.value_type == typeof (GLib.Value)) {
					GLib.Value? val = (GLib.Value?)entry.value;
					node = value_to_node (val);
				}
				else
					node = new Node.from (map.value_type, entry.value);
				props.add (new Property.with_node ((string)entry.key, node));
				return true;
			});
		}
		
		public GJson.Array select (string expression) throws GLib.Error {
			return Path.query (expression, new Node (this));
		}
		
		public override GJson.Node get (GLib.Value index) {
			if (index.type() == typeof (string))
				return get_member ((string)index);
			Value i = -1;
			index.transform (ref i);
			int idx = (int)i;
			if (idx < 0 || idx >= props.size)
				return new Node();
			return props[idx].node;
		}
		
		public GJson.Node get_member (string key) {
			for (var i = 0; i < props.size; i++)
				if (props[i].name == key)
					return props[i].node;
			return new Node();
		}
		
		public bool get_null_member (string key) {
			return get_member (key).node_type == NodeType.NULL;
		}
		
		public GJson.Array get_array_member (string key) {
			return get_member (key).as_array();
		}
		
		public GJson.Object get_object_member (string key) {
			return get_member (key).as_object();
		}
		
		public bool get_boolean_member (string key) {
			return get_member (key).as_boolean();
		}
		
		public string get_string_member (string key) {
			return get_member (key).as_string();
		}
		
		public double get_double_member (string key) {
			return get_member (key).as_double();
		}
		
		public int64 get_integer_member (string key) {
			return get_member (key).as_integer();
		}
		
		public DateTime get_datetime_member (string key) {
			return get_member (key).as_datetime();
		}
		
		public Regex get_regex_member (string key) {
			return get_member (key).as_regex();
		}
		
		public Bytes get_binary_member (string key) {
			return get_member (key).as_binary();
		}
		
		public bool has (string key, GLib.Value? val) {
			var node = value_to_node (val);
			var prop = new Property.with_node (key, node);
			return contains (prop);
		}
		
		public bool has_key (string key) {
			var props = to_array();
			for (var i = 0; i < props.length; i++)
				if (props[i].name == key)
					return true;
			return false;
		}
		
		public bool unset (string key, out GJson.Node node = null) {
			node = new Node();
			var props = to_array();
			for (var i = 0; i < props.length; i++)
				if (props[i].name == key) {
					node = props[i].node;
					return remove (props[i]);
				}
			return false;
		}
		
		public new void set (string key, GLib.Value? val) {
			var node = value_to_node (val);
			var prop = new Property.with_node (key, node);
			add (prop);
			node.container = this;
			if (node.node_type == NodeType.ARRAY) {
				node.as_array().container = this;
				node.as_array().property_name = key;
			}
			if (node.node_type == NodeType.OBJECT) {
				node.as_object().container = this;
				node.as_object().property_name = key;
			}
		}
		
		public void set_member (string key, GJson.Node node) {
			var prop = new Property.with_node (key, node);
			add (prop);
			node.container = this;
			if (node.node_type == NodeType.ARRAY) {
				node.as_array().container = this;
				node.as_array().property_name = key;
			}
			if (node.node_type == NodeType.OBJECT) {
				node.as_object().container = this;
				node.as_object().property_name = key;
			}
		}
		
		public void set_null_member (string key) {
			set_member (key, new Node());
		}
		
		public void set_array_member (string key, GJson.Array val) {
			set_member (key, new Node (val));
		}
		
		public void set_object_member (string key, GJson.Object val) {
			set_member (key, new Node (val));
		}
		
		public void set_string_member (string key, string val) {
			set_member (key, new Node (val));
		}
		
		public void set_boolean_member (string key, bool val) {
			set_member (key, new Node (val));
		}
		
		public void set_double_member (string key, double val) {
			set_member (key, new Node (val));
		}
		
		public void set_integer_member (string key, int64 val) {
			set_member (key, new Node (val));
		}
		
		public void set_datetime_member (string key, DateTime val) {
			set_member (key, new Node (val));
		}
		
		public void set_regex_member (string key, Regex val) {
			set_member (key, new Node (val));
		}
		
		public void set_binary_member (string key, Bytes val) {
			set_member (key, new Node (val));
		}
		
		public override bool equal_to (GJson.Container container) {
			if (!(container is GJson.Object))
				return false;
			var object = container as GJson.Object;
			if (object.size != size)
				return false;
			var oprops = object.to_array();
			for (var i = 0; i < object.size; i++)
				if (!props[i].equal_to (oprops[i]))
					return false;
			return true;
		}
		
		public void write_to (GJson.Writer writer, int depth = 0) throws GLib.Error {
			writer.write_start_object();
			writer.write_indent();
			for (var i = 0; i < props.size - 1; i++) {
				for (var j = 0; j < depth + 1; j++)
					writer.write_space();
				writer.write_property (props[i], depth + 1);
				writer.write_delimiter();
				writer.write_indent();
			}
			if (props.size > 0) {
				for (var j = 0; j < depth + 1; j++)
					writer.write_space();
				writer.write_property (props[props.size - 1], depth + 1);
				writer.write_indent();
			}
			for (var j = 0; j < depth; j++)
				writer.write_space();
			writer.write_end_object();
		}
		
		public override string to_string() {
			var twriter = new GText.StringWriter();
			try {
				var writer = new TextWriter (twriter);
				write_to (writer);
			} catch {}
			return twriter.text;
		}
		
		public Gee.Set<string> keys {
			owned get {
				var list = new Gee.HashSet<string>();
				for (var i = 0; i < props.size; i++)
					list.add (props[i].name);
				return list;
			}
		}
		
		public Gee.Collection<GJson.Node> values {
			owned get {
				var list = new Gee.ArrayList<Node>();
				for (var i = 0; i < props.size; i++)
					list.add (props[i].node);
				return list;
			}
		}
		
		public override bool add (GJson.Property property) {
			remove (property);
			property.container = this;
			property.node.container = this;
			return props.add (property);
		}
		
		public override void clear() {
			props.clear();
		}
		
		public override bool contains (GJson.Property property) {
			for (var i = 0; i < props.size; i++)
				if (props[i].equal_to (property))
					return true;
			return false;
		}
		
		public override Gee.Iterator<GJson.Property> iterator() {
			return props.iterator();
		}
		
		public override bool remove (GJson.Property property) {
			bool found = false;
			for (var i = props.size - 1; i >= 0; i--)
				if (props[i].name == property.name) {
					found = true;
					props.remove_at (i);
				}
			return found;
		}
		
		public GJson.Object slice (int start, int stop) {
			var obj = new Object();
			var list = props.slice (start, stop);
			if (list != null)
				for (var i = 0; i < list.size; i++) {
					var prop = list[i];
					var nprop = new Property (prop.name, null);
					if (prop.node.node_type != GJson.NodeType.NULL)
						nprop.value = prop.value;
					obj.add (nprop);
				}
			return obj;
		}
		
		public void sort (GLib.CompareDataFunc<GJson.Property>? compare_func = null) {
			if (compare_func == null)
				props.sort();
			else
				props.sort ((p1, p2) => {
					return compare_func (p1, p2);
				});
		}
		
		public Gee.Collection<GJson.Property> properties {
			owned get {
				return props.read_only_view;
			}
		}
		
		public override bool read_only {
			get {
				return false;
			}
		}
		
		public override int size {
			get {
				return props.size;
			}
		}
		
		internal Container container;
		internal string property_name;
		
		public override GJson.Container parent {
			get {
				return container;
			}
		}
		
		public override Gee.Collection<GJson.Item> children {
			owned get {
				var list = new Gee.ArrayList<GJson.Item>();
				for (var i = 0; i < props.size; i++)
					list.add (props[i]);
				return list;
			}
		}
		
		public override string path {
			owned get {
				if (parent == null)
					return "$";
				if (parent is Object)
					return "%s[\"%s\"]".printf (parent.path, property_name);
				if (parent is Array) {
					int index = int.parse (property_name);
					if (index < 0)
						return "$";
					return "%s[%d]".printf (parent.path, index);
				}
				return "$";
			}
		}
	}
}
