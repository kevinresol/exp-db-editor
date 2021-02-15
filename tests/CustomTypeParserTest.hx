package;

import exp.db.util.ValueParser;
import exp.db.Value;
import exp.db.ValueType;
import exp.db.CustomType;
import exp.db.CustomValue;
import tink.pure.Vector;


@:asserts
class CustomTypeParserTest {
	final SOURCE1 = '
		enum Effect {
			Grow(attr:Attribute, value:Value);
			Combined(e1:Effect, e2:Effect);
		}
		enum Attribute{
			Str;
			Agi;
			Int;
			Hp;
		}
		enum Value {
			Fixed(v:Int);
			Random(base:Int, threshold:Int, low:Int, high:Int);
		}
	';
	
	
	public function new() {}
	
	public function parse() {
		return switch exp.db.app.util.CustomTypeParser.parse(SOURCE1) {
			case Success(v):
				asserts.assert(v.length == 3);
				asserts.assert(v.exists(type -> type.name == 'Effect'));
				asserts.assert(v.exists(type -> type.name == 'Attribute'));
				asserts.assert(v.exists(type -> type.name == 'Value'));
				asserts.done();
			case Failure(e):
				asserts.fail(e);
		}
	}
}