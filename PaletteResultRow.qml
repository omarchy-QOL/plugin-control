import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: root

  required property int index
  required property string pluginName
  required property string pluginId
  required property string description
  required property string author
  required property string kind
  required property string stateLabel
  required property string sourceLabel
  required property string warningLabel
  required property string version
  required property string installedVersion
  required property bool versionWarning
  required property string versionWarningTooltip
  required property string repository
  required property bool separatorBefore
  required property bool dangerous

  property bool selected: false
  property bool settingsMenuOpen: false
  property bool pointerInteractive: true
  property int rowHeight: Style.space(60)
  property color foreground: Color.menu.text
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color urgent: Color.urgent
  property color installedVersionColor: Color.accent
  property color versionWarningColor: Color.accent
  readonly property bool showInstalledVersion: !settingsMenuOpen
    && installedVersion !== ""
  readonly property string repositoryLabel: {
    var value = root.repository.replace(/\/$/, "")
    var githubPrefix = "https://github.com/"
    return value.indexOf(githubPrefix) === 0
      ? value.slice(githubPrefix.length) : value
  }
  readonly property int titleLineHeight: Math.ceil(titleFontMetrics.height)
  readonly property int detailLineHeight: Math.ceil(detailFontMetrics.height)
  readonly property int rightColumnWidth: Math.ceil(Math.max(
    rightColumnMetrics.advanceWidth,
    stateColumnMetrics.advanceWidth + Style.space(24)))
  readonly property int detailLineCount: settingsMenuOpen ? 1 : 2
  readonly property int contentHeight: titleLineHeight + Style.space(2)
    + detailLineHeight * detailLineCount

  signal hovered()
  signal activated()
  signal repositoryRequested(string url)

  FontMetrics {
    id: titleFontMetrics
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.title
  }

  FontMetrics {
    id: detailFontMetrics
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.bodySmall
  }

  TextMetrics {
    id: rightColumnMetrics
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.title
    text: "Marketplace listed"
  }

  TextMetrics {
    id: stateColumnMetrics
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.title
    text: "Browse only 0.0.0"
  }

  height: rowHeight
  radius: Style.cornerRadius
  color: selected ? selectedBackground : "transparent"

  Rectangle {
    visible: root.separatorBefore
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Math.max(1, Style.space(1))
    color: Util.alpha(root.foreground, 0.18)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    hoverEnabled: true
    cursorShape: root.pointerInteractive
      ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: if (root.pointerInteractive) root.hovered()
    onClicked: if (root.pointerInteractive) root.activated()
  }

  Item {
    id: contentFrame
    anchors.left: parent.left
    anchors.leftMargin: Style.spacing.md
    anchors.right: parent.right
    anchors.rightMargin: Style.spacing.md
    anchors.verticalCenter: parent.verticalCenter
    height: root.contentHeight

    Item {
      id: leftColumn
      anchors.left: parent.left
      anchors.right: root.settingsMenuOpen
        ? parent.right : badgeColumn.left
      anchors.rightMargin: root.settingsMenuOpen ? 0 : Style.spacing.sm
      anchors.top: parent.top
      anchors.bottom: parent.bottom

      Row {
        id: titleRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.titleLineHeight
        spacing: Style.spacing.sm
        readonly property real installedWidth: root.showInstalledVersion
          ? Math.min(installedVersionText.implicitWidth, width * 0.36) : 0
        readonly property real nameSpace: width - installedWidth
          - (root.showInstalledVersion ? spacing : 0)

        Text {
          id: pluginNameText
          objectName: "pluginNameText"
          width: Math.min(implicitWidth, Math.max(0, titleRow.nameSpace
            * (repositoryText.visible ? 0.52 : 1)))
          height: parent.height
          text: root.pluginName
          textFormat: Text.PlainText
          color: root.selected ? root.selectedText
            : (root.dangerous ? root.urgent : root.foreground)
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.title
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Text {
          id: repositoryText
          objectName: "repositoryText"
          z: 2
          visible: !root.settingsMenuOpen && root.repository !== ""
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, Math.max(0, parent.width - x
            - titleRow.installedWidth
            - (root.showInstalledVersion ? titleRow.spacing : 0)))
          text: root.repositoryLabel
          textFormat: Text.PlainText
          color: root.selected ? root.selectedText : root.foreground
          opacity: repositoryMouse.containsMouse ? 0.90 : 0.48
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.underline: repositoryMouse.containsMouse
          elide: Text.ElideRight

          MouseArea {
            id: repositoryMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: root.pointerInteractive
              ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: if (root.pointerInteractive) root.hovered()
            onClicked: if (root.pointerInteractive)
              root.repositoryRequested(root.repository)
          }
        }

        Text {
          id: installedVersionText
          objectName: "installedVersionText"
          visible: root.showInstalledVersion
          width: titleRow.installedWidth
          height: parent.height
          text: "(installed " + root.installedVersion + ")"
          textFormat: Text.PlainText
          color: root.installedVersionColor
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.caption
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
      }

      Text {
        id: descriptionText
        objectName: "descriptionText"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: titleRow.bottom
        anchors.topMargin: Style.space(2)
        height: root.detailLineHeight * root.detailLineCount
        text: root.settingsMenuOpen ? root.description
          : (root.description || root.kind)
        textFormat: Text.PlainText
        color: root.selected ? root.selectedText : root.foreground
        opacity: 0.65
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.bodySmall
        lineHeightMode: Text.FixedHeight
        lineHeight: root.detailLineHeight
        wrapMode: root.settingsMenuOpen ? Text.NoWrap : Text.Wrap
        maximumLineCount: root.detailLineCount
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignTop
      }
    }

    Item {
      id: badgeColumn
      objectName: "badgeColumn"
      visible: !root.settingsMenuOpen
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: visible ? root.rightColumnWidth : 0

      Item {
        id: stateLine
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.titleLineHeight

        Text {
          id: stateText
          objectName: "stateText"
          anchors.right: versionCluster.visible
            ? versionCluster.left : parent.right
          anchors.rightMargin: versionCluster.visible ? Style.spacing.sm : 0
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.min(implicitWidth, Math.max(0, parent.width
            - versionCluster.width - anchors.rightMargin))
          text: root.stateLabel
          textFormat: Text.PlainText
          color: root.selected ? root.selectedText : root.foreground
          font.family: Style.font.menuFamily
          font.pixelSize: Style.font.title
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideRight
        }

        Item {
          id: versionCluster
          objectName: "versionCluster"
          visible: root.version !== ""
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          implicitWidth: versionText.implicitWidth
            + (versionWarningIcon.visible
              ? versionWarningIcon.implicitWidth + Style.space(4) : 0)
          width: Math.min(implicitWidth, Math.max(0, parent.width
            - stateText.implicitWidth - Style.spacing.sm))

          Text {
            id: versionWarningIcon
            objectName: "versionWarningIcon"
            visible: root.versionWarning
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? implicitWidth : 0
            text: "\uf071"
            textFormat: Text.PlainText
            color: root.versionWarningColor
            font.family: Style.font.family
            font.pixelSize: Style.font.icon
          }

          Text {
            id: versionText
            objectName: "versionText"
            anchors.left: versionWarningIcon.right
            anchors.leftMargin: versionWarningIcon.visible
              ? Style.space(4) : 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            text: root.version
            textFormat: Text.PlainText
            color: root.versionWarning
              ? root.versionWarningColor
              : (root.selected ? root.selectedText : root.foreground)
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.title
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
          }

          MouseArea {
            id: versionWarningHover
            objectName: "versionWarningHover"
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.versionWarning
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
          }

          PanelToolTip {
            id: versionTooltip
            objectName: "versionTooltip"
            visible: root.versionWarning && versionWarningHover.containsMouse
            width: Style.space(320)
            x: Math.round(versionWarningIcon.x
              + versionWarningIcon.width / 2 - width / 2)
            y: -height - Style.space(6)
            text: root.versionWarningTooltip
            panelBorder: root.versionWarningColor
            fontFamily: Style.font.menuFamily

            contentItem: Text {
              text: versionTooltip.text
              textFormat: Text.PlainText
              color: versionTooltip.panelForeground
              font.family: versionTooltip.fontFamily
              font.pixelSize: versionTooltip.fontSize
              wrapMode: Text.Wrap
              lineHeight: 1.15
              leftPadding: Style.spacing.sm
              rightPadding: Style.spacing.sm
              topPadding: Style.spacing.sm
              bottomPadding: Style.spacing.sm
            }
          }
        }
      }

      Text {
        id: sourceText
        objectName: "sourceText"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: stateLine.bottom
        anchors.topMargin: Style.space(2)
        height: root.detailLineHeight
        text: root.sourceLabel
        textFormat: Text.PlainText
        color: root.selected ? root.selectedText : root.foreground
        opacity: 0.55
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.bodySmall
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
      }

      Text {
        id: warningText
        objectName: "warningText"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: sourceText.bottom
        height: root.detailLineHeight
        text: root.warningLabel ? "(" + root.warningLabel + ")" : ""
        textFormat: Text.PlainText
        color: root.urgent
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.bodySmall
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
      }
    }
  }
}
