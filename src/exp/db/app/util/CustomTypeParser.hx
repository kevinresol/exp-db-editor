package exp.db.app.util;

import exp.db.CustomType;
import tink.pure.Vector;

using tink.CoreApi;

class CustomTypeParser {
	public static function parse(source:String):Outcome<Vector<CustomType>, Error> {
		return Error.catchExceptions(() -> {
			var e = new haxeparser.HaxeParser(byte.ByteData.ofString(source), '').parse();
			final typedefs = e.decls.map(v -> haxeparser.DefinitionConverter.convertTypeDef([], v.decl)).filter(v -> v.kind == TDEnum);
			([for(def in typedefs) (def:CustomType)]:Vector<CustomType>);
		});
	}
}