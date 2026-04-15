const EARTH_RADIUS_MILES = 3958.8;

function toRadians(value: number): number {
  return (value * Math.PI) / 180;
}

export function haversineDistanceMiles(
  latitudeA: number,
  longitudeA: number,
  latitudeB: number,
  longitudeB: number,
): number {
  const latitudeDelta = toRadians(latitudeB - latitudeA);
  const longitudeDelta = toRadians(longitudeB - longitudeA);
  const radLatitudeA = toRadians(latitudeA);
  const radLatitudeB = toRadians(latitudeB);

  const a =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(radLatitudeA) * Math.cos(radLatitudeB) * Math.sin(longitudeDelta / 2) ** 2;

  return 2 * EARTH_RADIUS_MILES * Math.asin(Math.sqrt(a));
}

export function isPointInBounds(
  latitude: number,
  longitude: number,
  north: number,
  south: number,
  east: number,
  west: number,
): boolean {
  return latitude <= north && latitude >= south && longitude <= east && longitude >= west;
}
