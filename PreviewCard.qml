// Adapted from Metaplug PreviewCard, copyright (c) 2026 Ilya Zarubin, MIT.
import QtQuick
import qs.Commons
import qs.Ui
import "CatalogModel.js" as Catalog

BorderSurface {
  id: root

  signal informationRequested

  property var plugin: null
  property string imageSource: ""
  property bool imageLoading: false
  property bool imageFailed: false
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color borderColor: Color.menu.border
  property color accent: Color.accent
  property color success: Color.accent
  property color urgent: Color.urgent
  property color marketplaceYellow: Color.accent
  property color marketplaceOrange: Color.accent

  function previewFont(size) {
    return Math.max(8, size - 1)
  }

  readonly property string activityState: Catalog.activityState(plugin, Date.now(
                                                                  ))
  readonly property var metricItems: {
    var values = []
    if (plugin && plugin.stars !== null && plugin.stars !== undefined)
      values.push({
                    label: "Stars",
                    icon: "\uf005",
                    value: plugin.stars,
                    color: marketplaceYellow
                  })
    if (plugin && plugin.metricsAvailable === true) {
      values.push({
                    label: "Hearts",
                    icon: "\uf004",
                    value: plugin.hearts,
                    color: urgent
                  })
      values.push({
                    label: "Views",
                    icon: "\uf441",
                    value: plugin.views,
                    color: marketplaceOrange
                  })
      values.push({
                    label: "Copies",
                    icon: "\uf0c5",
                    value: plugin.copies,
                    color: marketplaceOrange
                  })
    }
    return values.filter(function (item) {
      return item.value !== null && item.value !== undefined
    })
  }
  readonly property var badgeItems: {
    var values = []
    if (activityState === "updated")
      values.push({
                    label: "UPDATED",
                    color: marketplaceYellow,
                    tooltip: "Version updated within the last 12 hours"
                  })
    else if (activityState === "new")
      values.push({
                    label: "NEW",
                    color: success,
                    tooltip: "Listed within the last 12 hours"
                  })
    if (plugin && plugin.builtIn === true)
      values.push({
                    label: "BUILT-IN",
                    color: accent,
                    tooltip: "Included with Omarchy"
                  })
    else if (plugin && plugin.marketplaceListed === true)
      values.push({
                    label: plugin.verificationStatus === "verified"
                           ? "VERIFIED" : "UNVERIFIED",
                    color: plugin.verificationStatus === "verified" ? success :
                                                                      urgent,
                    tooltip: plugin.verificationStatus === "verified"
                             ? "Verified means checks were associated with the listed commit" :
                               "No current marketplace verification"
                  })
    return values
  }

  implicitHeight: contentTopInset + contentBottomInset
                  + previewContent.implicitHeight

  color: background
  radius: Style.cornerRadius
  borderSpec: Border.surfaceSpec("menu", "border", borderColor, Math.max(1,
                                                                         Style.space(
                                                                           2)))
  padding: Style.spacing.panelPadding

  Flickable {
    id: previewViewport
    objectName: "previewViewport"
    anchors.fill: parent
    anchors.topMargin: root.contentTopInset
    anchors.rightMargin: root.contentRightInset
    anchors.bottomMargin: root.contentBottomInset
    anchors.leftMargin: root.contentLeftInset
    contentWidth: width
    contentHeight: previewContent.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    MouseArea {
      width: previewViewport.width
      height: Math.max(previewViewport.height, previewViewport.contentHeight)
      acceptedButtons: Qt.LeftButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.informationRequested()
    }

    Column {
      id: previewContent
      width: parent.width
      spacing: Style.spacing.sm

      Item {
        width: parent.width
        height: root.plugin && root.plugin.previewThumbnailUrl ? Math.round(
                                                                   width * 0.5625) :
                                                                 0
        clip: true

        Image {
          id: previewImage
          anchors.fill: parent
          visible: source !== "" && status !== Image.Error
          source: root.visible ? root.imageSource : ""
          asynchronous: true
          cache: true
          fillMode: Image.PreserveAspectFit
        }

        Text {
          anchors.centerIn: parent
          visible: root.imageLoading || root.imageFailed || previewImage.status
                   === Image.Error
          text: root.imageFailed || previewImage.status === Image.Error
                ? "Preview unavailable" : "Loading preview..."
          color: root.foreground
          font.family: Style.font.menuFamily
          font.pixelSize: root.previewFont(Style.font.body)
        }
      }

      Row {
        id: previewHeading
        width: parent.width
        height: Math.max(previewName.implicitHeight,
                         headingBadges.implicitHeight)
        spacing: Style.spacing.sm

        Text {
          id: previewName
          width: Math.min(implicitWidth, Math.max(0, parent.width
                                                  - headingBadges.implicitWidth
                                                  - parent.spacing))
          anchors.verticalCenter: parent.verticalCenter
          text: root.plugin ? String(root.plugin.name || "") : ""
          textFormat: Text.PlainText
          color: root.foreground
          font.family: Style.font.menuFamily
          font.pixelSize: root.previewFont(Style.font.heading)
          font.bold: true
          elide: Text.ElideRight
        }
        Row {
          id: headingBadges
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          Repeater {
            model: root.badgeItems

            delegate: Rectangle {
              id: statusBadge
              required property var modelData
              width: badgeLabel.implicitWidth + Style.space(6)
              height: badgeLabel.implicitHeight + Style.space(4)
              radius: Style.space(3)
              color: Util.alpha(modelData.color, 0.10)
              border.width: Math.max(1, Style.space(1))
              border.color: Util.alpha(modelData.color, 0.72)

              Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: statusBadge.modelData.label
                textFormat: Text.PlainText
                color: statusBadge.modelData.color
                font.family: Style.font.menuFamily
                font.pixelSize: root.previewFont(Style.font.caption)
                font.bold: true
              }

              MouseArea {
                id: badgeHover
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
              }

              PanelToolTip {
                visible: badgeHover.containsMouse
                text: String(statusBadge.modelData.tooltip || "")
                fontFamily: Style.font.menuFamily
              }
            }
          }
        }
      }

      Text {
        width: parent.width
        text: root.plugin ? String(root.plugin.repository || "").replace(
                              "https://github.com/", "") || String(
                              root.plugin.kind || root.plugin.category
                              || "Plugin") : ""
        textFormat: Text.PlainText
        color: root.foreground
        opacity: 0.62
        font.family: Style.font.menuFamily
        font.pixelSize: root.previewFont(Style.font.body)
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        height: Math.min(implicitHeight, font.pixelSize * 4)
        text: root.plugin ? String(root.plugin.description || "") : ""
        textFormat: Text.PlainText
        color: root.foreground
        opacity: 0.74
        font.family: Style.font.menuFamily
        font.pixelSize: root.previewFont(Style.font.body)
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 3
      }

      Flow {
        width: parent.width
        spacing: Style.space(5)

        Repeater {
          model: root.plugin ? [root.plugin.category].concat(root.plugin.tags
                                                             || []).filter(
                                 Boolean).slice(0, 3) : []

          delegate: Rectangle {
            required property var modelData
            width: Math.min(tagLabel.implicitWidth + Style.spacing.sm * 2,
                            previewContent.width)
            height: Style.space(24)
            radius: Style.space(3)
            color: Util.alpha(root.foreground, 0.06)
            border.width: 1
            border.color: Util.alpha(root.foreground, 0.20)

            Text {
              id: tagLabel
              width: parent.width - Style.spacing.sm * 2
              elide: Text.ElideRight
              anchors.centerIn: parent
              text: String(modelData)
              textFormat: Text.PlainText
              color: root.foreground
              opacity: 0.74
              font.family: Style.font.menuFamily
              font.pixelSize: root.previewFont(Style.font.caption)
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Util.alpha(root.foreground, 0.16)
      }

      Grid {
        id: metricsGrid
        width: parent.width
        columns: 4
        columnSpacing: Style.spacing.sm
        rowSpacing: Style.spacing.sm

        Repeater {
          model: root.metricItems

          delegate: Column {
            required property var modelData
            objectName: "metric" + modelData.label
            width: (metricsGrid.width - metricsGrid.columnSpacing * 3) / 4
            spacing: Style.space(2)

            Row {
              objectName: "metricValue"
              width: parent.width
              spacing: Style.space(4)

              Text {
                text: modelData.icon
                textFormat: Text.PlainText
                color: modelData.color
                font.family: Style.font.family
                font.pixelSize: root.previewFont(Style.font.title - 1)
              }

              Text {
                text: Catalog.formatCount(modelData.value)
                textFormat: Text.PlainText
                color: modelData.color
                font.family: Style.font.menuFamily
                font.pixelSize: root.previewFont(Style.font.title)
                font.bold: true
              }
            }

            Text {
              width: parent.width
              text: modelData.label
              textFormat: Text.PlainText
              color: root.foreground
              opacity: 0.52
              font.family: Style.font.menuFamily
              font.pixelSize: root.previewFont(Style.font.caption)
            }
          }
        }
      }
    }
  }
}
