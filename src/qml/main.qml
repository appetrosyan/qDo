import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import Qt.labs.platform 1.0 as Labs
import QSettings 1.0
import ac.uk.cam.ap886 1.0
import core 1.0
import "sortUtils.js" as SortUtils

ApplicationWindow {
	id: rootWindow
	width: 300
	minimumWidth: 300
	height: 500
	minimumHeight: 400
	title: qsTr("qDolist") + " — [%1/%2]: %3%4".arg(myModel.completeTasks)
	.arg(myModel.size)
	.arg((myFileList.activeTrackedFile!=null)?myFileList.activeTrackedFile.fileName:"")
	.arg((myFileList.activeTrackedFile!=null)?(myFileList.activeTrackedFile.isModified?"*":""):"")
	property int mm: Screen.pixelDensity
	visible: true
	signal writeToFile(string file)
	signal loadFromFile(string file)
	signal saveAllFiles()
	signal requestTaskList()
	signal moveFocusedTaskUp()
	signal moveFocusedTaskDown()
	signal demoteFocusedTask()
	signal promoteFocusedTask()
	signal toggleFocusedTask()
	signal showNotification(string msg)
	signal showAgenda()
	SystemPalette{
		id: sysPallete
	}


	Material.accent: Material.Red
	Material.theme: settings.darkMode?Material.Dark:Material.light
	color: Qt.darker(Material.background, 1.2)
	header:ToolBar{
		RowLayout{
			anchors.fill: parent
			ToolButton{
				id: sidebarToggle
				text: "\u2263"
				visible: rootWindow.width < 500
				font.pixelSize: 24
				onClicked: globalDrawer.visible=!globalDrawer.visible
			}
			Button{
				text: "filtered"
				flat: !taskList.filtered
				font.capitalization: Font.Capitalize
				Layout.alignment: Qt.AlignRight
				onClicked:  {
					if(taskList.filtered){
						unfilter()
					} else {
						filterMenu.visible=true
					}
				}
			}
			ToolButton{
				text: "\u205E"
				Layout.alignment: Qt.AlignRight
				font.pixelSize: 24
				onClicked: {
					contextMenu.visible=!contextMenu.visible
					contextMenu.x = this.x
				}
			}

		}
	}

	Menu {
		id:filterMenu
		visible: false
		Action{
			id: filterIncomplete
			text: "Filter Incomplete"
			onTriggered: {
				filter((a) => !a.done)
			}
		}
		Action{
			id: filterOverdue
			text: "Filter Overdue"
			onTriggered: {
				filter((a) => a.overDue)
			}
		}
		Action{
			id: filterDone
			text: "Filter Done"
			onTriggered: {
				filter((a) => a.done)
			}
		}
	}

	Menu{
		id: contextMenu
		visible: false
		Action {
			id: saveAll
			shortcut: StandardKey.Save
			text: "Save all"
			onTriggered: {
				rootWindow.saveAllFiles()
			}
			icon.name: "file-save"
		}
		Action {
			id: openFile
			shortcut: StandardKey.Open
			text: "Open"
			onTriggered: {
				loadTodoListDialog.visible=true
			}
			icon.name: "file-open"
		}
		Action {
			id: saveAs
			shortcut: StandardKey.SaveAs
			text: "Save as"
			onTriggered: {
				saveTodoListDialog.visible=true
			}
			icon.name: "file-save-as"
		}
		Action {
			id: prune
			shortcut: StandardKey.Delete
			text: "Prune finished tasks"
			onTriggered: {
				myModel.prune()
			}
		}
		Action {
			id: showAgenda
			shortcut: StandardKey.WhatsThis
			text: "Show agenda"
			onTriggered:{
				rootWindow.showAgenda()
			}
		}
	}

	Component {
		id: sidebar
		ColumnLayout{
			property alias filePicker: inner_filePicker
			Rectangle{
				width:globalDrawer.width-10
				height: childrenRect.height
				color: Material.background
				border.color: Material.foreground
				radius: 12
				FilePicker{
					id: inner_filePicker
					width: globalDrawer.width-12
					height: 160
					Layout.preferredWidth: 250
					Layout.fillHeight: false
					Layout.fillWidth: false
				}
			}
			Switch{
				text: qsTr("Auto Sync Files")
				checked: settings.autoSync
				font.pixelSize: 11
				onCheckedChanged: settings.autoSync = checked
				transitions: [Transition {
						NumberAnimation{
							properties: x
							easing.type: Easing.InOutQuad
							duration: 200
						}
					}]
			}
			Switch{
				text: qsTr("Dark Mode")
				font.pixelSize: 11
				checked: settings.darkMode
				onCheckedChanged: {
					settings.darkMode = checked
				}
				transitions: [Transition {
						NumberAnimation{
							properties: x
							easing.type: Easing.InOutQuad
							duration: 200
						}
					}]
			}
			Switch{
				text: qsTr("Allow JavaScript evaluation")
				checked: settings.allowEval
				font.pixelSize: 11
				onCheckedChanged: {
					settings.allowEval = checked
				}
				transitions: [Transition {
						NumberAnimation{
							properties: x
							easing.type: Easing.InOutQuad
							duration: 200
						}
					}]
			}

		}
	}

	Drawer{
		id: globalDrawer
		height: rootWindow.height
		dragMargin: sidebarToggle.visible?10:0
		width: 250
		// TODO: Move position bindings from the component to the Loader.
		//       Check all uses of 'parent' inside the root element of the component.
		Loader {
			id: loader_ColumnLayout
			sourceComponent: sidebar
		}

	}

	Timer{
		id: saveTimer
		interval: 1000
		running: settings.autoSync
		repeat: settings.autoSync
		onTriggered: {
			saveAllFiles()
		}

	}

	ColumnLayout {
		anchors.fill: parent
		RowLayout {
			id: centerpiece
			Layout.fillHeight: true
			Layout.fillWidth: true
			Rectangle{
				id: drawerReplacer
			}

			Loader{
				sourceComponent: sidebar
				visible: rootWindow.width> 500
			}

			ColumnLayout {
				Layout.alignment: Qt.RightButton
				TaskList {
					id: taskList
					z: -2
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
					Layout.minimumWidth: 300
					Layout.fillHeight: true
					highlightRangeMode: ListView.ApplyRange
					snapMode: ListView.SnapToItem
					contentHeight: 2
					pixelAligned: false
					transformOrigin: Item.Center
					model: myModel
				}
			}

		}
	}

	ListModel{
		id: commandModel
		ListElement{ name: ":show agenda"}
		ListElement{ name: ":prune"}
		ListElement{ name: ":find"}
		ListElement{ name: ":filter done"}
		ListElement{ name: ":filter none"}
		ListElement{ name: ":filter overdue"}
		ListElement{ name: ":filter incomplete"}
	}

	Menu{
		id: suggestions
		width: rootWindow.width
		height: suggestionList.height + 50
		margins: sidebar.visible?300:0
		y: footer.y - suggestions.height
		ListView{
			id: suggestionList
			model:commandModel
			height: 90
			clip: true
			delegate: ToolButton{
				id: suggestionDelegate
				font.pixelSize: 8
				font.capitalization: Font.Normal
				height: 30
				text: name
				onClicked: {
					addTask.edited = false
					addTask.text = model.name
					visible = false
				}
			}
		}
	}

	footer:TaskAdd {
		id: addTask
		onCreateNewTask: {
			if(msg.startsWith(":")){
				if(msg.toLowerCase().trim()===(":show agenda")){
					rootWindow.showAgenda()
				} else if (msg.startsWith(":prune")){
					myModel.prune()
				} else if (msg.startsWith(":toggle")){
					rootWindow.toggleFocusedTask()
				} else if(msg.startsWith(":filter")){
					console.log("filtering")
					if(msg.match(/\s+done/gi)){
						console.log("done")
						filter((a)=>a.done)
					} else if(msg.match(/\s+incomplete/gi)){
						filter((a)=>!a.done)
					} else if(msg.match(/\s+over\s*due/gi)){
						filter((a)=>a.overDue)
						console.log("overDue")
					} else if(msg.match(/\s+none/gi)){
						unfilter()
					} else if (msg.match(/\s+custom/gi)) {
						let tag = msg.match(/custom\s+(.*)/i)
						if(settings.allowEval){
							// Yeah, I know eval is dangerous. Using JavaScript is not my choice, I can at least
							// make the best of it.
							// @disable-check M23
							filter(eval(tag[1]))
						} else {
							rootWindow.showNotification("JavaScript eval disabled. Custom filters will not work.")
						}
					} else {
						rootWindow.showNotification("Unrecognised filter string: %1".arg(msg))
					}
				}
				else {
					rootWindow.showNotification("unrecognised command %1".arg(msg))
				}
			}else {
				myModel.createNewTask(msg)
			}
			addTask.text = ""
			suggestions.visible=false
		}
		onSuggestionsRequested: {
			suggestions.visible=true
			suggestions.focus=false
			SortUtils.listModelSort(commandModel,
									(a,b) =>  - SortUtils.similarity(a.name, text) +
									SortUtils.similarity(b.name, text))
			if(text ===commandModel.get(0).name){
				suggestions.focus=false
				suggestions.visible=false
			}
		}
		onMostLikelySuggestionRequested: {
			addTask.text=commandModel.get(0).name
			suggestions.focus=false
			suggestions.visible=false
		}
	}


	function filter(fn) {
		taskList.filterFunction = fn
		taskList.filtered = true
	}

	function unfilter() {
		taskList.filterFunction = ((a) => true)
		taskList.filtered = false
	}

	FileDialog{
		id:saveTodoListDialog
		title: qsTr("Choose a new To-do list to write")
		folder: shortcuts.documents
		selectExisting: false
		onAccepted: rootWindow.writeToFile(fileUrl)
	}

	FileDialog {
		id: loadTodoListDialog
		title: qsTr("Choose an exsiting To-do list")
		folder: shortcuts.documents
		selectExisting: true
		onAccepted: rootWindow.loadFromFile(fileUrl)
	}
}
