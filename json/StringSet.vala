namespace GJson {
	public class StringSet : Gee.AbstractSet<string> {
		Gee.ArrayList<string> list;
		
		construct {
			list = new Gee.ArrayList<string>();
		}
		
		public override bool add (string str) {
			while (list.contains (str))
				list.remove (str);
			return list.add (str);
		}
		
		public override void clear() {
			list.clear();
		}
		
		public override bool contains (string str) {
			return list.contains (str);
		}
		
		public new string get (int index) {
			return list[index];
		}
		
		public override Gee.Iterator<string> iterator() {
			return list.iterator();
		}
		
		public override bool remove (string str) {
			return list.remove (str);
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
