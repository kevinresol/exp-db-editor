package;

import mui.core.*;
import exp.db.app.ui.view.DatabaseView;
import exp.db.app.data.DatabaseModel;
import electron.renderer.IpcRenderer;

using haxe.io.Path;
using sys.io.File;
using tink.CoreApi;

class Main extends coconut.react.View {
	static function main() {
		var div = js.Browser.document.createDivElement();
		js.Browser.document.body.appendChild(div);
		coconut.react.Renderer.mount(div, '<Main/>');
		
	}
	
	@:state var database:DatabaseModel = null;
	
	var path:String;
	
	function render() '
		<>
			<switch ${database}>
				<case ${null}>
					<Button variant=${Contained} color=${Primary} onClick=${() -> database = new DatabaseModel()}>New</Button>
					<Button variant=${Contained} color=${Primary} onClick=${load}>Load</Button>
				<case ${db}>
					<DatabaseView database=${db} onSave=${save}/>
			</switch>
		</>
	';
	
	override function viewDidMount() {
		// handle Ctrl+S / Cmd+S keyboard shortcut from electron
		untilUnmounted({
			IpcRenderer.on('command', function onCommand(event, data) {
				if(data == 'save') {
					if(database != null) save();
				}
			});
			IpcRenderer.removeListener.bind('command', onCommand);
		});
	}
	
	function load() {
		selectDirectory()
			.next(path -> {
				this.path = path;
				Error.catchExceptions(() -> {
					DatabaseModel.fromRaw({
						schema: Path.join([path, 'schema.json']).getContent(),
						content: Path.join([path, 'content.json']).getContent(),
					});
				}).flatten();
			})
			.next(db -> {
				database = db;
				Noise;
			})
			.handle(why.Toast.inst.outcome.bind(_, 'Database Loaded', Short));
	}
	
	function save() {
		(path == null ? selectDirectory() : Promise.resolve(path))
			.next(path -> {
				final raw = database.toRaw();
				Error.catchExceptions(() -> {
					Path.join([path, 'schema.json']).saveContent(raw.schema);
					Path.join([path, 'content.json']).saveContent(raw.content);
					Noise;
				});
			})
			.handle(why.Toast.inst.outcome.bind(_, 'Database Saved', Short));
	}
	
	
	static function selectDirectory() {
		return Promise.ofJsPromise(electron.remote.Dialog.showOpenDialog({properties: ['openDirectory']}))
			.next(v -> {
				final o:DialogResult = v;
				!o.canceled ? Promise.resolve(o.filePaths[0]) : new Error('cancelled');
			});
	}
}

private typedef DialogResult = {
	canceled:Bool,
	filePaths:Array<String>,
}