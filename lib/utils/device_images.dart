/// Bundled photos shown in the Remote Library browser.
///
/// The photos come from Wikimedia Commons; see
/// assets/device_images/ATTRIBUTION.md for the source and license of each one.
class DeviceImages {
  static const String _base = 'assets/device_images/';

  static String forCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('air conditioner') ||
        value == 'ac' ||
        value == 'acs' ||
        value.contains('ac ')) {
      return '${_base}ac.jpg';
    }
    if (value.contains('purifier')) return '${_base}air_purifier.jpg';
    if (value.contains('tv') || value.contains('television')) {
      return '${_base}tv.jpg';
    }
    if (value.contains('fan')) return '${_base}fan.jpg';
    if (value.contains('light')) return '${_base}light.jpg';
    if (value.contains('audio') ||
        value.contains('speaker') ||
        value.contains('soundbar') ||
        value.contains('multimedia')) {
      return '${_base}audio.jpg';
    }
    if (value.contains('projector')) return '${_base}projector.jpg';
    if (value.contains('set top') ||
        value.contains('set-top') ||
        value.contains('cable') ||
        value.contains('streaming') ||
        value.contains('dvb') ||
        value.contains('tuner') ||
        value.contains('blu-ray') ||
        value.contains('dvd') ||
        value.contains('vcr')) {
      return '${_base}settop.jpg';
    }
    if (value.contains('camera')) return '${_base}camera.jpg';
    if (value.contains('console') || value.contains('toy')) {
      return '${_base}console.jpg';
    }
    if (value.contains('vacuum') ||
        value.contains('dust') ||
        value.contains('cleaner')) {
      return '${_base}vacuum.jpg';
    }
    if (value.contains('heater') || value.contains('fireplace')) {
      return '${_base}heater.jpg';
    }
    if (value.contains('humidifier')) return '${_base}humidifier.jpg';
    if (value.contains('remote')) return '${_base}remote.jpg';
    return '${_base}other.jpg';
  }
}
