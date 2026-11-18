import QtQuick
import QtQuick.Window
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
  readonly property real iconPaintedSize: iconBox.longest * iconBox.fit

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

    Item {
      id: iconBox
      // An edge drawn between device pixels smears over two of them, so the
      // outline is sized and placed on whole pixels. Qt's Screen ratio is
      // integral; the window carries the fractional one.
      readonly property real dpr: Window.window
        ? Window.window.devicePixelRatio : 1
      readonly property real longest:
        Math.max(1, glyph.ink.width, glyph.ink.height)
      // hosts before 4.5 have no icon size and draw the font's own size
      readonly property real fit: Style.bar.iconSize > 0
        ? Math.round(Style.bar.iconSize * root.iconScale * dpr) / dpr / longest
        : 1
      property real snapX: 0
      property real snapY: 0

      function align() {
        var p = button.mapToItem(null, (button.width - width) / 2,
          (button.height - height) / 2)
        snapX = Math.round(p.x * dpr) / dpr - p.x
        snapY = Math.round(p.y * dpr) / dpr - p.y
      }

      width: glyph.ink.width * fit
      height: glyph.ink.height * fit
      x: (button.width - width) / 2 + snapX
      y: (button.height - height) / 2 + snapY
      scale: button.pressScale > 0 ? button.pressScale : 1

      // The bar moves widgets as neighbours resize; re-snap before each frame.
      Connections {
        target: iconBox.Window.window
        function onAfterAnimating() { iconBox.align() }
      }

      Text {
        id: glyph
        readonly property rect ink: Qt.rect(
          inkMetrics.tightBoundingRect.x / 100,
          inkMetrics.tightBoundingRect.y / 100,
          inkMetrics.tightBoundingRect.width / 100,
          inkMetrics.tightBoundingRect.height / 100)
        textFormat: Text.PlainText
        text: "󰏖"
        color: button.active && button.useActiveColor
          ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.bar.iconFont
        // Curves, not the default distance field: that one antialiases per
        // colour channel, which fringes this glyph's many thin edges.
        renderType: Text.CurveRendering
        transformOrigin: Item.TopLeft
        scale: iconBox.fit
        x: -ink.x * scale
        y: -(baselineOffset + ink.y) * scale
      }
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
