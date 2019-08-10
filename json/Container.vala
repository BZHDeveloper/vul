namespace GJson {
	public abstract class Item : GLib.Object, Gee.Hashable<GJson.Item> {
		public abstract new GJson.Node get (GLib.Value index);
		
		public abstract string to_string();
		
		public virtual bool equal_to (GJson.Item item) {
			return str_equal (to_string(), item.to_string());
		}
		
		public virtual uint hash() {
			return str_hash (to_string());
		}
	}
	
	public abstract class Container<G> : Gee.AbstractCollection<G>, Gee.Hashable<Container> {
		public new abstract GJson.Node get (GLib.Value index);
		
		public abstract bool equal_to (Container container);
		
		public abstract string to_string();
		
		public uint hash() {
			return str_hash (to_string());
		}
		
		public abstract GJson.Container parent { get; }
		
		public abstract Gee.Collection<Item> children { owned get; } 
		
		public abstract string path { owned get; }
	}
}
