namespace GJson.JsonSchema {
	public class SchemaArray : Schema {
		public SchemaArray() {
			GLib.Object (schema_type: SchemaType.ARRAY);
		}
		
		public GLib.Value additional_items { get; set; }
		public GLib.Value items { get; set; }
		public uint64 max_items { get; set; }
		public uint64 min_items { get; set; }
		public bool unique_items { get; set; }
	}
	
	public class Set : GJson.Array {
		GLib.Type value_type;
		
		public new void add (GLib.Value val) {
			if (value_type != val.type())
				return;
			if (val in this)
				return;
			value_type = val.type();
			base.add (val);
		}
	}
	
	public class SchemaList : Gee.AbstractList<Schema> {
		Gee.ArrayList<Schema> schemas;
		
		construct {
			schemas = new Gee.ArrayList<Schema>();
		}
		
		public override bool add (Schema schema) {
			return schemas.add (schema);
		}
		
		public override void clear() {
			schemas.clear();
		}
		
		public override bool contains (Schema schema) {
			return schemas.contains (schema);
		}
		
		public override Schema get (int index) {
			return schemas[index];
		}
		
		public override int index_of (Schema schema) {
			return schemas.index_of (schema);
		}
		
		public override void insert (int index, Schema schema) {
			schemas.insert (index, schema);
		}
		
		public override Gee.Iterator<Schema> iterator() {
			return schemas.iterator();
		}
		
		public override Gee.ListIterator<Schema> list_iterator() {
			return schemas.list_iterator();
		}
		
		public override bool remove (Schema schema) {
			return schemas.remove (schema);
		}
		
		public override Schema remove_at (int index) {
			return schemas.remove_at (index);
		}
		
		public override void set (int index, Schema schema) {
			if (index >= 0 && index < schemas.size)
				schemas[index] = schema;
		}
		
		public override Gee.List<Schema>? slice (int start, int stop) {
			return schemas.slice (start, stop);
		}
		
		public override bool read_only {
			get {
				return false;
			}
		}
		
		public override int size {
			get {
				return schemas.size;
			}
		}
	}
}
