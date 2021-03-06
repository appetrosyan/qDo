import QtQuick 2.11
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.3

Row{
	property bool expanded: true
	CheckBox{
		id: doneCheckbox
		checkState: !modelData.done?
						(modelData.doneSubtaskCount >0 ? 1:0)
					  :2
		checkable: false
		onClicked: {
			if(!modelData.toggle()){
				shake.start()
			}
		}
		SequentialAnimation on x{
			id: shake
			NumberAnimation {
				to: 10
				duration: 80
				easing.type: Easing.InOutBounce
			}
			NumberAnimation{
				to: 0
				duration: 150
				easing.type: Easing.InOutBounce
			}
		}
		Layout.alignment: Qt.AlignLeft

	}
	ColumnLayout{
		id: todoContent
		width: parent.width - doneCheckbox.width - dueDatePicker.width -7 - (caret.visible?caret.width:0)
		anchors.verticalCenter: parent.verticalCenter
		TextEdit{
			id: nameRow
			text: modelData.name
			//		anchors.verticalCenter: parent.verticalCenter
			color: Material.foreground
			Layout.alignment: Qt.AlignLeft
			onCursorVisibleChanged: {
				modelData.requestFocus()
			}
			Keys.onPressed: {
				if(event.matches(StandardKey.Undo)){
					text = modelData.name
				}
			}
			Keys.onUpPressed: {
				rootWindow.moveFocusedTaskUp()
			}
			Keys.onDownPressed: {
				rootWindow.moveFocusedTaskDown()
			}
			Keys.onTabPressed: {
				rootWindow.demoteFocusedTask()
			}
			Keys.onBacktabPressed: {
				rootWindow.promoteFocusedTask()
			}
			Keys.onReturnPressed: {
				text=text.trim()
				cursorVisible=false
				editingFinished()
//				focused=false
			}
			onEditingFinished: {
				modelData.name = text
			}
			selectByMouse: true
		}
		Row{
			Label{
				text: "[%1/%2] ".arg(modelData.doneSubtaskCount).arg(modelData.subtaskCount)
				visible: modelData.subtaskCount > 0
				font.pixelSize: nameRow.font.pixelSize-4
				opacity: 0.70
			}
			TextEdit{
				width: todoContent.width
				text: (modelData.comment?modelData.comment:"Comment")
				color: Material.foreground
				font.pixelSize: nameRow.font.pixelSize-4
				opacity: modelData.comment?1:0.25
				onEditingFinished: {
					if(text !== "Comment" && text.trim() !== "")
						modelData.comment = text
					else{
						text = "Comment"
						modelData.comment = ""
					}
				}
				Keys.onReturnPressed: {
					if(event.modifiers === Qt.NoModifier)
						editingFinished()
				}
				Keys.onPressed: {
					if(event.matches(StandardKey.Undo)){
						text = modelData.comment
					}
				}

				onCursorVisibleChanged: {
					if(cursorVisible && text ==="Comment"){
						text = ""
					}
				}
				selectByMouse: true
				wrapMode: TextEdit.Wrap
			}
		}
	}
	Label{
		id: caret
		text: "\u25B6"
		rotation: expanded?90:0
		visible: modelData.subtaskCount
		anchors.verticalCenter: parent.verticalCenter
		MouseArea{
			anchors.fill: parent
			onClicked: {
				expanded = !expanded
			}
		}
		Behavior on rotation {
			NumberAnimation {
				easing.overshoot: 2.702
				easing.type: Easing.InBack
				properties: "rotation"
				duration: 300
			}
		}
	}
	Label{
		id: dueDatePicker
		text:  modelData.prettyDueTime
		font.bold: modelData.overDue?true:false
		font.capitalization: Font.Capitalize
		anchors.verticalCenter: parent.verticalCenter
		MouseArea{
			anchors.fill: parent
			onClicked: loader_pickerDialog.item.visible=!loader_pickerDialog.item.visible
		}
		// TODO: CREATE FUCKING REFACTORING TOOLS. IF YOU CAN WRITE COMMENTS THAT TELL ME WHAT TO DO
		// THEN YOU CAN WRITE AN AWK SCRIPT.
		Component {
			id: component_pickerDialog
			Popup{
				property alias picker: inner_picker
				id: pickerDialog
				height: picker.height +20
				width: picker.width +20
				rightMargin: 5
				DatePicker {
					id: inner_picker
					date: modelData.due
					onNewDate: {
						modelData.due = msg
					}
				}
			}
		}
		Loader {
			id: loader_pickerDialog
			sourceComponent: component_pickerDialog
		}
	}
}
