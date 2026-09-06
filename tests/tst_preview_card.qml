import QtQuick
import QtTest
import ".."

TestCase {
  id: testCase
  name: "PreviewCard"
  width: 400
  height: 650
  visible: true
  when: windowShown
  property var card: null

  Component {
    id: cardComponent
    PreviewCard {
      width: 320
      height: implicitHeight
      plugin: ({
        id: "test.preview",
        name: "20-20-20 Eye Breaks",
        description: "A plugin preview",
        repository: "https://github.com/example/preview",
        marketplaceListed: true,
        verificationStatus: "unverified",
        stars: 0,
        metricsAvailable: false,
        previewThumbnailUrl: "https://example.com/preview.webp"
      })
      imageLoading: true
    }
  }

  SignalSpy { id: information; signalName: "informationRequested" }

  function init() {
    card = createTemporaryObject(cardComponent, testCase)
    verify(card)
    information.target = card
    information.clear()
    waitForRendering(card)
  }

  function cleanup() {
    information.target = null
    card.destroy()
  }

  function test_imageAndBodyOpenInformation() {
    verify(card.height > 100, "height " + card.height)
    verify(card.width === 320)
    mouseClick(card, 120, 80, Qt.LeftButton)
    tryCompare(information, "count", 1)
    mouseClick(card, 120, card.height - 20, Qt.LeftButton)
    tryCompare(information, "count", 2)
    mouseClick(card, 120, 80, Qt.RightButton)
    compare(information.count, 2)
  }

  function test_missingMetricsDoNotBecomeZero() {
    compare(card.metricItems.length, 1)
    compare(card.metricItems[0].label, "Stars")
    compare(card.metricItems[0].value, 0)
    card.plugin = {id: "local.only", name: "Local", metricsAvailable: false}
    compare(card.metricItems.length, 0)
    compare(card.badgeItems.length, 0)
  }

  function test_clippedContentCanBeDragged() {
    card.height = 200
    var viewport = findChild(card, "previewViewport")
    verify(viewport)
    mouseDrag(card, 120, 160, 0, -90, Qt.LeftButton)
    verify(viewport.contentY > 0)
    compare(information.count, 0)
  }

  function test_fourMetricsShareOneRow() {
    card.plugin = {id: "metrics", name: "Metrics", stars: 999,
      hearts: 1000, views: 12500, copies: 999999, metricsAvailable: true}
    waitForRendering(card)
    var labels = ["Stars", "Hearts", "Views", "Copies"]
    var first = findChild(card, "metricStars")
    for (var i = 0; i < labels.length; i++) {
      var metric = findChild(card, "metric" + labels[i])
      verify(metric)
      compare(metric.y, first.y)
      verify(metric.x + metric.width <= metric.parent.width + 1)
      var value = findChild(metric, "metricValue")
      verify(value.implicitWidth <= metric.width,
        labels[i] + " icon and count must fit")
    }
  }
}
