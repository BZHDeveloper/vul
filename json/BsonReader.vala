namespace GJson {
	
	namespace Bson {
	
	}
}

namespace GJson.Bson {
	internal enum ElementType {
		END,
		DOUBLE,
		STRING,
		DOCUMENT,
		ARRAY,
		BINARY,
		UNDEFINED,
		OBJECT_ID,
		BOOLEAN,
		DATETIME,
		NULL,
		REGEX,
		DB_POINTER,
		JAVASCRIPT_CODE,
		SYMBOL,
		JAVASCRIPT_CODE_WITH_SCOPE,
		INT32,
		TIMESTAMP,
		INT64,
		FLOAT218,
		EOF = 0xFFFFFFFF;
		/*
		public string get_nick() {
			var klass = (EnumClass)typeof (BsonElementType).class_ref();
			unowned EnumValue? val = klass.get_value (this);
			if (val != null)
				return val.value_nick;
			return "(null)";
		}
		*/
	}
	
	internal class Context : GLib.Object {
		public Context (int size, ElementType element_type = ElementType.DOCUMENT) {
			GLib.Object (size : size, element_type : element_type);
		}
		
		public ElementType element_type { get; construct; }
		public int index { get; set; }
		public int size { get; construct; }
	}
	
	public class Reader : GJson.Reader {
		DataInputStream stream;
		Gee.ArrayQueue<Context> stack;
		ElementType element_type;
		TokenType token_type;
		
		public Reader (GLib.InputStream input_stream) {
			stream = new DataInputStream (input_stream);
			stream.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;
			stack = new Gee.ArrayQueue<Context>();
		}
		
		public Reader.from_path (string filename) throws GLib.Error {
			this (File.new_for_path (filename).read());
		}
		
		ElementType read_element() {
			try {
				return (ElementType)stream.read_byte();
			}
			catch {
				return ElementType.EOF;
			}
		}
		
		string read_cstring() throws GLib.Error {
			uint8[] data = new uint8[0];
			uint8 byte = 0;
			while ((byte = stream.read_byte()) != 0)
				data += byte;
			data += 0;
			return (string)data;
		}
		/*
		void read_db_pointer() throws GLib.Error {
			read_string();
			stream.read_bytes (12);
		}
		
		Bytes read_object_id() throws GLib.Error {
			return stream.read_bytes (12);
		}
		
		string read_js() throws GLib.Error {
			stream.read_int32();
			string code = read_string();
			read_object();
			return code;
		}
		
		void read_timestamp() throws GLib.Error {
			stream.read_uint64();
		}
		*/
		
		public override void read_start_object() throws GLib.Error {	
			int size = stream.read_int32() - 4;
			if (size < 4)
				throw new ReaderError.INVALID ("invalid document size.");
			stack.offer_tail (new Context (size));
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.PROPERTY_NAME;
		}
		
		public override void read_start_array() throws GLib.Error {	
			int size = stream.read_int32() - 4;
			if (size < 4)
				throw new ReaderError.INVALID ("invalid array size.");
			var context = new Context (size, ElementType.ARRAY);
			stack.offer_tail (context);
			element_type = (ElementType)stream.read_byte();
			token_type = element_to_token (element_type);
			var id = read_cstring();
			int64 i = -1;
			if (!int64.try_parse (id, out i) || i != 0)
				throw new ReaderError.INVALID ("invalid index. '0' expected but '%s' value was found.".printf (id));
			context.index = 1;
		}
		
		public override string read_string() throws GLib.Error {
			int len = stream.read_int32();
			uint8[] data = new uint8[len];
			stream.read (data);
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return (string)data;
		}
		
		public override string read_property_name() throws GLib.Error {
			token_type = TokenType.COLON;
			return read_cstring();
		}
		
		public override bool read_boolean() throws GLib.Error {
			uint8 byte = stream.read_byte();
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			if (byte > 1)
				throw new ReaderError.INVALID ("invalid byte value. '0' or '1' expected, but '%u' was found.".printf (byte));
			return byte == 1;
		}
		
		public override int64 read_integer() throws GLib.Error {
			int64 val = 0;
			if (element_type == ElementType.INT64)
				val = stream.read_int64();
			else
				val = stream.read_int32();
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return val;
		}
		
		public override double read_double() throws GLib.Error {
			double val = 0;
			if (element_type == ElementType.FLOAT218) {
				uint8[] data = new uint8[16];
				stream.read (data);
				/*
				float128* pointer = (float128*)data;
				val = (double)(*pointer);
				*/
			}
			else {
				uint8[] data = new uint8[8];
				stream.read (data);
				double* pointer = (double*)data;
				val = *pointer;
			}		
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return val;
		}
		
		public override Regex read_regex() throws GLib.Error {
			string pattern = read_cstring();
			string options = read_cstring();
			RegexCompileFlags flags = 0;
			if ("i" in options)
				flags |= RegexCompileFlags.CASELESS;
			if ("m" in options)
				flags |= RegexCompileFlags.MULTILINE;
			if ("s" in options)
				flags |= RegexCompileFlags.DOTALL;
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return new Regex (pattern, flags);
		}
		
		public override void read_null() throws GLib.Error {
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
		}
		
		public override DateTime read_datetime() throws GLib.Error {
			int64 ms = stream.read_int64();
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return new DateTime.from_unix_local (ms / 1000);
		}
		
		public override Bytes read_binary() throws GLib.Error {
			int len = stream.read_int32();
			stream.read_byte();
			var bytes = stream.read_bytes (len);
			element_type = (ElementType)stream.read_byte();
			token_type = TokenType.DELIMITER;
			if (element_type == ElementType.END)
				token_type = element_to_token (element_type);
			return bytes;
		}
		
		public override GJson.TokenType peek_token() {
			return token_type;
		}
		
		TokenType element_to_token (ElementType et) {
			if (et == ElementType.ARRAY)
				return TokenType.START_ARRAY;
			if (et == ElementType.DOCUMENT)
				return TokenType.START_OBJECT;
			if (et == ElementType.BINARY)
				return TokenType.BINARY;
			if (et == ElementType.BOOLEAN)
				return TokenType.BOOLEAN;
			if (et == ElementType.DATETIME)
				return TokenType.DATETIME;
			if (et == ElementType.DOUBLE || et == ElementType.FLOAT218)
				return TokenType.DOUBLE;
			if (et == ElementType.INT32 || et == ElementType.INT64)
				return TokenType.INTEGER;
			if (et == ElementType.JAVASCRIPT_CODE || et == ElementType.STRING || et == ElementType.SYMBOL ||
			et == ElementType.JAVASCRIPT_CODE_WITH_SCOPE)
				return TokenType.STRING;
			if (et == ElementType.REGEX)
				return TokenType.REGEX;
			if (et == ElementType.NULL || et == ElementType.UNDEFINED)
				return TokenType.NULL;
			if (et == ElementType.END) {
				var context = stack.peek_tail();
				if (context != null) {
					if (context.element_type == ElementType.DOCUMENT)
						return TokenType.END_OBJECT;
					return TokenType.END_ARRAY;
				}
			}
			return TokenType.NONE;
		}
		
		public override GJson.TokenType read_token() throws GLib.Error {
			if (token_type == TokenType.EOF)
				return token_type;
			var tt = token_type;
			if (tt == TokenType.COLON) {
				token_type = element_to_token (element_type);
				return tt;
			}
			if (tt == TokenType.END_ARRAY || tt == TokenType.END_OBJECT) {
				stack.poll_tail();
				element_type = read_element();
				token_type = TokenType.DELIMITER;
				if (element_type == ElementType.EOF)
					token_type = TokenType.EOF;
				else if (element_type == ElementType.END)
					token_type = element_to_token (element_type);
				return tt;
			}
			else if (tt == TokenType.DELIMITER) {
				token_type = element_to_token (element_type);
				if (stack.peek_tail() != null && stack.peek_tail().element_type == ElementType.ARRAY) {
					var context = stack.peek_tail();
					var id = read_cstring();
					int64 i = -1;
					int64 index = context.index;
					if (!int64.try_parse (id, out i) || i != index)
						throw new ReaderError.INVALID ("invalid index. '%lld' expected but '%s' value was found.".printf (index, id));
					context.index = context.index + 1;
				}
			}
			return tt;
		}
	}
}
