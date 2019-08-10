namespace GJson {
	internal class TokenValue : GLib.Object {
		public TokenValue (GJson.TokenType token_type = GJson.TokenType.NONE) {
			GLib.Object (token_type : token_type);
		}
		
		public int64 integer { get; set; }
		
		public bool boolean { get; set; }
		
		public double number { get; set; }
		
		public string identifier { get; set; }
		
		public string str { get; set; }
		
		public GJson.TokenType token_type { get; set construct; }
	}
	
	public class TextReader : Reader {
		GText.TextReader reader;
		TokenValue token;
		TokenValue next_token;
		
		public bool decode_unicode { get; set; }
		public bool unescape { get; set; }
		
		public TextReader (GText.Reader text_reader) {
			this.reader = new GText.TextReader (text_reader);
			token = get_next_token();
			next_token = get_next_token (token);
			decode_unicode = true;
			unescape = true;
		}
		
		public TextReader.from_string (string json) {
			this (new GText.StringReader (json));
		}
		
		public TextReader.from_stream (InputStream stream, GText.Encoding encoding = GText.Encoding.utf8) throws GLib.Error {
			this (new GText.StreamReader (stream, encoding));
		}
		
		string read_str() throws GLib.Error {
			if (reader.peek() != '"')
				throw new ReaderError.INVALID ("GJson.TextReader.read_string() : invalid character '%s' at line %d, column %d.".printf (reader.peek().to_string(), reader.line, reader.column));
			StringBuilder builder = new StringBuilder();
			reader.read();
			while (!reader.eof) {
				if (reader.peek() == '"') {
					reader.read();
					if (unescape)
						return builder.str.compress();
					return builder.str;
				}
				else if (reader.peek() == '\\') {
					reader.read();
					if (reader.eof)
						throw new ReaderError.NULL ("GJson.TextReader.read_string() : end of file.");
					unichar u = reader.read();
					if (u == 'u' && decode_unicode) {
						unichar a = reader.read();
						if (a == 0)
							throw new ReaderError.EOF ("end of file");
						unichar b = reader.read();
						if (b == 0)
							throw new ReaderError.EOF ("end of file");
						unichar c = reader.read();
						if (c == 0)
							throw new ReaderError.EOF ("end of file");
						unichar d = reader.read();
						if (d == 0)
							throw new ReaderError.EOF ("end of file");
						string s = "0x%s%s%s%s".printf (a.to_string(), b.to_string(), c.to_string(), d.to_string());
						int64 i = 0;
						if (!int64.try_parse (s, out i))
							throw new ReaderError.INVALID ("invalid unicode character");
						builder.append_unichar ((unichar)i);
					}
					else {
						builder.append_unichar ('\\');
						builder.append_unichar (u);
					}
				}
				else if (reader.peek() == '\r' || reader.peek() == '\n')
					throw new ReaderError.INVALID ("current string is truncated.");
				else {
					builder.append_unichar (reader.read());
				}
			}
			return "";
		}
		
		TokenValue get_next_token (TokenValue? prev_token = null) {
			while (reader.peek().isspace())
				reader.read();
			if (reader.peek() == 0)
				return new TokenValue (TokenType.EOF);
			if (reader.peek() == '{') {
				reader.read();
				return new TokenValue (TokenType.START_OBJECT);
			}
			if (reader.peek() == '[') {
				reader.read();
				return new TokenValue (TokenType.START_ARRAY);
			}
			if (reader.peek() == '}') {
				reader.read();
				return new TokenValue (TokenType.END_OBJECT);
			}
			if (reader.peek() == ']') {
				reader.read();
				return new TokenValue (TokenType.END_ARRAY);
			}
			if (reader.peek() == ',') {
				reader.read();
				return new TokenValue (TokenType.DELIMITER);
			}
			if (reader.peek() == ':') {
				if (prev_token != null && prev_token.token_type == TokenType.STRING)
					prev_token.token_type = TokenType.PROPERTY_NAME;
				reader.read();
				return new TokenValue (TokenType.COLON);
			}
			if (reader.peek() == '"') {
				try {
					TokenValue tv = new TokenValue (TokenType.STRING);
					tv.str = read_str();
					return tv;
				}
				catch {
					return new TokenValue();
				}
			}
			StringBuilder builder = new StringBuilder();
			while (reader.peek() == '+' || reader.peek() == '-' || reader.peek() == '.' || reader.peek().isalnum())
				builder.append_unichar (reader.read());
			bool b = false;
			double d = 0;
			int64 i = 0;
			if (int64.try_parse (builder.str, out i)) {
				TokenValue tv = new TokenValue (TokenType.INTEGER);
				tv.integer = i;
				return tv;
			}
			if (double.try_parse (builder.str, out d)) {
				TokenValue tv = new TokenValue (TokenType.DOUBLE);
				tv.number = d;
				return tv;
			}
			if (bool.try_parse (builder.str, out b)) {
				TokenValue tv = new TokenValue (TokenType.BOOLEAN);
				tv.boolean = b;
				return tv;
			}
			if (builder.str == "null")
				return new TokenValue (TokenType.NULL);
			return new TokenValue();
		}
		
		public override GJson.TokenType peek_token() {
			return token.token_type;
		}
		
		public override GJson.TokenType read_token() {
			var tt = token.token_type;
			token = next_token;
			next_token = get_next_token (token);
			return tt;
		}
		
		public override void read_start_object() throws GLib.Error {
			if (token.token_type != TokenType.START_OBJECT)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'start-object' expected.".printf (token.token_type.get_nick()));
			read_token();
		}
		
		public override void read_start_array() throws GLib.Error {
			if (token.token_type != TokenType.START_ARRAY)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'start-array' expected.".printf (token.token_type.get_nick()));
			read_token();
		}
		
		public override string read_property_name() throws GLib.Error {
			if (token.token_type != TokenType.PROPERTY_NAME)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'property-name' expected.".printf (token.token_type.get_nick()));
			string name = token.str;
			read_token();
			return name;
		}
		
		public override string read_string() throws GLib.Error {
			if (token.token_type != TokenType.STRING)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'string' expected.".printf (token.token_type.get_nick()));
			string str = token.str;
			read_token();
			return str;
		}
		
		public override double read_double() throws GLib.Error {
			if (token.token_type != TokenType.DOUBLE)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'double' expected.".printf (token.token_type.get_nick()));
			double val = token.number;
			read_token();
			return val;
		}
		
		public override int64 read_integer() throws GLib.Error {
			if (token.token_type != TokenType.INTEGER)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'integer' expected.".printf (token.token_type.get_nick()));
			int64 val = token.integer;
			read_token();
			return val;
		}
		
		public override bool read_boolean() throws GLib.Error {
			if (token.token_type != TokenType.BOOLEAN)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'boolean' expected.".printf (token.token_type.get_nick()));
			bool val = token.boolean;
			read_token();
			return val;
		}
		
		public override void read_null() throws GLib.Error {
			if (token.token_type != TokenType.NULL)
				throw new ReaderError.TOKEN ("invalid '%s' token, 'null' expected.".printf (token.token_type.get_nick()));
			read_token();
		}
	}
}
