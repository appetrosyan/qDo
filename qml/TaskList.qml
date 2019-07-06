import QtQuick 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
import ac.uk.cam.ap886 1.0
import org.kde.kirigami 2.6 as Kirigami
import core 1.0

ListView {
	id: listView
	property var thisYear
	property var thisMonth
	property var thisDay
	add: slideIn
	remove: dropOut
	moveDisplaced:smoothShuffle
	move: smoothShuffle
	Transition {
		id: slideIn
		NumberAnimation {
			easing.amplitude: 1.05
			properties: "x"
			from: 100
			duration: 400
			easing.type: Easing.OutBounce
		}
	}
	Transition {
		id: dropOut
		NumberAnimation {
			easing.amplitude: 1.05
			properties: "x"
			to: 300
			duration: 400
			easing.type: Easing.InExpo
		}
	}

	Transition{
		id:smoothShuffle
		NumberAnimation{
			properties: "y"
			to: accordion.height
			duration: 1000
			easing.type: Easing.InOutCubic
		}
	}


	delegate: accordion
	Component {
		id: accordion
		Rectangle {
			width: parent.width
			height: childrenRect.height
			color: Qt.darker(sysPallete.window, 1+modelData.doneSubtaskCount/10)
			radius: 15

//			InfoRow {
//				id: infoRow
			//			}
			Kirigami.SwipeListItem {
				property bool expanded:false
				property var subTasks
				id:infoRow
				height: 50
				Row{
					QQC2.CheckBox{
						id: check
						checkState: !modelData.done? (modelData.doneSubtaskCount >0 ? 1:0):2
						checkable: false
						onClicked: {
							if(!modelData.toggle()){
								shake.start()
							}
						}
						SequentialAnimation on x{
							id: shake
							NumberAnimation {
								from: 0
								to: 10
								duration: 80
								easing.type: Easing.InOutBounce
							}
							NumberAnimation{
								from: 10
								to: 0
								duration: 150
								easing.type: Easing.InOutBounce
							}
						}
					}

					TextEdit{
						id: nameEdit
						text: modelData.name
						visible: true
						color:  modelData.isLastFocused?sysPallete.highlight:sysPallete.text
						onTextChanged: {
							if(activeFocus)
								cursorVisible=true
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
							focused=false
						}
						onEditingFinished: {
							modelData.name = text
							modelData.requestFocus()
						}
					}
				}
				actions: [
					Kirigami.Action{
						iconName: "accessories-text-editor"
						onTriggered: editDialog.visible=true
					},
					Kirigami.Action {
						iconName: "edit-delete"
						onTriggered: model.modelData.goAway()
					}

				]

				onPressAndHold: {
					modelData.goAway()
				}
				onDoubleClicked: {
					modelData.promote()
				}
				onClicked: {
					expanded = !expanded
					model.modelData.requestFocus()
					if (model.modelData.hasChildren) {
						subTasks = model.modelData.subModel
					} else {
						subTasks = []
					}
				}
			}

			Row{
				anchors.top: infoRow.bottom
				x: 10
				width: parent.width - x
				id: commentRow
				Text{
					id: doneCounter
					text: ("[%1/%2]").arg(modelData.doneSubtaskCount).arg(modelData.subtaskCount)
					visible: modelData.subtaskCount > 0
					color:  Material.foreground
				}
				TextEdit {
					id: commentStrip
					text: ("%1").arg(modelData.comment)
					visible: modelData.comment!==""
					color: Material.foreground
					wrapMode: Text.Wrap
				}

			}
			ListView {
				x: 10
				anchors.top: commentRow.bottom
				width: parent.width - x
				height: childrenRect.height * infoRow.expanded
				visible: infoRow.expanded ? 1 : 0
				opacity: infoRow.expanded ? 1 : 0
				Behavior on opacity {
					NumberAnimation {
						easing.type: Easing.OutBounce
						duration: 500
					}
				}
				delegate: accordion
				// Now this is why QML is such a dumb idea. In normal assignment
				// that the thing on the right wouldn't be the same as on the left:
				// but in QML it's a binding not an assignment and so what I'm doing
				// is recursive binding.
				model: infoRow.subTasks
				interactive: false
				add: slideIn
				remove: dropOut
				moveDisplaced:smoothShuffle
				move: smoothShuffle
			}
			Kirigami.ContextDrawer{
//				id: contextDrawer
				modal: true
				height: rootWindow.height
				width: 250
				id: editDialog
				TaskEdit {
					anchors.fill: parent
					onEditsFinished: {
						editDialog.visible = false
					}
				}
			}
		}
	}

	// If you need to pass a string to a property in an OOP supporting Language
	// This is a sign that your design is probably monumentally stupid. What if I
	// (quite resonably) want to have a custom comparator? What if I track the due
	// dates with up to millisecond precision and I don't want for things that are
	// a miunte apart to show up as different things? If anyone doing QQC2 sees this
	// comment, please fix!
	section.property: "modelData.prettyDueDate"
	section.criteria: ViewSection.FullString
	section.delegate: Component {
		Rectangle {
			width: listView.width
			height: childrenRect.height
			color: Material.accent
			Text {
				text: section
				color: sysPallete.highlightedText
			}
		}
	}

	QQC2.Label {
		id: placeholder
		text: qsTr("Empty")
		anchors.margins: 60
		anchors.fill: parent
		opacity: 0.5
		visible: listView.count === 0
		horizontalAlignment: Qt.AlignHCenter
		verticalAlignment: Qt.AlignVCenter
		font.pixelSize: 18
	}
}
