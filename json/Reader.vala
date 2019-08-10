[CCode (gir_namespace = "GJson", gir_version = "1.0")]
namespace GJson {}

namespace GJson {
	public enum TokenType {
		EOF,
		NONE,
		DELIMITER,
		START_OBJECT,
		START_ARRAY,
		END_OBJECT,
		END_ARRAY,
		PROPERTY_NAME,
		COLON,
		INTEGER,
		DOUBLE,
		STRING,
		BOOLEAN,
		NULL,
		REGEX,
		DATETIME,
		BINARY;
		
		public string get_nick() {
			var klass = (EnumClass)typeof (TokenType).class_ref();
			unowned EnumValue? val = klass.get_value (this);
			if (val != null)
				return val.value_nick;
			return "(null)";
		}
	}
	
	public errordomain ReaderError {
		NULL,
		INVALID,
		TYPE,
		TOKEN,
		EOF,
		LENGTH
	}
	
	public abstract class Reader : GLib.Object {
		public abstract string read_property_name() throws GLib.Error;
		public abstract string read_string() throws GLib.Error;
		public abstract void read_null() throws GLib.Error;
		public abstract bool read_boolean() throws GLib.Error;
		public abstract double read_double() throws GLib.Error;
		public abstract int64 read_integer() throws GLib.Error;
		public abstract void read_start_array() throws GLib.Error;
		public abstract void read_start_object() throws GLib.Error;
		public abstract GJson.TokenType read_token() throws GLib.Error;
		public abstract GJson.TokenType peek_token();
		
		public virtual Bytes read_binary() throws GLib.Error {
			return new Bytes (new uint8[0]);
		}
		
		public virtual DateTime read_datetime() throws GLib.Error {
			return new DateTime.now_local();
		}
		
		public virtual Regex read_regex() throws GLib.Error {
			return new Regex ("");
		}
		
		public GJson.Node read_node() throws GLib.Error {
			if (peek_token() == GJson.TokenType.START_ARRAY)
				return new GJson.Node (read_array());
			if (peek_token() == GJson.TokenType.START_OBJECT)
				return new GJson.Node (read_object());
			if (peek_token() == GJson.TokenType.STRING)
				return new GJson.Node (read_string());
			if (peek_token() == GJson.TokenType.BOOLEAN)
				return new GJson.Node (read_boolean());
			if (peek_token() == GJson.TokenType.DOUBLE)
				return new GJson.Node (read_double());
			if (peek_token() == GJson.TokenType.INTEGER)
				return new GJson.Node (read_integer());
			if (peek_token() == GJson.TokenType.NULL) {
				read_null();
				return new GJson.Node (null);
			}
			if (peek_token() == GJson.TokenType.DATETIME)
				return new GJson.Node (read_datetime());
			if (peek_token() == GJson.TokenType.REGEX)
				return new GJson.Node (read_regex());
			if (peek_token() == GJson.TokenType.BINARY)
				return new GJson.Node (read_binary());
			throw new ReaderError.TOKEN ("GJson.Reader.read_node : invalid '%s' token.".printf (peek_token().get_nick()));
			return new GJson.Node (null);
		}
		
		public GJson.Object read_object() throws GLib.Error {
			read_start_object();
			var object = new Object();
			while (peek_token() != TokenType.END_OBJECT) {
				string id = read_property_name();
				if (peek_token() != TokenType.COLON)
					throw new ReaderError.TOKEN ("GJson.Reader.read_object : Invalid token. 'colon' expected but '%s' was found.".printf (peek_token().get_nick()));
				read_token();
				object[id] = read_node();
				if (peek_token() != TokenType.DELIMITER && peek_token() != TokenType.END_OBJECT)
					throw new ReaderError.TOKEN ("GJson.Reader.read_object : invalid end of object member. '%s' token was found.".printf (peek_token().get_nick()));
				if (peek_token() == TokenType.DELIMITER)
					read_token();
			}
			read_token();
			return object;
		}
		
		public GJson.Array read_array() throws GLib.Error {
			read_start_array();
			var array = new Array();
			while (peek_token() != TokenType.END_ARRAY) {
				var node = read_node();
				array.add (node);
				if (peek_token() != TokenType.DELIMITER && peek_token() != TokenType.END_ARRAY)
					throw new ReaderError.TOKEN ("GJson.Reader.read_array : invalid end of array element. '%s' token was found.".printf (peek_token().get_nick()));
				if (peek_token() == TokenType.DELIMITER)
					read_token();
			}
			read_token();
			return array;
		}
	}
}
