namespace GJson {
	static void bytearray_to_icon (Value src_value, ref Value dest_value) {
		ByteArray bytes = (ByteArray)src_value;
		Variant[] children = new Variant[bytes.len];
		for (var i = 0; i < bytes.len; i++)
			children[i] = new Variant.byte (bytes.data[i]);
		Variant array = new Variant.variant (new Variant.array (null, children));
		Variant vtype = new Variant.string ("bytes");
		Variant tuple = new Variant.tuple ({ vtype, array });
		dest_value.set_object (Icon.deserialize (tuple));
	}
	
	static void bytes_to_icon (Value src_value, ref Value dest_value) {
		Bytes bytes = (Bytes)src_value;
		Variant[] children = new Variant[bytes.get_size()];
		for (var i = 0; i < bytes.get_size(); i++)
			children[i] = new Variant.byte (bytes.get (i));
		Variant array = new Variant.variant (new Variant.array (null, children));
		Variant vtype = new Variant.string ("bytes");
		Variant tuple = new Variant.tuple ({ vtype, array });
		dest_value.set_object (Icon.deserialize (tuple));
	}
	
	static void datetime_to_string (Value src_value, ref Value dest_value) {
		DateTime dt = (DateTime)src_value;
		dest_value.set_string (dt.to_string());
	}
	
	static void date_to_string (Value src_value, ref Value dest_value) {
		Date d = (Date)src_value;
		Time t;
		d.to_time (out t);
		DateTime dt = new DateTime.from_unix_local (t.mktime());
		dest_value.set_string (dt.to_string());
	}
	
	static void time_to_string (Value src_value, ref Value dest_value) {
		Time t = (Time)src_value;
		DateTime dt = new DateTime.from_unix_local (t.mktime());
		dest_value.set_string (dt.to_string());
	}
	
	static void bytes_to_string (Value src_value, ref Value dest_value) {
		Bytes bytes = (Bytes)src_value;
		dest_value.set_string (Base64.encode (bytes.get_data()));
	}
	
	static void bytearray_to_string (Value src_value, ref Value dest_value) {
		ByteArray array = (ByteArray)src_value;
		dest_value.set_string (Base64.encode (array.data));
	}
	
	static void regex_to_string (Value src_value, ref Value dest_value) {
		Regex regex = (Regex)src_value;
		dest_value.set_string (regex.get_pattern());
	}
		
		
	static void string_to_datetime (Value src_value, ref Value dest_value) {
		string str = src_value.get_string();
		var dt = new DateTime.from_iso8601 (str, new TimeZone.local());
		if (dt != null)
			dest_value.set_boxed (dt);
		else
			dest_value.set_boxed (new DateTime.now_local());
	}
	
	static void string_to_time (Value src_value, ref Value dest_value) {
		string str = src_value.get_string();
		DateTime dt = new DateTime.from_iso8601 (str, new TimeZone.local());
		if (dt == null)
			dt = new DateTime.now_local();
		Time t = Time.local ((time_t)dt.to_unix());
		dest_value = t;
	}
	
	static void string_to_date (Value src_value, ref Value dest_value) { 
		string str = src_value.get_string();
		Date d = Date();
		var dt = new DateTime.from_iso8601 (str, new TimeZone.local());
		if (dt != null)
			d.set_time_t ((time_t)dt.to_unix());
		dest_value = d;
	}
	
	static void string_to_bytes (Value src_value, ref Value dest_value) { 
		string str = src_value.get_string();
		uint8[] data = Base64.decode (str);
		dest_value.set_boxed (new Bytes (data));
	}
	
	static void string_to_bytearray (Value src_value, ref Value dest_value) { 
		string str = src_value.get_string();
		uint8[] data = Base64.decode (str);
		var array = new ByteArray();
		array.append (data);
		dest_value.set_boxed (array);
	}
	
	static void string_to_regex (Value src_value, ref Value dest_value) {
		string str = src_value.get_string();
		Regex regex = new Regex (str);
		dest_value.set_boxed (regex);
	}
	
	static void int64_to_datetime (Value src_value, ref Value dest_value) {
		int64 val = src_value.get_int64();
		DateTime dt = new DateTime.from_unix_local (val);
		dest_value.set_boxed (dt);
	}
	
	static void int64_to_time (Value src_value, ref Value dest_value) {
		int64 val = src_value.get_int64();
		Time t = Time.local ((time_t)val);
		dest_value = t;
	}
	
	static void int64_to_date (Value src_value, ref Value dest_value) {
		int64 val = src_value.get_int64();
		Date d = Date();
		d.set_time_t ((time_t)val);
		dest_value = d;
	}
	
	static void init_funcs() {
		Value.register_transform_func (typeof (DateTime), typeof (string), datetime_to_string);
		Value.register_transform_func (typeof (Date), typeof (string), date_to_string);
		Value.register_transform_func (typeof (Time), typeof (string), time_to_string);
		Value.register_transform_func (typeof (Bytes), typeof (string), bytes_to_string);
		Value.register_transform_func (typeof (ByteArray), typeof (string), bytearray_to_string);
		Value.register_transform_func (typeof (Regex), typeof (string), regex_to_string);
			
		Value.register_transform_func (typeof (string), typeof (DateTime), string_to_datetime);
		Value.register_transform_func (typeof (string), typeof (Time), string_to_time);
		Value.register_transform_func (typeof (string), typeof (Date), string_to_date);
		Value.register_transform_func (typeof (string), typeof (Bytes), string_to_bytes);
		Value.register_transform_func (typeof (string), typeof (ByteArray), string_to_bytearray);
		Value.register_transform_func (typeof (string), typeof (Regex), string_to_regex);
		
		Value.register_transform_func (typeof (int64), typeof (DateTime), int64_to_datetime);
		Value.register_transform_func (typeof (int64), typeof (Date), int64_to_date);
		Value.register_transform_func (typeof (int64), typeof (Time), int64_to_time);
		
		Value.register_transform_func (typeof (Bytes), typeof (Icon), bytes_to_icon);
		Value.register_transform_func (typeof (ByteArray), typeof (Icon), bytearray_to_icon);
	}
	
	static void gee_list_add (Gee.Collection coll, GJson.Node node) {
		if (coll.element_type.is_object()) {
			var list = (Gee.Collection<GLib.Object>)coll;
			list.add (deserialize_object (coll.element_type, node.as_object()));
		}
		else if (coll.element_type == typeof (Value)) {
			var list = (Gee.Collection<Value?>)coll;
			list.add (node.value);
		}
		else if (coll.element_type == typeof (string)) {
			var list = (Gee.Collection<string>)coll;
			list.add ((string)node.as_string());
		}
		else if (coll.element_type == typeof (bool)) {
			var list = (Gee.Collection<bool>)coll;
			list.add ((bool)node.as_boolean());
		}
		else if (coll.element_type == typeof (int)) {
			var list = (Gee.Collection<int>)coll;
			list.add ((int)node.as_integer());
		}
		else if (coll.element_type == typeof (uint)) {
			var list = (Gee.Collection<uint>)coll;
			list.add ((uint)node.as_integer());
		}
		else if (coll.element_type == typeof (int8)) {
			var list = (Gee.Collection<int8>)coll;
			list.add ((int8)node.as_integer());
		}
		else if (coll.element_type == typeof (uint8)) {
			var list = (Gee.Collection<uint8>)coll;
			list.add ((uint8)node.as_integer());
		}
		else if (coll.element_type == typeof (int64)) {
			var list = (Gee.Collection<int64?>)coll;
			list.add (node.as_integer());
		}
		else if (coll.element_type == typeof (uint64)) {
			var list = (Gee.Collection<uint64?>)coll;
			list.add ((uint64)node.as_integer());
		}
		else if (coll.element_type == typeof (double)) {
			var list = (Gee.Collection<double?>)coll;
			list.add (node.as_double());
		}
		else if (coll.element_type == typeof (float)) {
			var list = (Gee.Collection<float?>)coll;
			list.add ((float)node.as_double());
		}
		else if (coll.element_type == typeof (Regex)) {
			var list = (Gee.Collection<Regex>)coll;
			list.add (node.as_regex());
		}
		else if (coll.element_type == typeof (DateTime)) {
			var list = (Gee.Collection<DateTime>)coll;
			list.add (node.as_datetime());
		}
		else if (coll.element_type == typeof (Date)) {
			var list = (Gee.Collection<Date?>)coll;
			Date d = Date();
			d.set_time_t ((time_t)node.as_datetime().to_unix());
			list.add (d);
		}
		else if (coll.element_type == typeof (Time)) {
			var list = (Gee.Collection<Time?>)coll;
			Time t = Time.local ((long)node.as_datetime().to_unix());
			list.add (t);
		}
		else if (coll.element_type == typeof (Bytes)) {
			var list = (Gee.Collection<Bytes>)coll;
			list.add (node.as_binary());
		}
		else if (coll.element_type == typeof (ByteArray)) {
			var list = (Gee.Collection<ByteArray>)coll;
			ByteArray array = new ByteArray.take (node.as_binary().get_data());
			list.add (array);
		}
	}
	
	static GLib.Value deserialize_node (GJson.Node node) {
		if (node.node_type == NodeType.STRING)
			return node.as_string();
		if (node.node_type == NodeType.DOUBLE)
			return node.as_double();
		if (node.node_type == NodeType.BOOLEAN)
			return node.as_boolean();
		if (node.node_type == NodeType.INTEGER)
			return node.as_integer();
		if (node.node_type == NodeType.DATETIME)
			return node.as_datetime();
		if (node.node_type == NodeType.REGEX)
			return node.as_regex();
		if (node.node_type == NodeType.BINARY)
			return node.as_binary();
		return 0;
	}
	
	public static Gee.List<T> deserialize_array<T>(GJson.Array array) {
		var list = new Gee.ArrayList<T>();
		for (var i = 0; i < array.size; i++)
			gee_list_add (list, array.get_element (i));
		return list;
	}
	
	public ParamSpec? find_property (ObjectClass klass, string name) {
	    ParamSpec[] specs = klass.list_properties ();
	    
	    foreach (var spec in specs) {
	        if (spec.get_nick () == @"json::$name") {
	            return spec;
	        }
	    }
	    
	    return klass.find_property (name);
	}
	
	public static GLib.Object deserialize_object (Type type, GJson.Object object) {
		assert (type.is_object());
		init_funcs();
		var obj = GLib.Object.new (type);
		var klass = (ObjectClass)type.class_ref();
		object.foreach (prop => {
		    ParamSpec? spec = find_property (klass, prop.name);
			if (spec == null)
				return true;
			var val = object.get_member (prop.name);
			if (val.node_type == NodeType.ARRAY && spec.value_type.is_a (typeof (Gee.Collection)) && (spec.flags & ParamFlags.WRITABLE) == 0) {
				Gee.Collection<void*> coll;
				obj.get (spec.name, out coll);
				if (coll == null)
					return true;
				val.as_array().foreach (node => {
					gee_list_add (coll, node);
					return true;
				});
			}
			if (val.node_type == NodeType.OBJECT && spec.value_type.is_a (typeof (Gee.Map)) && (spec.flags & ParamFlags.WRITABLE) == 0) {
				Gee.Map<void*,void*> map;
				obj.get (spec.name, out map);
				if (map == null || map.key_type != typeof (string))	
					return true;
				val.as_object().foreach (prop => {
					Value res = Value (map.value_type);
					prop.node.value.transform (ref res);
					if (map.value_type.is_object()) {
						var imap = (Gee.Map<string, GLib.Object>)map;
						imap[prop.name] = deserialize_object (map.value_type, prop.node.as_object());
					}
					else if (res.type() == typeof (bool)) {
						var imap = (Gee.Map<string, bool>)map;
						imap[prop.name] = (bool)res;
					}
					else if (res.type() == typeof (string)) {
						var imap = (Gee.Map<string, string>)map;
						imap[prop.name] = prop.node.as_string();
					}
					else if (res.type() == typeof (int)) {
						var imap = (Gee.Map<string, int>)map;
						imap[prop.name] = (int)res;
					}
					else if (res.type() == typeof (uint)) {
						var imap = (Gee.Map<string, uint>)map;
						imap[prop.name] = (uint)res;
					}
					else if (res.type() == typeof (int8)) {
						var imap = (Gee.Map<string, int8>)map;
						imap[prop.name] = (int8)res;
					}
					else if (res.type() == typeof (uint8)) {
						var imap = (Gee.Map<string, uint8>)map;
						imap[prop.name] = (uint8)res;
					}
					else if (res.type() == typeof (int64)) {
						var imap = (Gee.Map<string, int64?>)map;
						imap[prop.name] = (int64)res;
					}
					else if (res.type() == typeof (uint64)) {
						var imap = (Gee.Map<string, uint64?>)map;
						imap[prop.name] = (uint64)res;
					}
					else if (res.type() == typeof (double)) {
						var imap = (Gee.Map<string, double?>)map;
						imap[prop.name] = prop.node.as_double();
					}
					else if (res.type() == typeof (float)) {
						var imap = (Gee.Map<string, float?>)map;
						imap[prop.name] = (float)prop.node.as_double();
					}
					else if (res.type() == typeof (Regex)) {
						var imap = (Gee.Map<string, Regex>)map;
						imap[prop.name] = prop.node.as_regex();
					}
					else if (res.type() == typeof (DateTime)) {
						var imap = (Gee.Map<string, DateTime>)map;
						imap[prop.name] = prop.node.as_datetime();
					}
					else if (res.type() == typeof (Date)) {
						var imap = (Gee.Map<string, Date?>)map;
						Date d = Date();
						d.set_time_t ((time_t)prop.node.as_datetime().to_unix());
						imap[prop.name] = d;
					}
					else if (res.type() == typeof (Time)) {
						var imap = (Gee.Map<string, Time?>)map;
						imap[prop.name] = Time.local ((long)prop.node.as_datetime().to_unix());
					}
					else if (res.type() == typeof (Bytes)) {
						var imap = (Gee.Map<string, Bytes>)map;
						imap[prop.name] = prop.node.as_binary();
					}
					else if (res.type() == typeof (ByteArray)) {
						var imap = (Gee.Map<string, ByteArray>)map;
						imap[prop.name] = new ByteArray.take (prop.node.as_binary().get_data());
					}
					//////////////
					// TODO ... //
					//////////////
					return true;
				});
			}
			if (spec.value_type.is_object() && (spec.flags & ParamFlags.WRITABLE) != 0)
				obj.set (spec.name, deserialize_object (spec.value_type, val.as_object()));
			else if ((spec.flags & ParamFlags.WRITABLE) != 0) {
				obj.set_property (spec.name, deserialize_node (val));
			}
			return true;
		});
		return obj;
	}
	
	public static GLib.Value deserialize<T>(GJson.Node node) {
		if (typeof (T).is_object() && node.node_type == NodeType.OBJECT)
			return deserialize_object (typeof (T), node.as_object());
		return node.value;
	}
	
	static GJson.Array serialize_traversable_internal (Gee.Traversable<void*> traversable) {
		var array = new GJson.Array();
		traversable.foreach (pointer => {
			if (pointer == null)
				array.add (null);
			else if (traversable.element_type.is_a (typeof (Gee.Map)))
				array.add (serialize_map ((Gee.Map)pointer));
			else if (traversable.element_type.is_a (typeof (Gee.Traversable)))
				array.add (serialize_traversable_internal ((Gee.Traversable)pointer));
			else if (traversable.element_type.is_object())
				array.add (serialize_gobject ((GLib.Object)pointer));
			else if (traversable.element_type == typeof (GLib.Value)) {
				GLib.Value? val = (GLib.Value?)pointer;
				array.add (value_to_node (val));
			}
			else
				array.add (new Node.from (traversable.element_type, pointer));
			return true;
		});
		return array;
	}
	
	public static GJson.Array serialize_traversable (Gee.Traversable traversable) {
		return serialize_traversable_internal (traversable);
	}
	
	public static GJson.Object serialize_map (Gee.Map map) {
		var object = new Object();
		if (map.key_type != typeof (string))
			return object;
		map.foreach (entry => {
			string key = (string)entry.key;
			if (entry.value == null)
				object[key] = null;
			else if (map.value_type.is_a (typeof (Gee.Map)))
				object[key] = serialize_map ((Gee.Map)entry.value);
			else if (map.value_type.is_a (typeof (Gee.Traversable)))
				object[key] = serialize_traversable_internal ((Gee.Traversable)entry.value);
			else if (map.value_type.is_object())
				object[key] = serialize_gobject ((GLib.Object)entry.value);
			else if (map.value_type == typeof (GLib.Value)) {
				GLib.Value? val = (GLib.Value?)entry.value;
				object[key] = value_to_node (val);
			}
			else
				object[key] = new Node.from (map.value_type, entry.value);
			return true;
		});
		return object;
	}
	
	public static GJson.Object serialize_gobject (GLib.Object gobject) {
		var obj = new GJson.Object();
		var klass = (ObjectClass)gobject.get_type().class_ref();
		ParamSpec[] specs = klass.list_properties();
		foreach (var spec in specs) {
			Value val = Value (spec.value_type);
			gobject.get_property (spec.name, ref val);
			
			string prop_name;
			
			if ("json::" in spec.get_nick ()) {
			    prop_name = spec.get_nick ().substring ("json::".length);
			} else {
			    prop_name = spec.name;
			}
			
			obj[prop_name] = serialize (val);
		}
		return obj;
	}
	
	public static GJson.Node serialize_icon (Icon icon) {
		Variant variant = icon.serialize();
		if (variant == null || variant.n_children() < 2)
			return new Node();
		var vtype = variant.get_child_value (0).get_string();
		if (vtype == "bytes") {
			var v = variant.get_child_value (1).get_variant();
			var list = new Gee.ArrayList<uint8>();
			for (var u = 0; u < v.n_children(); u++)
				list.add (v.get_child_value (u).get_byte());
			var bytes = new Bytes (list.to_array());
			return new Node (bytes);
		}
		return new Node();
	}
	
	public static GJson.Object serialize_multimap (Gee.MultiMap map) {
		var object = new Object();
		if (map.key_type != typeof (string))
			return object;
		foreach (var key in ((Gee.Set<string>)map.get_keys()))
			object[key] = serialize_traversable (map[key]);
		return object;
	}
	
	public static GJson.Node serialize (GLib.Value value) {
		if (value.type().is_a (typeof (Gee.Map)))
			return new Node (serialize_map ((Gee.Map)value));
		if (value.type().is_a (typeof (Gee.Traversable)))
			return new Node (serialize_traversable ((Gee.Traversable)value));
		if (value.type().is_object())
			return new Node (serialize_gobject ((GLib.Object)value));
		if (value.type().is_a (typeof (Icon)))
			return serialize_icon ((Icon)value);
		return new Node (value);
	}
}
