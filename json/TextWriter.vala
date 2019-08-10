namespace GJson {
	public class TextWriter : Writer {
		GText.Writer writer;
		
		public TextWriter (GText.Writer base_writer) {
			writer = base_writer;
			pretty = true;
			indent = 1;
			indent_char = '\t';
		}
		
		public bool    pretty      { get; set; }
		public uint    indent      { get; set; }
		public unichar indent_char { get; set; }
		
		public override void write_indent() throws GLib.Error {
			if (pretty)
				writer.write ('\n');
		}
		
		public override void write_space() throws GLib.Error {
			for (var u = 0; u < indent; u++)
				writer.write (indent_char);
		}
		
		public override void write_start_array() throws GLib.Error {
			writer.write ('[');
		}
		
		public override void write_start_object() throws GLib.Error {
			writer.write ('{');
		}
		
		public override void write_end_array() throws GLib.Error {
			writer.write (']');
		}
		
		public override void write_end_object() throws GLib.Error {
			writer.write ('}');
		}
		
		public override void write_delimiter() throws GLib.Error {
			writer.write (',');
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
		
		public override void write_string (string val) throws GLib.Error {
			writer.write ('"');
			writer.write_string (strescape (val));
			writer.write ('"');
		}
		
		public override void write_property_name (string name) throws GLib.Error {
			write_string (name);
			writer.write_string (" : ");
		}
		
		public override void write_double (double val) throws GLib.Error {
			writer.write_string ("%f".printf (val));
		}
		
		public override void write_boolean (bool val) throws GLib.Error {
			writer.write_string (val ? "true" : "false");
		}
		
		public override void write_integer (int64 val) throws GLib.Error {
			writer.write_string (val.to_string());
		}
		
		public override void write_null() throws GLib.Error {
			writer.write_string ("null");
		}
	}
}
