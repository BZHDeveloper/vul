namespace GJson {
	public class Array : GJson.Container<GLib.Value?> {
		public static GJson.Array load (GJson.Reader reader) throws GLib.Error {
			var array = reader.read_array();
			if (reader.peek_token() != TokenType.EOF)
				throw new ReaderError.INVALID ("GJson.Array.parse : extra content at end of array. '%s' token.".printf (reader.peek_token().get_nick()));
			return array;
		}
		
		public static async GJson.Array load_async (GJson.Reader reader) throws GLib.Error {
			GJson.Array array = null;
			ThreadFunc<void*> func = () => {
				array = load (reader);
				Idle.add (load_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return array;
		}

		public static GJson.Array parse (string data) throws GLib.Error {
			var reader = new GText.StringReader (data);
			var jreader = new TextReader (reader);
			return load (jreader);
		}
		
		public static async GJson.Array parse_async (string data) throws GLib.Error {
			GJson.Array array = null;
			ThreadFunc<void*> func = () => {
				array = parse (data);
				Idle.add (parse_async.callback);
				return null;
			};
			Thread.create (func, false);
			yield;
			return array;
		}
		
		Gee.ArrayList<Node> nodes;
		
		construct {
			nodes = new Gee.ArrayList<Node>();
		}
		
		public Array.wrap (GLib.Value?[] array) {
			this();
			add_all_array (array);
		}
		
		public Array.from_strv (string[] strv) {
			this();
			foreach (string str in strv)
				add (str);
		}
		
		public Array.from_traversable (Gee.Traversable traversable) {
			this();
			add_traversable (traversable);
		}
		
		[Version (experimental = true)]
		public void validate (JsonSchema.Schema schema) throws GLib.Error {
			if (!(schema is JsonSchema.SchemaArray))
				throw new JsonSchema.SchemaError.INVALID ("current schema isn't array.");
			var sc = schema as JsonSchema.SchemaArray;
			if (size > sc.max_items)
				throw new JsonSchema.SchemaError.INVALID ("current array is too big.");
			if (size < sc.min_items)
				throw new JsonSchema.SchemaError.INVALID ("current array is too small.");
			if (sc.unique_items && size > 1) {
				for (var i = 0; i < size; i++)
					for (var j = 0; j < size; j++)
						if (j != i && this[i].equal_to (this[j]))
							throw new JsonSchema.SchemaError.INVALID ("current array has equal nodes.");
			}
			if (sc.items.type().is_a (typeof (JsonSchema.Schema))) {
				var s = (JsonSchema.Schema)sc.items;
				foreach (var item in this)
					item.validate (s);
			}
			else if (sc.items.type().is_a (typeof (JsonSchema.SchemaList))) {
				var sl = (JsonSchema.SchemaList)sc.items;
				if (sl.size != size)
					throw new JsonSchema.SchemaError.INVALID ("current array doesn't have requested size");
				for (var i = 0; i < sl.size; i++)
					this[i].validate (sl[i]);
			}
			else
				throw new JsonSchema.SchemaError.INVALID ("invalid type for schema items.");
		}
		
		void add_traversable_internal (Gee.Traversable<void*> traversable) {
			Type t = traversable.element_type;
			traversable.foreach (pointer => {
				if (t == typeof (GLib.Value)) {
					GLib.Value? val = (GLib.Value?)pointer;
					nodes.add (value_to_node (val));
				}
				else
					nodes.add (new Node.from (t, pointer));
				return true;
			});
		}
		
		public void add_traversable (Gee.Traversable traversable) {
			add_traversable_internal (traversable);
		}
		
		public GJson.Array select (string expression) throws GLib.Error {
			return Path.query (expression, new Node (this));
		}
		
		public override GJson.Node get (GLib.Value index) {
			Value i = -1;
			index.transform (ref i);
			int idx = (int)i;
			return get_element (idx);
		}
		
		public GJson.Node get_element (int index) {
			if (index < 0 || index >= nodes.size)
				return new Node();
			return nodes[index];
		}
		
		public bool get_null_element (int index) {
			if (index < 0 || index >= nodes.size)
				return false;
			return nodes[index].node_type == NodeType.NULL;
		}
		
		public GJson.Array get_array_element (int index) {
			return get_element (index).as_array();
		}
		
		public GJson.Object get_object_element (int index) {
			return get_element (index).as_object();
		}
		
		public string get_string_element (int index) {
			return get_element (index).as_string();
		}
		
		public bool get_boolean_element (int index) {
			return get_element (index).as_boolean();
		}
		
		public int64 get_integer_element (int index) {
			return get_element (index).as_integer();
		}
		
		public double get_double_element (int index) {
			return get_element (index).as_double();
		}
		
		public Regex get_regex_element (int index) {
			return get_element (index).as_regex();
		}
		
		public DateTime get_datetime_element (int index) {
			return get_element (index).as_datetime();
		}
		
		public Bytes get_binary_element (int index) {
			return get_element (index).as_binary();
		}
		
		public int index_of (GLib.Value? val) {
			var node = value_to_node (val);
			return nodes.index_of (node);
		}
		
		public void insert (int index, GLib.Value? val) {
			if (index < 0 || index >= nodes.size)
				return;
			var node = value_to_node (val);
			nodes.insert (index, node);	
		}
		
		public GJson.Node remove_at (int index) {
			if (index < 0 || index >= nodes.size)
				return new Node();
			return nodes.remove_at (index);
		}
		
		public new void set (int index, GLib.Value? val) {
			if (index < 0 || index >= nodes.size)
				return;
			var node = value_to_node (val);
			node.container = this;
			if (node.node_type == NodeType.OBJECT)
				node.as_object().container = this;
			if (node.node_type == NodeType.ARRAY)
				node.as_array().container = this;
			node.property_name = nodes.size.to_string();
			nodes[index] = node;
		}
		
		public void set_element (int index, GJson.Node node) {
			if (index < 0 || index >= nodes.size)
				return;
			node.container = this;
			if (node.node_type == NodeType.OBJECT)
				node.as_object().container = this;
			if (node.node_type == NodeType.ARRAY)
				node.as_array().container = this;
			node.property_name = nodes.size.to_string();
			nodes[index] = node;
		}
		
		public void set_null_element (int index) {
			set_element (index, new Node());
		}
		
		public void set_array_element (int index, GJson.Array val) {
			set_element (index, new Node (val));
		}
		
		public void set_object_element (int index, GJson.Object val) {
			set_element (index, new Node (val));
		}
		
		public void set_boolean_element (int index, bool val) {
			set_element (index, new Node (val));
		}
		
		public void set_string_element (int index, string val) {
			set_element (index, new Node (val));
		}
		
		public void set_integer_element (int index, int64 val) {
			set_element (index, new Node (val));
		}
		
		public void set_double_element (int index, double val) {
			set_element (index, new Node (val));
		}
		
		public void set_regex_element (int index, Regex val) {
			set_element (index, new Node (val));
		}
		
		public void set_datetime_element (int index, DateTime val) {
			set_element (index, new Node (val));
		}
		
		public void set_binary_element (int index, Bytes val) {
			set_element (index, new Node (val));
		}
		
		public GJson.Array slice (int start, int stop) {
			var list = nodes.slice (start, stop);
			var array = new Array();
			if (list == null)
				return array;
			for (var i = 0; i < list.size; i++) {
				if (list[i].node_type == GJson.NodeType.NULL)
					array.add_null_element();
				else {
					var node = new GJson.Node (list[i].value);
					array.add_element (node);
				}
			}
			return array;
		}
		
		public void sort (GLib.CompareDataFunc<GJson.Node>? compare_func = null) {
			if (compare_func == null)
				nodes.sort();
			else
				nodes.sort ((p1, p2) => {
					return compare_func (p1, p2);
				});
		}
		
		public override bool add (GLib.Value? val) {
			var node = value_to_node (val);
			node.container = this;
			if (node.node_type == NodeType.OBJECT)
				node.as_object().container = this;
			if (node.node_type == NodeType.ARRAY)
				node.as_array().container = this;
			node.property_name = nodes.size.to_string();
			return nodes.add (node);
		}
		
		public bool add_element (GJson.Node node) {
			node.container = this;
			if (node.node_type == NodeType.OBJECT)
				node.as_object().container = this;
			if (node.node_type == NodeType.ARRAY)
				node.as_array().container = this;
			node.property_name = nodes.size.to_string();
			return nodes.add (node);
		}
		
		public bool add_null_element() {
			var node = new Node();
			node.container = this;
			return nodes.add (node);
		}
		
		public bool add_array_element (GJson.Array val) {
			return add_element (new Node (val));
		}
		
		public bool add_object_element (GJson.Object val) {
			return add_element (new Node (val));
		}
		
		public bool add_boolean_element (bool val) {
			return add_element (new Node (val));
		}
		
		public bool add_string_element (string val) {
			return add_element (new Node (val));
		}
		
		public bool add_integer_element (int64 val) {
			return add_element (new Node (val));
		}
		
		public bool add_double_element (double val) {
			return add_element (new Node (val));
		}
		
		public bool add_regex_element (Regex val) {
			return add_element (new Node (val));
		}
		
		public bool add_datetime_element (DateTime val) {
			return add_element (new Node (val));
		}
		
		public bool add_binary_element (Bytes val) {
			return add_element (new Node (val));
		}
		
		public override void clear() {
			nodes.clear();
		}
		
		public override bool contains (GLib.Value? val) {
			return index_of (val) > -1;
		}
		
		public override Gee.Iterator<GLib.Value?> iterator() {
			return nodes.iterator().map<GLib.Value?>(node => {
				if (node.node_type == NodeType.NULL)
					return null;
				return node.value;
			});
		}
		
		public override bool remove (GLib.Value? val) {
			var node = value_to_node (val);
			return nodes.remove (node);
		}
		
		public override bool equal_to (GJson.Container container) {
			if (!(container is GJson.Array))
				return false;
			var array = container as GJson.Array;
			if (array.size != nodes.size)
				return false;
			for (var i = 0; i < nodes.size; i++)
				if (!nodes[i].equal_to (array[i]))
					return false;
			return true;
		}
		
		public bool equal (GLib.Value val) {
			if (val.type().is_a (typeof (Array))) {
				var array = (Array)val;
				return equal_to (array);
			}
			if (val.type() == typeof (Gee.Traversable)) {
				Gee.Traversable iter = (Gee.Traversable)val;
				var array = new Array.from_traversable (iter);
				return equal_to (array);
			}
			if (val.type() == typeof (string[])) {
				var array = new Array();
				var strv = (string[])val;
				for (var i = 0; i < strv.length; i++)
					array.add (strv[i]);
				return equal_to (array);
			}
			return false;
		}
		
		public void write_to (GJson.Writer writer, int depth = 0) throws GLib.Error {
			writer.write_start_array();
			writer.write_indent();
			for (var i = 0; i < nodes.size - 1; i++) {
				for (var j = 0; j < depth + 1; j++)
					writer.write_space();
				writer.write_node (nodes[i], depth + 1);
				writer.write_delimiter();
				writer.write_indent();
			}
			if (nodes.size > 0) {
				for (var j = 0; j < depth + 1; j++)
					writer.write_space();
				writer.write_node (nodes[nodes.size - 1], depth + 1);
				writer.write_indent();
			}
			for (var j = 0; j < depth; j++)
				writer.write_space();
			writer.write_end_array();
		}
		
		public override string to_string() {
			var twriter = new GText.StringWriter();
			try {
				var writer = new TextWriter (twriter);
				write_to (writer);
			} catch {}
			return twriter.text;
		}
		
		public new bool foreach (Gee.ForallFunc<GJson.Node> func) {
			return nodes.foreach (func);
		}
		
		public override bool read_only {
			get {
				return false;
			}
		}
		
		public override int size {
			get {
				return nodes.size;
			}
		}
		
		public GJson.NodeType is_single {
			get {
				if (nodes.size == 0)
					return GJson.NodeType.NULL;
				for (var i = 1; i < nodes.size; i++)
					if (nodes[i].node_type != nodes[0].node_type)
						return NodeType.NULL;
				return nodes[0].node_type;
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
				return nodes.read_only_view;
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
