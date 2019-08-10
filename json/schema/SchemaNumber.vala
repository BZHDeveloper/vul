namespace GJson.JsonSchema {
	public class SchemaBoolean : Schema {
		public SchemaBoolean() {
			GLib.Object (schema_type: SchemaType.BOOLEAN);
		}
	}
	
	public class SchemaNumber : Schema {
		public SchemaNumber() {
			GLib.Object (schema_type: SchemaType.NUMBER);
		}
		
		public double multiple_of { get; set; }
		
		public double maximum { get; set; }
		public bool exclusive_maximum { get; set; }
		public double minimum { get; set; }
		public bool exclusive_minimum { get; set; }
	}
	
	public class SchemaInteger : Schema {
		public SchemaInteger() {
			GLib.Object (schema_type: SchemaType.INTEGER);
		}
		
		public int64 multiple_of { get; set; }
		
		public int64 maximum { get; set; }
		public bool exclusive_maximum { get; set; }
		public int64 minimum { get; set; }
		public bool exclusive_minimum { get; set; }
	}
}
