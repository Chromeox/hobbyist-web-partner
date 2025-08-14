// Geo-fencing and Location-based Check-in Utilities
// Advanced location validation, fraud detection, and smart time windows

import { 
  GeoFenceSettings, 
  LocationData, 
  GeoFenceValidation, 
  CheckInWindow,
  ClassSchedule,
  DeviceInfo 
} from './types.ts';
import { calculateDistance } from './utils.ts';

// Smart time window calculations based on class duration
export function calculateCheckInWindow(
  schedule: ClassSchedule,
  durationMinutes: number,
  customWindow?: CheckInWindow
): {
  opensAt: Date;
  closesAt: Date;
  isCurrentlyOpen: boolean;
  minutesUntilOpens?: number;
  minutesUntilCloses?: number;
} {
  const classStartTime = new Date(`${schedule.start_date}T${schedule.start_time}`);
  const now = new Date();

  // Default or custom window settings
  const opensMinutesBefore = customWindow?.opens_minutes_before || 10;
  let closesMinutesAfter: number;

  if (customWindow?.closes_minutes_after && !customWindow.dynamic_closing) {
    closesMinutesAfter = customWindow.closes_minutes_after;
  } else {
    // Dynamic closing based on class duration
    if (durationMinutes <= 60) {
      closesMinutesAfter = 5;
    } else if (durationMinutes <= 120) {
      closesMinutesAfter = 10;
    } else {
      closesMinutesAfter = 20;
    }
  }

  const opensAt = new Date(classStartTime.getTime() - (opensMinutesBefore * 60 * 1000));
  const closesAt = new Date(classStartTime.getTime() + (closesMinutesAfter * 60 * 1000));

  const isCurrentlyOpen = now >= opensAt && now <= closesAt;
  
  let minutesUntilOpens: number | undefined;
  let minutesUntilCloses: number | undefined;

  if (now < opensAt) {
    minutesUntilOpens = Math.ceil((opensAt.getTime() - now.getTime()) / (1000 * 60));
  } else if (now <= closesAt) {
    minutesUntilCloses = Math.ceil((closesAt.getTime() - now.getTime()) / (1000 * 60));
  }

  return {
    opensAt,
    closesAt,
    isCurrentlyOpen,
    minutesUntilOpens,
    minutesUntilCloses,
  };
}

// Comprehensive geo-fence validation
export function validateGeoFence(
  userLocation: LocationData,
  geoFence: GeoFenceSettings,
  schedule: ClassSchedule,
  durationMinutes: number
): GeoFenceValidation {
  const reasons: string[] = [];
  
  // Calculate distance from venue center
  const distanceMeters = calculateDistance(
    userLocation.latitude,
    userLocation.longitude,
    geoFence.center_lat,
    geoFence.center_lng
  ) * 1609.34; // Convert miles to meters

  // Check if within geo-fence radius
  const withinFence = distanceMeters <= geoFence.radius_meters;
  if (!withinFence) {
    reasons.push(`Outside geo-fence: ${Math.round(distanceMeters)}m from venue (limit: ${geoFence.radius_meters}m)`);
  }

  // Check GPS accuracy
  const accuracyThreshold = geoFence.accuracy_threshold || 50; // Default 50m accuracy
  const accuracySufficient = userLocation.accuracy <= accuracyThreshold;
  if (!accuracySufficient) {
    reasons.push(`GPS accuracy insufficient: ${userLocation.accuracy}m (required: <${accuracyThreshold}m)`);
  }

  // Check time window
  const timeWindow = calculateCheckInWindow(schedule, durationMinutes, geoFence.check_in_window);
  const timeWindowValid = timeWindow.isCurrentlyOpen;
  if (!timeWindowValid) {
    if (timeWindow.minutesUntilOpens) {
      reasons.push(`Check-in opens in ${timeWindow.minutesUntilOpens} minute(s)`);
    } else {
      reasons.push('Check-in window has closed');
    }
  }

  // Overall check-in allowed status
  const checkInAllowed = geoFence.enabled ? 
    (withinFence && accuracySufficient && timeWindowValid) :
    timeWindowValid; // If geo-fence disabled, only check time

  return {
    within_fence: withinFence,
    distance_meters: distanceMeters,
    accuracy_sufficient: accuracySufficient,
    time_window_valid: timeWindowValid,
    check_in_allowed: checkInAllowed,
    reasons: reasons.length > 0 ? reasons : undefined,
  };
}

// Location fraud detection algorithms
export function detectLocationFraud(
  currentLocation: LocationData,
  previousLocations: LocationData[],
  deviceInfo: DeviceInfo
): {
  suspiciousActivity: boolean;
  fraudScore: number; // 0-100, higher = more suspicious
  flags: string[];
} {
  const flags: string[] = [];
  let fraudScore = 0;

  // Check for impossible travel speed
  if (previousLocations.length > 0) {
    const lastLocation = previousLocations[previousLocations.length - 1];
    const timeDiff = new Date(currentLocation.timestamp).getTime() - new Date(lastLocation.timestamp).getTime();
    const timeDiffHours = timeDiff / (1000 * 60 * 60);
    
    if (timeDiffHours > 0) {
      const distanceKm = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        lastLocation.latitude,
        lastLocation.longitude
      ) * 1.609344; // Convert miles to km
      
      const speedKmh = distanceKm / timeDiffHours;
      
      // Flag impossible speeds (>1000 km/h suggests teleportation/spoofing)
      if (speedKmh > 1000) {
        flags.push(`Impossible travel speed: ${Math.round(speedKmh)} km/h`);
        fraudScore += 50;
      } else if (speedKmh > 500) {
        flags.push(`Very high travel speed: ${Math.round(speedKmh)} km/h`);
        fraudScore += 25;
      }
    }
  }

  // Check for suspiciously perfect accuracy
  if (currentLocation.accuracy < 1) {
    flags.push('Suspiciously perfect GPS accuracy');
    fraudScore += 15;
  }

  // Check for rounded coordinates (potential spoofing)
  const latDecimalPlaces = (currentLocation.latitude.toString().split('.')[1] || '').length;
  const lngDecimalPlaces = (currentLocation.longitude.toString().split('.')[1] || '').length;
  
  if (latDecimalPlaces < 4 || lngDecimalPlaces < 4) {
    flags.push('Location coordinates appear rounded/simplified');
    fraudScore += 10;
  }

  // Check device consistency
  if (!deviceInfo.location_services_enabled && currentLocation.accuracy < 10) {
    flags.push('High accuracy location without location services enabled');
    fraudScore += 20;
  }

  // Check for repeated identical locations
  const identicalLocations = previousLocations.filter(loc => 
    loc.latitude === currentLocation.latitude && 
    loc.longitude === currentLocation.longitude
  ).length;

  if (identicalLocations > 3) {
    flags.push('Multiple identical location reports');
    fraudScore += 15;
  }

  // Check location source consistency
  const recentSources = previousLocations.slice(-5).map(loc => loc.source);
  if (recentSources.length > 0 && !recentSources.includes(currentLocation.source)) {
    const sourceChanges = new Set(recentSources).size;
    if (sourceChanges > 2) {
      flags.push('Frequent location source changes');
      fraudScore += 10;
    }
  }

  return {
    suspiciousActivity: fraudScore >= 30,
    fraudScore: Math.min(fraudScore, 100),
    flags,
  };
}

// Privacy-aware location rounding
export function roundLocationForPrivacy(
  location: LocationData,
  precisionMeters = 10
): LocationData {
  // Convert precision from meters to approximate decimal degrees
  // 1 degree ≈ 111,320 meters at equator
  const precisionDegrees = precisionMeters / 111320;
  
  const roundTo = Math.pow(10, Math.ceil(Math.log10(1 / precisionDegrees)));
  
  return {
    ...location,
    latitude: Math.round(location.latitude * roundTo) / roundTo,
    longitude: Math.round(location.longitude * roundTo) / roundTo,
    privacy_rounded: true,
  };
}

// Generate optimal geo-fence settings based on venue type
export function generateGeoFenceSettings(
  centerLat: number,
  centerLng: number,
  venueType: 'indoor_studio' | 'outdoor_park' | 'large_facility' | 'home_studio' | 'online',
  customRadius?: number
): GeoFenceSettings | null {
  if (venueType === 'online') {
    return null; // No geo-fence for online classes
  }

  const radiusMap = {
    indoor_studio: 100,     // Small studios
    home_studio: 50,        // Private homes
    outdoor_park: 300,      // Parks and outdoor spaces
    large_facility: 500,    // Gyms, recreation centers
  };

  const radius = customRadius || radiusMap[venueType];
  const accuracyMap = {
    indoor_studio: 20,      // More lenient for indoor GPS
    home_studio: 15,        // Stricter for private locations
    outdoor_park: 10,       // Good GPS expected outdoors
    large_facility: 30,     // Large buildings may affect GPS
  };

  return {
    enabled: true,
    center_lat: centerLat,
    center_lng: centerLng,
    radius_meters: radius,
    accuracy_threshold: accuracyMap[venueType],
    check_in_window: {
      opens_minutes_before: 10,
      dynamic_closing: true,
    },
    fallback_options: {
      allow_manual_override: true,
      instructor_override_required: venueType === 'home_studio', // Stricter for home studios
      alternative_methods: ['instructor_confirmation'],
      emergency_bypass: true,
    },
  };
}

// Check if location permission is required
export function shouldRequestLocationPermission(
  geoFence?: GeoFenceSettings | null,
  classType?: 'in_person' | 'online' | 'hybrid'
): {
  required: boolean;
  reason: string;
  urgency: 'optional' | 'recommended' | 'required';
} {
  if (!geoFence || classType === 'online') {
    return {
      required: false,
      reason: 'Location not needed for this class type',
      urgency: 'optional',
    };
  }

  if (!geoFence.enabled) {
    return {
      required: false,
      reason: 'Geo-fence is disabled for this class',
      urgency: 'optional',
    };
  }

  const hasAlternatives = geoFence.fallback_options?.alternative_methods.length > 0;
  
  return {
    required: true,
    reason: hasAlternatives ? 
      'Location is required for check-in, or use alternative method' :
      'Location is required for check-in at this venue',
    urgency: hasAlternatives ? 'recommended' : 'required',
  };
}

// Calculate recommended notification times for location-based check-ins
export function calculateLocationNotificationTimes(
  classSchedule: ClassSchedule,
  geoFence: GeoFenceSettings,
  estimatedTravelTimeMinutes?: number
): {
  initialNotification: Date;
  approachingVenueNotification?: Date;
  checkInReminderNotification: Date;
} {
  const classStartTime = new Date(`${classSchedule.start_date}T${classSchedule.start_time}`);
  const checkInOpens = new Date(classStartTime.getTime() - (geoFence.check_in_window?.opens_minutes_before || 10) * 60 * 1000);
  
  // Initial notification: 2 hours before (if travel time unknown) or travel time + buffer
  const travelBuffer = estimatedTravelTimeMinutes ? estimatedTravelTimeMinutes + 30 : 120;
  const initialNotification = new Date(classStartTime.getTime() - travelBuffer * 60 * 1000);
  
  // Approaching venue notification: 30 minutes before class (if travel time known)
  let approachingVenueNotification: Date | undefined;
  if (estimatedTravelTimeMinutes) {
    approachingVenueNotification = new Date(classStartTime.getTime() - 30 * 60 * 1000);
  }
  
  // Check-in reminder: 5 minutes after check-in opens
  const checkInReminderNotification = new Date(checkInOpens.getTime() + 5 * 60 * 1000);
  
  return {
    initialNotification,
    approachingVenueNotification,
    checkInReminderNotification,
  };
}

// Validate location data quality
export function validateLocationQuality(location: LocationData): {
  isValid: boolean;
  quality: 'excellent' | 'good' | 'fair' | 'poor';
  issues: string[];
} {
  const issues: string[] = [];
  let quality: 'excellent' | 'good' | 'fair' | 'poor' = 'excellent';

  // Check basic validity
  if (Math.abs(location.latitude) > 90) {
    issues.push('Invalid latitude value');
  }
  if (Math.abs(location.longitude) > 180) {
    issues.push('Invalid longitude value');
  }
  if (location.accuracy < 0) {
    issues.push('Invalid accuracy value');
  }

  // Assess quality based on accuracy
  if (location.accuracy > 100) {
    quality = 'poor';
    issues.push('Very poor GPS accuracy');
  } else if (location.accuracy > 50) {
    quality = 'fair';
    issues.push('Poor GPS accuracy');
  } else if (location.accuracy > 20) {
    quality = 'good';
  }

  // Check timestamp freshness
  const locationAge = Date.now() - new Date(location.timestamp).getTime();
  const locationAgeMinutes = locationAge / (1000 * 60);
  
  if (locationAgeMinutes > 5) {
    issues.push('Location data is stale');
    if (quality === 'excellent') quality = 'good';
  }
  if (locationAgeMinutes > 15) {
    if (quality === 'good') quality = 'fair';
  }
  if (locationAgeMinutes > 30) {
    if (quality === 'fair') quality = 'poor';
  }

  return {
    isValid: issues.length === 0 || !issues.some(issue => 
      issue.includes('Invalid') || issue.includes('Very poor')
    ),
    quality,
    issues,
  };
}