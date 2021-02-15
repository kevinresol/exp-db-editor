# Experimental Game Database Editor

GUI editor for https://github.com/kevinresol/exp-db

## Demo

Some demo video clips can be found here: https://twitter.com/kevinresol/status/1278713601004453888

## How to build and run the electron editor

- `yarn global add lix`
- `lix download`
- `haxe build-app.hxml && haxe build-electron.hxml`
- `pushd bin/electron && yarn && popd`
- `yarn start`

## How to embed the editor in a Haxe/Javascript project

- Install this library
- Render `exp.db.app.ui.view.DatabaseView` (see electron/Main.hx for an example)

Note: this should work for both web and electron-alike
