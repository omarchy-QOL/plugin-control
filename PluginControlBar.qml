import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.ilyazar.plugin-control"

  property bool settingsMenuOpen: false
  readonly property var service: root.bar && root.bar.shell
    && typeof root.bar.shell.serviceFor === "function"
    ? root.bar.shell.serviceFor(root.moduleName) : null
  readonly property bool actionFailed: root.service && root.service.actionState
    && root.service.actionState.ok === false
    && root.service.actionState.acknowledged === false
  readonly property bool trayIconHidden:
    setting("trayIconHidden", false) === true

  visible: !trayIconHidden
  implicitWidth: trayIconHidden ? 0 : button.implicitWidth
  implicitHeight: trayIconHidden ? 0 : button.implicitHeight

  function openPalette() {
    if (root.bar && root.bar.shell
        && typeof root.bar.shell.toggle === "function") {
      root.bar.shell.toggle(root.moduleName, "{}")
    }
  }

  function close() {
    settingsMenuOpen = false
  }

  function openSettings() {
    close()
    if (root.bar && root.bar.shell
        && typeof root.bar.shell.toggle === "function") {
      root.bar.shell.toggle(root.moduleName, '{"settings":true}')
    }
  }

  // Omarchy 4.5 fits every bar glyph to one box size. This glyph's own
  // outline is 1.16 times as tall as the round and square glyphs beside it,
  // so the fit shrinks it against them and its inner lines close up.
  readonly property real iconScale: 1.16
  readonly property real iconPaintedSize:
    Math.max(glyph.ink.width, glyph.ink.height) * glyph.fit

  // WidgetButton, not BarIconButton: the host's fit cannot be widened, so
  // the glyph is measured and sized here to keep its own proportion.
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : Style.bar.iconSlot
    fixedHeight: vertical ? Style.bar.iconSlot : -1

    TextMetrics {
      id: inkMetrics
      font.family: glyph.font.family
      // large, so the bounds are not rounded to whole pixels at bar size
      font.pixelSize: glyph.font.pixelSize * 100
      text: glyph.text
    }

    Text {
      id: glyph
      readonly property rect ink: Qt.rect(
        inkMetrics.tightBoundingRect.x / 100,
        inkMetrics.tightBoundingRect.y / 100,
        inkMetrics.tightBoundingRect.width / 100,
        inkMetrics.tightBoundingRect.height / 100)
      // hosts before 4.5 have no icon size and draw the font's own size
      readonly property real fit: Style.bar.iconSize > 0
        ? Style.bar.iconSize * root.iconScale
          / Math.max(1, ink.width, ink.height) : 1
      textFormat: Text.PlainText
      text: "󰏖"
      color: button.active && button.useActiveColor
        ? button.activeColor : button.foreground
      font.family: button.fontFamily
      font.pixelSize: Style.bar.iconFont
      renderType: Text.QtRendering
      transformOrigin: Item.TopLeft
      scale: fit * (button.pressScale > 0 ? button.pressScale : 1)
      x: button.width / 2 - (ink.x + ink.width / 2) * scale
      y: button.height / 2
        - (baselineOffset + ink.y + ink.height / 2) * scale
    }

    tooltipText: "Plugin Control"
    // Keep red bounded to the failed-action notice, not the palette lifetime.
    active: root.actionFailed
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.openPalette()
      else if (buttonCode === Qt.RightButton)
        root.settingsMenuOpen = !root.settingsMenuOpen
    }
  }

  PopupCard {
    id: settingsPopup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.settingsMenuOpen
    padding: Style.spacing.xl
    contentWidth: settingsPopup.fittedContentWidth(Style.space(144))
    contentHeight: settingsPopup.fittedContentHeight(settingsColumn.implicitHeight)

    Column {
      id: settingsColumn
      anchors.fill: parent
      spacing: Style.space(4)

      Button {
        id: settingsButton
        width: parent.width
        text: "Settings"
        leftAlign: false
        verticalPadding: Style.spacing.sm
        onClicked: root.openSettings()
      }

    }
  }
}
