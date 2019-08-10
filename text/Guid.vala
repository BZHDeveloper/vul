namespace GText {
	public class Guid : Gee.Hashable<Guid>, Gee.Comparable<Guid>, GLib.Object {
		public enum Format {
			N,
			D,
			B,
			P,
			X;
			
			public bool has_hyphen() {
				return this == Format.D || this == Format.B || this == Format.P;
			}
		}
		
		static Gee.HashSet<Guid> guids;
		
		public static Guid empty = new Guid (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		
		static Guid random() {
			int a = Random.int_range (0, int.MAX);
			short b = (short)Random.int_range (0, (int)short.MAX);
			short c = (short)Random.int_range (0, (int)short.MAX);
			uint8 d = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 e = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 f = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 g = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 h = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 i = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 j = (uint8)Random.int_range (0, (int)uint8.MAX);
			uint8 k = (uint8)Random.int_range (0, (int)uint8.MAX);
			return new Guid (a, b, c, d, e, f, g, h, i, j, k);
		}
		
		public static Guid next_guid() {
			if (guids == null)
				guids = new Gee.HashSet<Guid>();
			Guid guid = random();
			while (guids.contains (guid))
				guid = random();
			guids.add (guid);
			return guid;
		}
		
		internal class Parser : GText.StringReader {
			public Parser (string str) {
				GLib.Object (text : str);
			}
			
			public bool parse_hex_prefix() {
				while (peek() == '0' || peek().isspace()) {
					if (peek() == '0') {
						read();
						return read() == 'x';
					}
				}
				return false;
			}
			
			public bool parse_char_with_spaces (unichar u) {
				while (!this.eof) {
					var c = read();
					if (c == u)
						return true;
					if (!c.isspace())
						return false;
				}
				return false;
			}
		
			public bool parse_char (unichar u) {
				if (!this.eof && peek() == u) {
					read();
					return true;
				}
				return false;
			}
			
			public bool parse_hex (int length, bool strict, out int64 res) {
				res = 0;
				for (int i = 0; i < length; i++) {
					if (this.eof)
						return !(strict && (i + 1 != length));
					unichar c = peek();
					if (c.isdigit()) {
						res = res * 16 + c - '0';
						read();
						continue;
					}
					if (c >= 'a' && c <= 'f') {
						res = res * 16 + c - 'a' + 10;
						read();
						continue;
					}
					if (c >= 'A' && c <= 'F') {
						res = res * 16 + c - 'A' + 10;
						read();
						continue;
					}
					if (!strict)
						return true;
					return false;
				}
				return true;
			}
		
			public bool try_parse_x (out Guid guid) {
				this.position = 0;
				guid = Guid.empty;
				int64 a = 0, b = 0, c = 0;
				
				if (!(parse_char ('{') &&
					parse_hex_prefix() &&
					parse_hex (8, false, out a) &&
					parse_char_with_spaces (',') &&
					parse_hex_prefix() &&
					parse_hex (4, false, out b) &&
					parse_char_with_spaces (',') &&
					parse_hex_prefix() &&
					parse_hex (4, false, out c) &&
					parse_char_with_spaces (',') &&
					parse_char_with_spaces ('{')))
						return false;
				
				var d = new uint8[8];
				for (int i = 0; i < 8; i++) {
					int64 dd = 0;
					if (!(parse_hex_prefix() && parse_hex (2, false, out dd)))
						return false;
					d[i] = (uint8)dd;
					if (i != 7 && !parse_char_with_spaces (','))
						return false;
				}
				if (!(parse_char_with_spaces ('}') && parse_char_with_spaces ('}')))
					return false;
				if (!this.eof)
					return false;
				guid = new Guid ((int)a, (short)b, (short)c, (uint8)d[0], (uint8)d[1], (uint8)d[2], (uint8)d[3], (uint8)d[4], (uint8)d[5], (uint8)d[6], (uint8)d[7]);
				return true;
			}
		
			public bool try_parse_ndbp (Format format, out Guid guid) {
				guid = Guid.empty;
				this.position = 0;
				int64 a = 0, b = 0, c = 0;
				if (format == Format.B && !parse_char ('{'))
					return false;
				if (format == Format.P && !parse_char ('('))
					return false;
				if (!parse_hex (8, true, out a))
					return false;
				if (format.has_hyphen() && !parse_char ('-'))
					return false;
				if (!parse_hex (4, true, out b))
					return false;
				if (format.has_hyphen() && !parse_char ('-'))
					return false;
				if (!parse_hex (4, true, out c))
					return false;
				if (format.has_hyphen() && !parse_char ('-'))
					return false;
				var d = new uint8[8];
				for (int i = 0; i < 8; i++) {
					int64 dd;
					if (!parse_hex (2, true, out dd))
						return false;
					if (i == 1 && format.has_hyphen() && !parse_char ('-'))
						return false;
					d[i] = (uint8)dd;
				}
				if (format == Format.B && !parse_char ('}'))
					return false;
				if (format == Format.P && !parse_char (')'))
					return false;
				if (!this.eof)
					return false;
				guid = new Guid ((int)a, (short)b, (short)c, (uint8)d[0], (uint8)d[1], (uint8)d[2], (uint8)d[3], (uint8)d[4], (uint8)d[5], (uint8)d[6], (uint8)d[7]);
				return true;
			}
		}
		
		public static bool try_parse (string str, out Guid guid) {
			guid = Guid.empty;
			var parser = new Parser (str.strip());
			if (parser.text.length == 32)
				if (parser.try_parse_ndbp (Format.N, out guid))
					return true;
			if (parser.text.length == 36)
				if (parser.try_parse_ndbp (Format.D, out guid))
					return true;
			if (parser.text.length == 38)
				if (parser.text[0] == '{') {
					if (parser.try_parse_ndbp (Format.B, out guid))
						return true;
				}
				else if (parser.text[0] == '(') {
					if (parser.try_parse_ndbp (Format.P, out guid))
						return true;
				}
			return parser.try_parse_x (out guid);
		}
		
		public static Guid parse (string str) {
			Guid guid = null;
			if (!try_parse (str, out guid))
				return Guid.empty;
			return guid;
		}
		
		int a;
		short b;
		short c;
		uint8 d;
		uint8 e;
		uint8 f;
		uint8 g;
		uint8 h;
		uint8 i;
		uint8 j;
		uint8 k;
		
		public Guid (int a, short b, short c, uint8 d, uint8 e, uint8 f, uint8 g, uint8 h, uint8 i, uint8 j, uint8 k) {
			this.a = a;
			this.b = b;
			this.c = c;
			this.d = d;
			this.e = e;
			this.f = f;
			this.g = g;
			this.h = h;
			this.i = i;
			this.j = j;
			this.k = k;
		}
		
		public uint8[] to_array() {
			var result = new uint8[16];
			uint8* data = (uint8*)(&(this.a));
			for (var i = 0; i < 4; i++)
				result[i] = data[BYTE_ORDER == ByteOrder.BIG_ENDIAN ? i : 3 - i];
			data = (uint8*)(&(this.b));
			for (var i = 0; i < 2; i++)
				result[i + 4] = data[BYTE_ORDER == ByteOrder.BIG_ENDIAN ? i : 1 - i];
			data = (uint8*)(&(this.c));
			for (var i = 0; i < 2; i++)
				result[i + 4] = data[BYTE_ORDER == ByteOrder.BIG_ENDIAN ? i : 1 - i];
			result[8] = this.d;
			result[9] = this.e;
			result[10] = this.f;
			result[11] = this.g;
			result[12] = this.h;
			result[13] = this.i;
			result[14] = this.j;
			result[15] = this.k;
			return result;
		}
		
		public void copy (Guid source) {
			var array = source.to_array();
			uint8[] aa = new uint8[]{ array[0], array[1], array[2], array[3] };
			if (BYTE_ORDER == ByteOrder.BIG_ENDIAN)
				aa = new uint8[] { array[3], array[2], array[1], array[0] };
			uint8[] ab = new uint8[]{ array[4], array[5] };
			if (BYTE_ORDER == ByteOrder.BIG_ENDIAN)
				ab = new uint8[]{ array[5], array[4] };
			uint8[] ac = new uint8[]{ array[6], array[7] };
			if (BYTE_ORDER == ByteOrder.BIG_ENDIAN)
				ac = new uint8[]{ array[7], array[6] };
			int* pa = (int*)((uint8*)aa);
			short* pb = (short*)((uint8*)ab);
			short* pc = (short*)((uint8*)ac);
			this.a = *pa;
			this.b = *pb;
			this.c = *pc;
			this.d = array[8];
			this.e = array[9];
			this.f = array[10];
			this.g = array[11];
			this.h = array[12];
			this.i = array[13];
			this.j = array[14];
			this.k = array[15];
		}
		
		static char to_hex (int val) {
			return (char)((val < 0xA) ? ('0' + val) : ('a' + val - 0xA));
		}
		
		static void append_int (StringBuilder builder, int val) {
			builder.append_c (to_hex ((val >> 28) & 0xF));
			builder.append_c (to_hex ((val >> 24) & 0xF));
			builder.append_c (to_hex ((val >> 20) & 0xF));
			builder.append_c (to_hex ((val >> 16) & 0xF));
			builder.append_c (to_hex ((val >> 12) & 0xF));
			builder.append_c (to_hex ((val >> 8) & 0xF));
			builder.append_c (to_hex ((val >> 4) & 0xF));
			builder.append_c (to_hex (val & 0xF));
		}
		
		static void append_short (StringBuilder builder, short val) {
			builder.append_c (to_hex ((val >> 12) & 0xF));
			builder.append_c (to_hex ((val >> 8) & 0xF));
			builder.append_c (to_hex ((val >> 4) & 0xF));
			builder.append_c (to_hex (val & 0xF));
		}
		
		static void append_byte (StringBuilder builder, uint8 val) {
			builder.append_c (to_hex ((val >> 4) & 0xF));
			builder.append_c (to_hex (val & 0xF));
		}
		
		public string to_string (Format format = Format.D) {
			var builder = new StringBuilder();
			if (format == Format.P)
				builder.append ("(");
			else if (format == Format.B)
				builder.append ("{");
			else if (format == Format.X)
				builder.append ("{0x");
			append_int (builder, this.a);
			if (format.has_hyphen())
				builder.append ("-");
			else if (format == Format.X)
				builder.append (",0x");
			append_short (builder, this.b);
			if (format.has_hyphen())
				builder.append ("-");
			else if (format == Format.X)
				builder.append (",0x");
			append_short (builder, this.c);
			if (format.has_hyphen())
				builder.append ("-");
			if (format == Format.X) {
				builder.append (",{0x");
				append_byte (builder, this.d);
				builder.append (",0x");
				append_byte (builder, this.e);
				builder.append (",0x");
				append_byte (builder, this.f);
				builder.append (",0x");
				append_byte (builder, this.g);
				builder.append (",0x");
				append_byte (builder, this.h);
				builder.append (",0x");
				append_byte (builder, this.i);
				builder.append (",0x");
				append_byte (builder, this.j);
				builder.append (",0x");
				append_byte (builder, this.k);
				builder.append ("}}");
			} else {
				append_byte (builder, this.d);
				append_byte (builder, this.e);
				if (format.has_hyphen())
					builder.append ("-");
				append_byte (builder, this.f);
				append_byte (builder, this.g);
				append_byte (builder, this.h);
				append_byte (builder, this.i);
				append_byte (builder, this.j);
				append_byte (builder, this.k);
				if (format == Format.P)
					builder.append (")");
				else if (format == Format.B)
					builder.append ("}");
			}
			return builder.str;
		}
		
		public uint hash() {
			return str_hash (to_string());
		}
		
		public bool equal_to (Guid guid) {
			return str_equal (to_string(), guid.to_string());
		}
		
		public int compare_to (Guid guid) {
			return strcmp (to_string(), guid.to_string());
		}
	}
}
