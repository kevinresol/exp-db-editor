package;

import electron.main.MenuItem;
import js.Node;
import js.Node.__dirname;
import electron.main.App;
import electron.main.Menu;
import electron.main.BrowserWindow;

class Electron {

	static function main() {

		App.on(ready, function(e) {

			var win = new BrowserWindow( {
				width: 1440, height: 900,
				webPreferences: {
					enableRemoteModule: true,
					nodeIntegration: true,
				}
			} );
			win.on(closed, function() {
				win = null;
			});
			win.loadFile( 'app.html' );
			//win.webContents.openDevTools();

			// var tray = new Tray( '${__dirname}/icon-192.png' );
			
			
			
			var menu = Menu.getApplicationMenu();
			var items:Array<MenuItem> = (cast menu).items;
			
			for(item in items) {
				if(item.label == 'File') {
					item.submenu.insert(0, new MenuItem({
						label: 'Save',
						accelerator: 'CmdOrCtrl+S',
						click: () -> win.webContents.send('command', 'save'),
					}));
				}
			}
			
			Menu.setApplicationMenu(menu);
		});

		App.on(window_all_closed, function(e) {
			App.quit();
		});
		
	}

}