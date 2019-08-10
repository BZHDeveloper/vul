namespace GJson.JsonSchema {
	public class SchemaString : Schema {
		public SchemaString() {
			GLib.Object (schema_type: SchemaType.STRING);
		}
		
		public uint64 max_length { get; set; }
		public uint64 min_length { get; set; } 
		
		public Regex pattern { get; set; }
	}
}
