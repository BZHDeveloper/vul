namespace GJson.JsonSchema {
	public class SchemaObject : Schema {
		public SchemaObject() {
			GLib.Object (schema_type: SchemaType.OBJECT);
		}
		
		Gee.ArrayList<string> req;
		Gee.HashMap<string, Schema> props;
		Gee.HashMap<string, GLib.Value?> deps;
		Gee.HashMap<string, Schema> pprops;
		
		construct {
			req = new Gee.ArrayList<string>();
			props = new Gee.HashMap<string, Schema>();
			deps = new Gee.HashMap<string, GLib.Value?>();
			pprops = new Gee.HashMap<string, Schema>();
			additional_properties = 0;
		}
		
		public uint64 max_properties { get; set; }
		public uint64 min_properties { get; set; }
		
		public GLib.Value additional_properties { get; set; }
		
		public Gee.Map<string, GLib.Value?> dependencies {
			get {
				return deps;
			}
			set {
				deps.clear();
				value.foreach (entry => {
					if (is_valid_string (entry.key))
						deps[entry.key] = entry.value;
					return true;
				});
			}
		}
		
		public Gee.Map<string, Schema> pattern_properties {
			get {
				return pprops;
			}
			set {
				pprops.clear();
				value.foreach (entry => {
					if (is_valid_string (entry.key))
						pprops[entry.key] = entry.value;
					return true;
				});
			}
		}
		
		public Gee.Map<string, Schema> properties {
			get {
				return props;
			}
			set {
				props.clear();
				value.foreach (entry => {
					if (is_valid_string (entry.key))
						props[entry.key] = entry.value;
					return true;
				});
			}
		}
		
		public string[] required {
			owned get {
				return req.to_array();
			}
			set {
				req.clear();
				foreach (string str in value)
					if (is_valid_string (str))
						req.add (str);
			}
		}
	}
}
