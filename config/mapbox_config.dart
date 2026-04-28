const String kMapboxAccessToken = String.fromEnvironment(
  'MAPBOX_PUBLIC_TOKEN',
  defaultValue: 'pk.eyJ1IjoiZGFjcmVzIiwiYSI6ImNtbW5odTF1MTAzMzEyb3I4b2FpZjF6dW0ifQ.8Ft3XdkqqmBmSzvOJ0cgww',
);

const String kMapboxStyleOwner = String.fromEnvironment(
  'MAPBOX_STYLE_OWNER',
  defaultValue: 'mapbox',
);

const String kMapboxStyleId = String.fromEnvironment(
  'MAPBOX_STYLE_ID',
  defaultValue: 'streets-v12',
);
