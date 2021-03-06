package exp.db.app.ui.component;

import exp.db.app.data.DatabaseModel;
import exp.db.Value;
import exp.db.ValueType;
import haxe.DynamicAccess;
import mui.core.*;
import mui.core.styles.Styles.*;
import mui.lab.*;
import externs.DataSheet;
import tink.Anon.merge;

enum CellValue {
	Header(v:String);
	Invalid(v:String, reason:String);
	Value(v:Value);
	Empty;
}

@:pure
enum ContextMenu {
	Column(index:Int, x:Int, y:Int);
	Row(index:Int, x:Int, y:Int);
}
	
// @:react.hoc(withStyles(styles))
class Sheet extends View {
	@:attr var tableNames:Vector<String>;
	@:attr var typeNames:Vector<String>;
	@:attr var getCustomType:String->Outcome<CustomType, Error>;
	
	@:attr var columns:ObservableArray<Column>;
	@:attr var rows:ObservableArray<ObservableMap<String, Content>>;
	@:attr var depth:Int = 0;
	
	@:state var contextMenu:ContextMenu = null;
	@:state var showColumnAdder:Bool = false;
	@:state var disablePageClick:Bool = false;
	
	@:computed var columnList:Vector<Column> = [for(column in columns.values()) column];
	
	@:skipCheck @:computed var header:Array<Cell<CellValue>> = {
		var ret = [{value: Header(''), readOnly: true, disableUpdatedFlag: true}];
		for(column in columns.values())
			ret.push({
				value: Header('${column.name} (${column.type.getName()})'),
				readOnly: true, disableUpdatedFlag: true,
			});
		ret;
	}
	
	@:skipCheck @:computed var footer:Array<Cell<CellValue>> = {
		var ret:Array<Cell<CellValue>> = [{value: Header(''), readOnly: true, disableUpdatedFlag: true}];
		for(column in columns.values())
			ret.push({value: Empty, disableUpdatedFlag: true});
		ret;
	}
	
	@:skipCheck @:computed var data:Array<Array<Cell<CellValue>>> = {
		typeNames; // make it depends on types, so this data will be re-evaluated when types changed
		
		var ret = [header];
		for(r in 0...rows.length) {
			var row:Array<Cell<CellValue>> = [{value: Header('$r'), readOnly: true, disableUpdatedFlag: true}];
			for(column in columns.values()) {
				var content = rows.get(r).get(column.name);
				
				row.push({
					disableUpdatedFlag: true,
					value: switch content {
						case null:
							Invalid('', 'Empty');
						case v if(v.interim != null):
							Invalid(v.interim.value, v.interim.error);
						case {value: null}:
							Invalid('', 'Empty');
						case v:
							switch column.type.validateValue(v.value, getCustomType) {
								case Success(_): Value(v.value);
								case Failure(e): Invalid(valueToString(Value(v.value)), e.data == null ? e.message : Std.string(e.data));
							}
					},
					component: switch content {
						case null | {value: null}: null;
						case {value: Boolean(v)}: hxx('
							<Switch
								checked=${v}
								size=${Small}
								color=${Primary}
								onChange=${e -> rows.get(r).set(column.name, exp.db.Value.Boolean((cast e.target).checked))}
							/>
						');
						case _: null;
					},
					forceComponent: switch content {
						case null | {value: null}: false;
						case {value: Boolean(_)}: true;
						case _: false;
					},
				});
			}
			ret.push(row);
		}
		ret.push(footer);
		ret;
	}
	
	
	
	// @:react.injected var classes:{
	// 	table:String,
	// };
	
	// static function styles(theme) return {
	// 	table: {
			
	// 	},
	// }
	
	static final CONTAINER = css('
		& * {
			box-sizing: initial;
		}
		& .data-grid-container {
			& table.data-grid {
				margin: auto;
				width: 100%;
				
				& tr:first-child td:first-child {
					width: 40px;
				}
				
				& .cell {
					height: 24px;
					& > span.value-viewer {
						height: 21px;
					}
					& > input.data-editor {
						font-size: 0.875rem;
						height: 18px;
					}
				} 
			}
		}
	');
	
	var ADD_COLUMN_BUTTON:coconut.react.RenderResult = coconut.react.Renderer.hxx('<button onclick=${showColumnAdder = true}>+col</button>');
	
	function render() '
		<div class=${CONTAINER}>
			<DataSheet
				data=${data}
				valueRenderer=${valueRenderer}
				disablePageClick=${disablePageClick}
				dataRenderer=${(cell, i, j) -> valueToString(cell.value)}
				onContextMenu=${onContextMenu}
				onCellsChanged=${onCellsChanged}
				dataEditor=${dataEditor}
				cellRenderer=${cellRenderer}
				isCellNavigable=${isCellNavigable}
			/>
			<ColumnAdder
				open=${showColumnAdder}
				columns=${columnList}
				tables=${tableNames}
				customs=${typeNames}
				onCancel=${showColumnAdder = false}
				onConfirm=${v -> {
					columns.push(v);
					for(i in 0...rows.length) {
						var row = rows.get(i);
						row.set(v.name, v.type.getDefaultValue(i));
					}
					showColumnAdder = false;
				}}
			/>
			<switch ${contextMenu}>
				<case ${null}>
				<case ${Column(i, x, y)}>
					<let current=${columns.get(i)}>
						<ColumnMenu
							x=${x}
							y=${y}
							column=${current}
							columns=${columnList}
							tables=${tableNames}
							customs=${typeNames}
							onClose=${contextMenu = null}
							onDelete=${() -> {
								if(js.Browser.window.confirm('Delete column "${current.name}"?')) {
									columns.splice(i, 1);
									for(row in rows.values()) row.remove(current.name);
								}
								contextMenu = null;
							}}
							onEdit=${col -> {
								columns.set(i, col);
								
								// try convert current values
								for(row in rows.values()) {
									var v = row.get(current.name);
									row.remove(current.name);
									row.set(col.name, switch col.type.convertValue(v == null ? null : v.value) {
										case Success(v): v;
										case Failure(e): {
											value: null,
											interim: {
												value: v == null || v.value == null ? '' : valueToString(Value(v.value)),
												error: e.data == null ? e.message : Std.string(e.data)
											}
										}
									});
								}
								contextMenu = null;
							}}
						/>
					</let>
				<case ${Row(i, x, y)}>
					<RowMenu
						x=${x}
						y=${y}
						onClose=${contextMenu = null}
						onDelete=${() -> {
							if(js.Browser.window.confirm('Delete row $i?'))
								rows.splice(i, 1);
							contextMenu = null;
						}}
					/>
			</switch>
		</div>
	';
	
	function onContextMenu(event:js.html.MouseEvent, cell:Cell<CellValue>, row:Int, col:Int) {
		if(row == 0 && col > 0) {
			contextMenu = Column(col - 1, event.clientX, event.clientY);
		}
		if(row > 0 && col == 0) {
			contextMenu = Row(row - 1, event.clientX, event.clientY);
		}
	}
	
	function onCellsChanged(changes:Array<Change<CellValue>>, additions:Array<Addition>) {
		
		function handle(v:Addition) {
			var c = v.col - 1; // minus header offset
			var r = v.row - 1; // minus header offset
			
			var column = columns.get(c);
			var row = switch rows.get(r) {
				case null:
					var row = new ObservableMap([for(column in columns.values()) column.name => (column.type.getDefaultValue(r):Content)]);
					rows.set(r, row);
					row;
				case row:
					row;
			}
			
			row.set(column.name, switch parseValue(column.type, v.value) {
				case Success(v):
					v;
				case Failure(e):
					{value: switch row.get(column.name) {case null: null; case v: v.value;}, interim: {value: v.value, error: e.data == null ? e.message : Std.string(e.data)}}
			});
		}
		
		for(change in changes) handle(change);
		if(additions != null) for(addition in additions) handle(addition);
	}
	
	var valueRendererCache = new Map();
	function valueRenderer(cell:Cell<CellValue>, row:Int, col:Int):react.ReactComponent.ReactSingleFragment {
		return if(row == 0 && col == 0) {
			ADD_COLUMN_BUTTON;
		} else switch cell.value {
			case Invalid(value, error):
				var key = '$value:_:$error';
				if(!valueRendererCache.exists(key))
					valueRendererCache[key] = hxx('<Tooltip title=${error}><div>${value}</div></Tooltip>');
				valueRendererCache[key];
			case _:
				valueToString(cell.value);
		}
	}
	
	function dataEditor(props:DataEditorProps<CellValue>):react.ReactComponent.ReactFragment {
		return switch columns.get(props.col - 1) {
			case column = {type: SubTable(c)}:
				var subTableColumns = TableModel.fromColumns(c);
				var subTableRows = TableModel.fromRows(switch props.cell.value {
					case Value(SubTable(rows)): rows;
					case _: null;
				});
				
				disablePageClick = true;
				
				function commit(v, e) {
					disablePageClick = false;
					columns.set(props.col - 1, merge(column, type = SubTable(TableModel.toColumns(subTableColumns))));
					props.onCommit(v, e);
				}
				
				@hxx '
					<SubTableEditor
						onCommit=${commit}
						columns=${subTableColumns}
						rows=${subTableRows}
						getCustomType=${getCustomType}
						tableNames=${tableNames}
						typeNames=${typeNames}
						depth=${depth + 1}
					/>
				';
			case {type: Boolean}:
				null; // unreachable because a Switch is always rendered
				
			case {type: Enumeration(list)}:
				var value = switch props.cell.value {
						case Value(Enumeration(v)): v;
						case _: list[0];
					}
			
				disablePageClick = true;
				
				function revert() {
					disablePageClick = false;
					props.onRevert();
				}
				
				function commit(v:String) {
					disablePageClick = false;
					props.onCommit(v, null);
				}
				
				@hxx '
					<DropdownEditor
						options=${list.toArray()}
						getOptionLabel=${v -> v}
						defaultValue=${value}
						onRevert=${revert}
						onCommit=${commit}
					/>
				';
			case _:
				react.ReactMacro.jsx('<input class="data-editor" autoFocus ${...props} onChange=${e -> props.onChange(e.target.value)}/>');
		}
	}
	
	static function cellRenderer(props:CellRendererProps<CellValue>) {
		var style = switch (props.cell.value:CellValue) {
			case Header(v): null;
			case Invalid(v, _): {backgroundColor: 'rgba(200, 0, 0, 0.3)'}
			case Value(v): null;
			case Empty: null;
		}
		
		return coconut.Ui.hxx('
			<td
				style=${js.lib.Object.assign({}, props.style, style)}
				class=${props.className}
				onContextMenu=${props.onContextMenu}
				onDoubleClick=${props.onDoubleClick}
				onKeyUp=${props.onKeyUp}
				onMouseDown=${props.onMouseDown}
				onMouseOver=${props.onMouseOver}
			>
				${props.children}
			</td>
		');
	}
	
	function parseValue(type:ValueType, value:String):Outcome<Value, Error> {
		return exp.db.app.util.ValueParser.parseRawString(type, value, getCustomType);
	}
	
	static function valueToString(value:CellValue):String {
		return switch value {
			case Header(v) | Invalid(v, _):
				v;
			case Empty:
				'';
			case Value(v):
				exp.db.app.util.ValuePrinter.print(v);
		}
	}
	
	static function isCellNavigable(cell, row, col) {
		return row != 0 && col != 0;
	}
}

@:react.hoc(withStyles(styles))
class SubTableEditor extends View {
	
	@:attr var onCommit:(value:String, event:js.html.KeyboardEvent)->Void;
	@:attr var tableNames:Vector<String>;
	@:attr var typeNames:Vector<String>;
	@:attr var getCustomType:String->Outcome<CustomType, Error>;
	@:attr var columns:ObservableArray<Column>;
	@:attr var rows:ObservableArray<ObservableMap<String, Content>>;
	@:attr var depth:Int;
	
	@:react.injected var classes:{
		modal:String,
		paper:String,
	}
	
	static function styles(theme) return {
		modal: {
			display: 'flex',
			flexDirection: 'column',
			alignItems: 'center',
		},
		paper: {
			overflowY: 'scroll',
		},
	}
	
	
	function render() '
		<Modal class=${classes.modal} open onClose=${commit}>
			<Paper class=${classes.paper} style=${{margin: depth * 24}}>
				<Sheet ${...this}/>
			</Paper>
		</Modal>
	';
	
	function commit() {
		try {
			var str = tink.Json.stringify(TableModel.toRows(rows));
			onCommit(str, null);
		} catch(e:Dynamic) {
			trace(e);
		}
	}
}

@:react.hoc(withStyles(styles))
class DropdownEditor<T> extends View {
	
	@:attr var options:Vector<T>;
	@:attr var getOptionLabel:T->String;
	@:attr var defaultValue:T;
	@:attr var onCommit:T->Void;
	@:attr var onRevert:()->Void;
	
	@:react.injected var classes:Dynamic;
	
	static function styles(theme) return {
		root: {
			display: 'flex',
			padding: '0',
			height: '100%',
		},
	}
	
	static final WRAPPER = css('
		display: flex;
		height: 100%;
		flex: 1;
	');
	
	// copied from: .data-grid-container .data-grid .cell > input
	// TODO: https://github.com/back2dos/cix/issues/21
	static final INPUT = css('
		outline: none !important;
		border: 2px solid rgb(33, 133, 208);
		text-align: right;
		height: 18px;
		background: none;
	');
	
	
	function render() '
		<Autocomplete
			open
			size=${Small}
			classes=${classes}
			options=${options.toArray()}
			getOptionLabel=${getOptionLabel}
			defaultValue=${cast defaultValue}
			onClose=${(e, reason) -> {
				if(reason == 'escape') onRevert();
			}}
			onChange=${(e, v, reason) -> {
				if(v != null) onCommit(v);
			}}
			renderInput=${params -> react.ReactMacro.jsx('
				<div ref=${params.InputProps.ref} className=${WRAPPER}>
					<input 
						${...params.inputProps}
						className=${INPUT.add((cast params.inputProps).className)}
						style=${{width: 'calc(100% - 6px)'}}
						autoFocus
					/>
				</div>
			')}
		/>
	';
	
	
}

class ColumnMenu extends View {
	@:attr var x:Int;
	@:attr var y:Int;
	@:attr var column:Column;
	@:attr var columns:Vector<Column>;
	@:attr var tables:Vector<String>;
	@:attr var customs:Vector<String>;
	
	@:attr var onClose:Void->Void;
	@:attr var onDelete:Void->Void;
	@:attr var onEdit:Column->Void;
	
	@:state var edit:Bool = false;
	
	function render() '
		<>
			<Menu open=${!edit} anchorReference=${AnchorPosition} anchorPosition=${{left: x, top: y}} onClose=${onClose}>
				<MenuItem dense onClick=${onDelete}>Delete Column</MenuItem>
				<MenuItem dense onClick=${_ -> edit = true}>Edit Column</MenuItem>
			</Menu>
			<ColumnAdder
				open=${edit}
				initial=${column}
				columns=${columns.filter(v -> v.name != column.name)}
				tables=${tables}
				customs=${customs}
				onCancel=${onClose}
				onConfirm=${onEdit}
			/>
		</>
	';
}

class RowMenu extends View {
	@:attr var x:Int;
	@:attr var y:Int;
	
	@:attr var onClose:Void->Void;
	@:attr var onDelete:Void->Void;
	
	function render() '
		<>
			<Menu open anchorReference=${AnchorPosition} anchorPosition=${{left: x, top: y}} onClose=${onClose}>
				<MenuItem dense onClick=${onDelete}>Delete Row</MenuItem>
			</Menu>
		</>
	';
}