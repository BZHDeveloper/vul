namespace GJson {
	internal enum PathNodeType {
		ROOT,
		CHILD_MEMBER,
		CHILD_ELEMENT,
		RECURSIVE_DESCENT,
		WILDCARD_MEMBER,
		WILDCARD_ELEMENT,
		ELEMENT_SET,
		ELEMENT_SLICE
	}
	
	internal struct PathSlice {
		public int start;
		public int stop;
		public int step;
	}
	
	internal class PathNode : GLib.Object {
		Gee.ArrayList<int> list;
		
		public PathNode (PathNodeType node_type = PathNodeType.ROOT) {
			GLib.Object (node_type : node_type);
		}
		
		construct {
			list = new Gee.ArrayList<int>();
		}
		
		public Gee.List<int> indices {
			get {
				return list;
			}
		}
		
		public PathSlice slice { get; set; }
		
		public int element_index { get; set; }
		
		public string member_name { get; set; }
		
		public PathNodeType node_type { get; construct; }
	}
	
	public errordomain PathError {
		INVALID
	}
	
	internal class Path : GLib.Object {
		Gee.ArrayList<PathNode> nodes;
		
		construct {
			nodes = new Gee.ArrayList<PathNode>();
		}
		
		public bool compile (string expression) throws GLib.Error {
			nodes.clear();
			PathNode root = null;
			char *end_p;
			char *p = (char*)expression;
			while (*p != '\0') {
				switch (*p) {
					case '$' :
						if (root != null)
							throw new PathError.INVALID ("Only one root node is allowed in a JSONPath expression");
						if (!(*(p + 1) == '.' || *(p + 1) == '[' || *(p + 1) == '\0'))
							throw new PathError.INVALID ("Root node followed by invalid character '%c'".printf (*(p + 1)));
						root = new PathNode();
						nodes.add (root);
					break;
					case '.':
					case '[':
						PathNode node = null;
						if (*p == '.' && *(p + 1) == '.')
							node = new PathNode (PathNodeType.RECURSIVE_DESCENT);
						else if (*p == '.' && *(p + 1) == '*') {
							node = new PathNode (PathNodeType.WILDCARD_MEMBER);
							p += 1;
						}
						else if (*p == '.') {
							end_p = p + 1;
							while (!(*end_p == '.' || *end_p == '[' || *end_p == '\0'))
								end_p += 1;
							if (end_p == p + 1)
								throw new PathError.INVALID ("Missing member name or wildcard after . character");
							node = new PathNode (PathNodeType.CHILD_MEMBER);
							string s = (string)(p + 1);
							node.member_name = s.ndup (end_p - p - 1);
							p = end_p - 1;
						}
						else if (*p == '[' && *(p + 1) == '\'') {
							if (*(p + 2) == '*' && *(p + 3) == '\'' && *(p + 4) == ']') {
								node = new PathNode (PathNodeType.WILDCARD_MEMBER);
								p += 4;
							}
							else {
								node = new PathNode (PathNodeType.CHILD_MEMBER);
								string s = (string)(p + 2);
								end_p = (char*)s.str ("'");
								node.member_name = s.ndup (end_p - p - 2);
								p = end_p + 1;
							}
						}
						else if (*p == '[' && *(p + 1) == '*' && *(p + 2) == ']') {
							node = new PathNode (PathNodeType.WILDCARD_ELEMENT);
							p += 1;
						}
						else if (*p == '[') {
							int sign = 1;
							int idx;

							end_p = p + 1;

							if (*end_p == '-') {
								sign = -1;
								end_p += 1;
							}
							
							if (*end_p == ':') {
								string s = (string)(end_p + 1);
								string end;
								int slice_end = (int)s.to_int64 (out end, 10) * sign;
								end_p = (char*)end;
								int slice_step = 1;
								
								if (*end_p == ':') {
									end_p += 1;
									if (*end_p == '-')
									{
										sign = -1;
										end_p += 1;
									}
									else
										sign = 1;
										
									s = (string)end_p;
									slice_step = (int)s.to_int64 (out end, 10) * sign;
									end_p = (char*)end;
									
									if (*end_p != ']')
										throw new PathError.INVALID ("Malformed slice expression '%*s'".printf ((int)(end_p - p), p + 1));
								}
								
								node = new PathNode (PathNodeType.ELEMENT_SLICE);
								node.slice = { 0, slice_end, slice_step };
								nodes.add (node);
								p = end_p;
								break;
							}
							
							string s = (string)end_p;
							string end;
							idx = (int)s.to_int64 (out end, 10) * sign;
							end_p = (char*)end;
							
							if (*end_p == ',') {
								node = new PathNode (PathNodeType.ELEMENT_SET);
								node.indices.add (idx);
								while (*end_p != ']') {
									end_p += 1;
									if (*end_p == '-')
									{
										sign = -1;
										end_p += 1;
									}
									else
										sign = 1;
									s = (string)end_p;
									idx = (int)s.to_int64 (out end, 10) * sign;
									end_p = (char*)end;
									if (!(*end_p == ',' || *end_p == ']'))
										throw new PathError.INVALID ("Invalid set definition '%*s'".printf ((int)(end_p - p), p + 1));
									node.indices.add (idx);
								}
								nodes.add (node);
								p = end_p;
								break;
							}
							else if (*end_p == ':') {
								int slice_start = idx;
								int slice_end = 0;
								int slice_step = 1;
								end_p += 1;

								if (*end_p == '-')
								{
									sign = -1;
									end_p += 1;
								}
								else
									sign = 1;
								
								s = (string)end_p;
								slice_end = (int)s.to_int64 (out end, 10) * sign;
								end_p = (char*)end;
								
								if (*end_p == ':') {
									end_p += 1;

									if (*end_p == '-')
									{
										sign = -1;
										end_p += 1;
									}
									else
										sign = 1;
										
									s = (string)(end_p + 1);
									slice_step = (int)s.to_int64 (out end, 10) * sign;
									end_p = (char*)end;	
								}
								
								if (*end_p != ']')
									throw new PathError.INVALID ("Invalid slice definition '%*s'".printf ((int)(end_p - p), p + 1));
									
								node = new PathNode (PathNodeType.ELEMENT_SLICE);
								node.slice = { slice_start, slice_end, slice_step };
								nodes.add (node);
								p = end_p;
								break;
							}
							else if (*end_p == ']') {
								node = new PathNode (PathNodeType.CHILD_ELEMENT);
								node.element_index = idx;
								nodes.add (node);
								p = end_p;
								break;
							}
							else
								throw new PathError.INVALID ("Invalid array index definition '%*s'".printf ((int)(end_p - p), p + 1));
						}
						else
							break;
						if (node != null)
							nodes.add (node);
					break;
					default:
						if (nodes.size == 0)
							throw new PathError.INVALID ("Invalid first character '%c'".printf (*p));
					break;
				}
				
				p += 1;
			}
			return true;
		}
		
		void walk_path_node (int list_index, GJson.Node root, GJson.Array result) {
			PathNode node = nodes[list_index];
			switch (node.node_type) {
				case PathNodeType.ROOT:
					if (list_index + 1 != nodes.size)
						walk_path_node (list_index + 1, root, result);
					else
						result.add (root);
				break;
				case PathNodeType.CHILD_MEMBER:
					if (root.node_type == NodeType.OBJECT) {
						var object = root.as_object();
						if (object.has_key (node.member_name)) {
							var member = object.get_member (node.member_name);
							if (list_index + 1 == nodes.size)
								result.add (member);
							else
								walk_path_node (list_index + 1, member, result);
						}
					}
				break;
				case PathNodeType.CHILD_ELEMENT:
					if (root.node_type == NodeType.ARRAY) {
						var array = root.as_array();
						if (array.size > node.element_index) {
							var element = array.get_element (node.element_index);
							if (list_index + 1 == nodes.size)
								result.add (element);
							else
								walk_path_node (list_index + 1, element, result);
						}
					}
				break;
				case PathNodeType.RECURSIVE_DESCENT:
					PathNode tmp = nodes[list_index + 1];
					switch (root.node_type) {
						case NodeType.OBJECT:
							var object = root.as_object();
							object.foreach (property => {
								if (tmp.node_type == PathNodeType.CHILD_MEMBER && str_equal (tmp.member_name, property.name))
									walk_path_node (list_index + 1, root, result);
								else
									walk_path_node (list_index, property.node, result);
								return true;
							});
						break;
						case NodeType.ARRAY:
							var array = root.as_array();
							for (var i = 0; i < array.size; i++) {
								if (tmp.node_type == PathNodeType.CHILD_ELEMENT && tmp.element_index == i)
									walk_path_node (list_index + 1, root, result);
								else
									walk_path_node (list_index, array.get_element (i), result);
							}
						break;
					}
				break;
				case PathNodeType.WILDCARD_MEMBER:
					if (root.node_type == NodeType.OBJECT) {
						var object = root.as_object();
						object.foreach (property => {
							if (list_index + 1 != nodes.size)
								walk_path_node (list_index + 1, property.node, result);
							else
								result.add (property.node);
							return true;
						});
					}
					else
						result.add (root);
				break;
				case PathNodeType.WILDCARD_ELEMENT:
					if (root.node_type == NodeType.ARRAY) {
						var array = root.as_array();
						for (var i = 0; i < array.size; i++) {
							if (list_index + 1 != nodes.size)
								walk_path_node (list_index + 1, array.get_element (i), result);
							else
								result.add (array.get_element (i));
						}
					}
					else
						result.add (root);
				break;
				case PathNodeType.ELEMENT_SET:
					if (root.node_type == NodeType.ARRAY) {
						var array = root.as_array();
						node.indices.foreach (indice => {
							var element = array.get_element (indice);
							if (list_index + 1 != nodes.size)
								walk_path_node (list_index + 1, element, result);
							else
								result.add (element);
							return true;
						});
					}
				break;
				case PathNodeType.ELEMENT_SLICE:
					if (root.node_type == NodeType.ARRAY) {
						var array = root.as_array();
						int start, end;
						if (node.slice.start < 0) {
							start = array.size + node.slice.start;
							end = array.size + node.slice.stop;
						}
						else {
							start = node.slice.start;
							end = node.slice.stop;
						}
						for (var i = start; i < end; i += node.slice.step) {
							var element = array.get_element (i);
							if (list_index + 1 != nodes.size)
								walk_path_node (list_index + 1, element, result);
							else
								result.add (element);
						}
					}
				break;
			}
		}
		
		public GJson.Array match (GJson.Node root) {
			var array = new Array();
			walk_path_node (0, root, array);
			return array;
		}
		
		public static GJson.Array query (string expression, GJson.Node root) throws GLib.Error {
			var path = new Path();
			if (!path.compile (expression))
				return new Array();
			return path.match (root);
		}
	}
}
