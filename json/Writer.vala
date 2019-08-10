namespace GJson {
	public abstract class Writer : GLib.Object {
		public abstract void write_start_array() throws GLib.Error;
		public abstract void write_start_object() throws GLib.Error;
		public abstract void write_end_array() throws GLib.Error;
		public abstract void write_end_object() throws GLib.Error;
		public abstract void write_property_name (string name) throws GLib.Error;
		public abstract void write_boolean (bool val) throws GLib.Error;
		public abstract void write_double (double val) throws GLib.Error;
		public abstract void write_string (string val) throws GLib.Error;
		public abstract void write_integer (int64 val) throws GLib.Error;
		public abstract void write_null() throws GLib.Error;
		public abstract void write_delimiter() throws GLib.Error;
		public abstract void write_indent() throws GLib.Error;
		public abstract void write_space() throws GLib.Error;
		
		public virtual void write_regex (Regex regex) throws GLib.Error {
			write_string (regex.get_pattern());
		}
		
		public virtual void write_datetime (DateTime dt) throws GLib.Error {
			write_string (dt.to_string());
		}
		
		public virtual void write_binary (Bytes bytes) throws GLib.Error {
			write_string (Base64.encode (bytes.get_data()));
		}
		
		public void write_property (GJson.Property property, int depth = 0) throws GLib.Error {
			write_property_name (property.name);
			write_node (property.node, depth);
		}
		
		public void write_node (GJson.Node node, int depth = 0) throws GLib.Error {
			if (node.node_type == NodeType.ARRAY)
				node.as_array().write_to (this, depth);
			else if (node.node_type == NodeType.OBJECT)
				node.as_object().write_to (this, depth);
			else if (node.node_type == NodeType.BOOLEAN)
				write_boolean (node.as_boolean());
			else if (node.node_type == NodeType.STRING)
				write_string (node.as_string());
			else if (node.node_type == NodeType.DOUBLE)
				write_double (node.as_double());
			else if (node.node_type == NodeType.INTEGER)
				write_integer (node.as_integer());
			else if (node.node_type == NodeType.BINARY)
				write_binary (node.as_binary());
			else if (node.node_type == NodeType.REGEX)
				write_regex (node.as_regex());
			else if (node.node_type == NodeType.DATETIME)
				write_datetime (node.as_datetime());
			else
				write_null();
		}
	}
}
