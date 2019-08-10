namespace GJson.JsonSchema {
	internal static bool is_valid_string (string str) {
		if (str[0] == '"')
			return false;
		var pos = 1;
		while (pos < str.length) {
			if (str[pos] == '"' && str[pos - 1] != '\\')
				return false;
			pos++;
		}
		return true;
	}
	
	public enum SchemaType {
		NULL,
		ARRAY,
		BOOLEAN,
		INTEGER,
		NUMBER,
		OBJECT,
		STRING;
		
		public string to_string() {
			var strv = new string[]{"null", "array", "boolean", "integer", "number", "object", "string"};
			return strv[(int)this];
		}
	}
	
	public class Schema : GLib.Object {
		[Version (experimental = true)]
		public void validate (GJson.Node node) throws GLib.Error {
			node.validate (this);
		}
		
		string _title;
		string _description;
		
		public string description {
			get {
				return _description;
			}
			set {
				_description = is_valid_string (value) ? value : null;
			}
		}
		
		public string title {
			get {
				return _title;
			}
			set {
				_title = is_valid_string (value) ? value : null;
			}
		}
		
		public Set @enum { get; set; }
	
		public SchemaType schema_type { get; set construct; }
	
		public static Schema parse (string data) throws GLib.Error {
			var object = GJson.Object.parse (data);
			Schema schema = parse_schema (object);
			if (object.has_key ("title") && object["title"].node_type == GJson.NodeType.STRING)
				schema.title = object["title"].as_string();
			if (object.has_key ("description") && object["description"].node_type == GJson.NodeType.STRING)
				schema.description = object["description"].as_string();
			return schema;
		}
		
		static Schema parse_schema (GJson.Object object) throws GLib.Error {
			Schema schema = null;
			if (object["type"] != null) {
				if (object["type"].as_string() == "array")
					schema = parse_array (object);
				else if (object["type"].as_string() == "object")
					schema = parse_object (object);
				else if (object["type"].as_string() == "boolean")
					schema = parse_boolean (object);
				else if (object["type"].as_string() == "integer")
					schema = parse_integer (object);
				else if (object["type"].as_string() == "number")
					schema = parse_number (object);
				else if (object["type"].as_string() == "string")
					schema = parse_string (object);
				else
					throw new SchemaError.INVALID ("invalid object type (%s).".printf (object["type"].as_string()));
			}
			if (object["enum"] != null) {
				
			}
			return schema;
		}
		
		static Schema parse_number (GJson.Object object) throws GLib.Error {
			var schema = new SchemaNumber();
			if (object.has_key ("multipleOf")) {
				if (object["multipleOf"].node_type != GJson.NodeType.DOUBLE)
					throw new SchemaError.INVALID ("invalid type for 'multipleOf'.");
				schema.multiple_of = object["multipleOf"].as_double();
			}
			if (object.has_key ("maximum")) {
				if (object["maximum"].node_type != GJson.NodeType.DOUBLE)
					throw new SchemaError.INVALID ("invalid type for 'maximum'.");
				schema.maximum = object["maximum"].as_double();
			}
			if (object.has_key ("exclusiveMaximum")) {
				if (object["exclusiveMaximum"].node_type != GJson.NodeType.BOOLEAN)
					throw new SchemaError.INVALID ("invalid type for 'exclusiveMaximum'.");
				schema.exclusive_maximum = object["exclusiveMaximum"].as_boolean();
			}
			if (object.has_key ("minimum")) {
				if (object["minimum"].node_type != GJson.NodeType.DOUBLE)
					throw new SchemaError.INVALID ("invalid type for 'minimum'.");
				schema.minimum = object["minimum"].as_double();
			}
			if (object.has_key ("exclusiveMinimum")) {
				if (object["exclusiveMinimum"].node_type != GJson.NodeType.BOOLEAN)
					throw new SchemaError.INVALID ("invalid type for 'exclusiveMinimum'.");
				schema.exclusive_minimum = object["exclusiveMinimum"].as_boolean();
			}
			return schema;
		}
		
		static Schema parse_integer (GJson.Object object) throws GLib.Error {
			var schema = new SchemaInteger();
			if (object.has_key ("multipleOf")) {
				if (object["multipleOf"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'multipleOf'.");
				schema.multiple_of = object["multipleOf"].as_integer();
			}
			if (object.has_key ("maximum")) {
				if (object["maximum"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'maximum'.");
				schema.maximum = object["maximum"].as_integer();
			}
			if (object.has_key ("exclusiveMaximum")) {
				if (object["exclusiveMaximum"].node_type != GJson.NodeType.BOOLEAN)
					throw new SchemaError.INVALID ("invalid type for 'exclusiveMaximum'.");
				schema.exclusive_maximum = object["exclusiveMaximum"].as_boolean();
			}
			if (object.has_key ("minimum")) {
				if (object["minimum"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'minimum'.");
				schema.minimum = object["minimum"].as_integer();
			}
			if (object.has_key ("exclusiveMinimum")) {
				if (object["exclusiveMinimum"].node_type != GJson.NodeType.BOOLEAN)
					throw new SchemaError.INVALID ("invalid type for 'exclusiveMinimum'.");
				schema.exclusive_minimum = object["exclusiveMinimum"].as_boolean();
			}
			return schema;
		}
		
		static Schema parse_string (GJson.Object object) throws GLib.Error {
			var schema = new SchemaString();
			if (object.has_key ("maxLength")) {
				if (object["maxLength"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'maxLength'.");
				schema.max_length = (uint64)object["maxLength"].as_integer();
			}
			if (object.has_key ("minLength")) {
				if (object["minLength"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'minLength'.");
				schema.min_length = (uint64)object["minLength"].as_integer();
			}
			if (object.has_key ("pattern")) {
				if (object["pattern"].node_type != GJson.NodeType.STRING)
					throw new SchemaError.INVALID ("invalid type for 'minLength'.");
				schema.pattern = new Regex (object["pattern"].as_string());
			}
			return schema;
		}
		
		static Schema parse_boolean (GJson.Object object) {
			return new SchemaBoolean();
		}
		
		static SchemaArray parse_array (GJson.Object object) throws GLib.Error {
			var schema = new SchemaArray();
			if (!object.has_key ("items"))
				throw new SchemaError.INVALID ("can't find items object.");
			if (object["items"].node_type == GJson.NodeType.OBJECT)
				schema.items = parse_schema (object["items"].as_object());
			if (object["items"].node_type == GJson.NodeType.ARRAY) {
				var slist = new SchemaList();
				object["items"].as_array().foreach (node => {
					if (node.node_type != GJson.NodeType.OBJECT)
						throw new SchemaError.INVALID ("current node is invalid.");
					slist.add (parse_schema (node.as_object()));
					return true;
				});
				schema.items = slist;
			}
			if (object.has_key ("additionalItems")) {
				if (object["additionalItems"].node_type == GJson.NodeType.BOOLEAN)
					schema.additional_items = object["additionalItems"].as_boolean();
				else if (object["additionalItems"].node_type == GJson.NodeType.OBJECT)
					schema.additional_items = parse_schema (object["additionalItems"].as_object());
				else throw new SchemaError.INVALID ("invalid type for 'additionalItems'.");
			}
			if (object.has_key ("maxItems"))
				if (object["maxItems"].node_type != GJson.NodeType.INTEGER) 
					throw new SchemaError.INVALID ("invalid type for 'maxItems'.");
				else
					schema.max_items = (uint64)object["maxItems"].as_integer();
			if (object.has_key ("minItems"))
				if (object["minItems"].node_type != GJson.NodeType.INTEGER) 
					throw new SchemaError.INVALID ("invalid type for 'minItems'.");
				else
					schema.min_items = (uint64)object["minItems"].as_integer();
			if (object.has_key ("uniqueItems"))
				if (object["uniqueItems"].node_type != GJson.NodeType.BOOLEAN) 
					throw new SchemaError.INVALID ("invalid type for 'uniqueItems'.");
				else
					schema.unique_items = object["uniqueItems"].as_boolean();
			return schema;
		}
		
		static SchemaObject parse_object (GJson.Object object) throws GLib.Error {
			var schema = new SchemaObject();
			if (object.has_key ("maxProperties"))
				if(object["maxProperties"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'maxProperties'.");
				else
					schema.max_properties = (uint64)object["maxProperties"].as_integer();
			if (object.has_key ("minProperties"))
				if(object["minProperties"].node_type != GJson.NodeType.INTEGER)
					throw new SchemaError.INVALID ("invalid type for 'minProperties'.");
				else
					schema.min_properties = (uint64)object["minProperties"].as_integer();
			if (object.has_key ("required")) {
				if (object["required"].node_type == GJson.NodeType.ARRAY)
					throw new SchemaError.INVALID ("invalid type for 'required'.");
				string[] req = new string[0];
				object["required"].as_array().foreach (node => {
					if (node.node_type != GJson.NodeType.STRING)
						throw new SchemaError.INVALID ("current node is invalid.");
					if (node.as_string() in req)
						throw new SchemaError.INVALID ("current string is already in required values.");
					req += node.as_string();
					return true;
				});
				schema.required = req;
			}
			if (object.has_key ("additionalProperties")) {
				if (object["additionalProperties"].node_type == GJson.NodeType.BOOLEAN)
					schema.additional_properties = object["additionalProperties"].as_boolean();
				else if (object["additionalProperties"].node_type == GJson.NodeType.OBJECT)
					schema.additional_properties = parse_schema (object["additionalProperties"].as_object());
				else throw new SchemaError.INVALID ("invalid type for 'additionalProperties'.");
			}
			if (object.has_key ("properties")) {
				if (object["properties"].node_type != GJson.NodeType.OBJECT)
					throw new SchemaError.INVALID ("invalid type for 'properties'.");
				object["properties"].as_object().foreach (prop => {
					if (prop.node.node_type != GJson.NodeType.OBJECT)
						throw new SchemaError.INVALID ("invalid type for current property.");
					schema.properties[prop.name] = parse_schema (prop.node.as_object());
					return true;
				});
			}
			if (object.has_key ("patternProperties")) {
				if (object["patternProperties"].node_type != GJson.NodeType.OBJECT)
					throw new SchemaError.INVALID ("invalid type for 'patternProperties'.");
				object["patternProperties"].as_object().foreach (prop => {
					if (prop.node.node_type != GJson.NodeType.OBJECT)
						throw new SchemaError.INVALID ("invalid type for current property.");
					try {
						var regex = new Regex (prop.name);
						schema.pattern_properties[prop.name] = parse_schema (prop.node.as_object());
					} catch {
						throw new SchemaError.INVALID ("current key isn't valid Regex.");
					}
					return true;
				});
			}
			if (object.has_key ("dependencies")) {
				if (object["dependencies"].node_type != GJson.NodeType.OBJECT)
					throw new SchemaError.INVALID ("invalid type for 'dependencies'.");
				object["dependencies"].as_object().foreach (prop => {
					if (prop.node.node_type == GJson.NodeType.ARRAY && prop.node.as_array().is_single == GJson.NodeType.STRING) {
						string[] deps = new string[0];
						prop.node.as_array().foreach (val => {
							deps += val.as_string();
							return true;
						});
						schema.dependencies[prop.name] = deps;
					}
					else if (prop.node.node_type == GJson.NodeType.OBJECT)
						schema.dependencies[prop.name] = parse_schema (prop.node.as_object());
					else
						throw new SchemaError.INVALID ("invalid type for current dependency.");
					return true;
				});
			}
			return schema;
		}
	}
	
	public errordomain SchemaError {
		NONE,
		INVALID
	}
}
