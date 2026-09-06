pragma Singleton
import QtQuick

QtObject {
  function surfaceSpec(section, key, color, width) {
    return { color: color, width: width }
  }
}
