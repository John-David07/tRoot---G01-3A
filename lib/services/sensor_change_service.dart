import 'dart:async';

class SensorChangeService {
  static final StreamController<int> _controller = StreamController<int>.broadcast();
  
  static Stream<int> get sensorChanges => _controller.stream;
  
  static void notifySensorChanged(int index) {
    _controller.add(index);
  }
  
  static void dispose() {
    _controller.close();
  }
}