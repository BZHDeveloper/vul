namespace Gcl {
	public class Entries : Gee.AbstractList<Gcl.Entry> {
		public signal void added (Gcl.Entry entry);
		public signal void changed (Gcl.Entry entry, int index);
		public signal void inserted (Gcl.Entry entry, int index);
		public signal void removed (Gcl.Entry entry, int index);
		
		Gee.ArrayList<Entry> list;
		
		construct {
			list = new Gee.ArrayList<Entry>();
		}
		
		public override bool add (Gcl.Entry entry) {
			for (var i = list.size - 1; i >= 0; i--)
				if (list[i].name == entry.name)
					list.remove_at (i);
			added (entry);
			return list.add (entry);
		}
		
		public override void clear() {
			while (list.size > 0)
				remove_at (0);
		}
		
		public override bool contains (Gcl.Entry entry) {
			return index_of (entry) > -1;
		}
		
		public override Gcl.Entry get (int index) {
			return list[index];
		}
		
		public override int index_of (Gcl.Entry entry) {
			return list.index_of (entry);
		}
		
		public override void insert (int index, Gcl.Entry entry) {
			if (index < 0 || index >= list.size)
				return;
			for (var i = list.size - 1; i >= 0; i--)
				if (list[i].name == entry.name)
					list.remove_at (i);
			inserted (entry, index);
			list.insert (index, entry);
		}
		
		public override Gee.Iterator<Gcl.Entry> iterator() {
			return list.iterator();
		}
		
		public override Gee.ListIterator<Gcl.Entry> list_iterator() {
			return list.list_iterator();
		}
		
		public override bool remove (Gcl.Entry entry) {
			int index = list.index_of (entry);
			if (index < 0)
				return false;
			removed (entry, index);
			return list.remove (entry);
		}
		
		public override Gcl.Entry remove_at (int index) {
			if (index < 0 || index >= list.size)
				return null;
			var entry = list.remove_at (index);
			removed (entry, index);
			return entry;
		}
		
		public override void set (int index, Gcl.Entry entry) {
			if (index < 0 || index >= list.size)
				return;
			for (var i = list.size - 1; i >= 0; i--)
				if (list[i].name == entry.name)
					list.remove_at (i);
			changed (entry, index);
			list[index] = entry;
		}
		
		public override Gee.List<Gcl.Entry>? slice (int start, int stop) {
			var res = list.slice (start, stop);
			var entries = new Entries();
			if (list != null)
				entries.add_all (res);
			return entries;
		}
		
		public override bool read_only {
			get {
				return false;
			}
		}
		
		public override int size {
			get {
				return list.size;
			}
		}
	}
}
