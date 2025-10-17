import type {
  CalendarIntegration,
  ImportedEvent,
  ImportResult,
  EventMapping,
  SquareSettings,
  SquareBooking,
  SquareService,
  SquareTeamMember
} from '@/types/calendar-integration';
import { toError } from '@/lib/utils/integration-helpers';

export class SquareIntegration {
  private apiBaseUrl = 'https://connect.squareup.com';
  private accessToken: string;
  private applicationId: string;

  constructor(
    private integration: CalendarIntegration,
    private settings: SquareSettings
  ) {
    this.accessToken = integration.access_token || '';
    this.applicationId = process.env.SQUARE_APPLICATION_ID || '';
  }

  /**
   * Get Square OAuth authorization URL for initial setup
   */
  static getAuthUrl(): string {
    const scopes = [
      'BOOKINGS_READ',
      'BOOKINGS_WRITE',
      'MERCHANT_PROFILE_READ',
      'CUSTOMERS_READ'
    ].join('%20');

    const params = new URLSearchParams({
      client_id: process.env.SQUARE_APPLICATION_ID || '',
      scope: scopes,
      session: 'false',
      state: 'square_integration'
    });

    return `https://connect.squareup.com/oauth2/authorize?${params.toString()}`;
  }

  /**
   * Exchange authorization code for access token
   */
  static async exchangeCodeForTokens(code: string) {
    const response = await fetch('https://connect.squareup.com/oauth2/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Square-Version': '2023-10-18',
      },
      body: JSON.stringify({
        client_id: process.env.SQUARE_APPLICATION_ID,
        client_secret: process.env.SQUARE_APPLICATION_SECRET,
        code,
        grant_type: 'authorization_code'
      }),
    });

    if (!response.ok) {
      throw new Error(`Square token exchange failed: ${response.statusText}`);
    }

    return await response.json();
  }

  /**
   * Test the Square connection
   */
  async testConnection(): Promise<boolean> {
    try {
      const response = await this.makeApiRequest('/v2/merchants');
      return !!response.merchant?.[0];
    } catch (error) {
      const err = toError(error);
      console.error('Square connection test failed:', err);
      return false;
    }
  }

  /**
   * Get merchant information and locations
   */
  async getMerchantInfo() {
    const merchants = await this.makeApiRequest('/v2/merchants');
    const locations = await this.makeApiRequest('/v2/locations');

    return {
      merchant: merchants.merchant?.[0],
      locations: locations.locations || []
    };
  }

  /**
   * Fetch services (catalog items for bookings)
   */
  async fetchServices(): Promise<SquareService[]> {
    try {
      const response = await this.makeApiRequest('/v2/catalog/list', {
        method: 'GET'
      });

      // Filter for service items
      const services = response.objects?.filter(
        (item: any) => item.type === 'ITEM' &&
        item.item_data?.variations?.some((v: any) => v.item_variation_data?.service_duration)
      ) || [];

      return services.map(this.convertCatalogItemToService);
    } catch (error) {
      const err = toError(error);
      console.error('Failed to fetch Square services:', err);
      throw new Error(`Square API error: ${err.message}`);
    }
  }

  /**
   * Fetch team members who can provide services
   */
  async fetchTeamMembers(): Promise<SquareTeamMember[]> {
    try {
      const response = await this.makeApiRequest('/v2/team-members');
      return response.team_members || [];
    } catch (error) {
      const err = toError(error);
      console.error('Failed to fetch Square team members:', err);
      return [];
    }
  }

  /**
   * Fetch bookings from Square
   */
  async fetchBookings(
    startDate: Date,
    endDate: Date
  ): Promise<SquareBooking[]> {
    try {
      const response = await this.makeApiRequest('/v2/bookings/search', {
        method: 'POST',
        body: JSON.stringify({
          filter: {
            start_at_range: {
              start_at: startDate.toISOString(),
              end_at: endDate.toISOString()
            },
            location_id: this.settings.location_id
          }
        })
      });

      return response.bookings || [];
    } catch (error) {
      const err = toError(error);
      console.error('Failed to fetch Square bookings:', err);
      throw new Error(`Square API error: ${err.message}`);
    }
  }

  /**
   * Convert Square catalog item to service format
   */
  private convertCatalogItemToService(catalogItem: any): SquareService {
    const variation = catalogItem.item_data?.variations?.[0];
    const serviceData = variation?.item_variation_data;

    return {
      id: catalogItem.id,
      name: catalogItem.item_data?.name || 'Unknown Service',
      description: catalogItem.item_data?.description,
      duration_minutes: serviceData?.service_duration ?
        Math.round(parseInt(serviceData.service_duration) / 60000) : 60,
      price: serviceData?.price_money ?
        parseFloat(serviceData.price_money.amount) / 100 : 0,
      category: catalogItem.item_data?.category_id,
      variation_id: variation.id
    };
  }

  /**
   * Convert Square booking to ImportedEvent format
   */
  private async convertToImportedEvent(
    booking: SquareBooking,
    services: SquareService[],
    teamMembers: SquareTeamMember[]
  ): Promise<Partial<ImportedEvent>> {
    const startTime = booking.appointment_segments?.[0]?.start_at;
    const endTime = booking.appointment_segments?.[0]?.end_at;

    // Find the service details
    const serviceId = booking.appointment_segments?.[0]?.service_variation_id;
    const service = services.find(s => s.variation_id === serviceId);

    // Find the team member (instructor)
    const teamMemberId = booking.appointment_segments?.[0]?.team_member_id;
    const teamMember = teamMembers.find(tm => tm.id === teamMemberId);

    // Extract workshop details from service name and description
    const { category, skillLevel, maxParticipants } = this.extractWorkshopDetails(
      service?.name || 'Unknown Service',
      service?.description
    );

    return {
      external_id: booking.id,
      provider: 'square',
      title: service?.name || 'Square Appointment',
      description: service?.description,
      start_time: startTime,
      end_time: endTime,
      all_day: false,
      location: booking.location_id,
      instructor_name: teamMember ? `${teamMember.given_name} ${teamMember.family_name}` : undefined,
      instructor_email: teamMember?.email_address,
      category,
      skill_level: skillLevel,
      max_participants: maxParticipants || 1,
      current_participants: booking.appointment_segments?.[0]?.any_team_member_id ? 1 : 0,
      price: service?.price,
      migration_status: 'pending',
      raw_data: booking,
    };
  }

  /**
   * Extract workshop details from service name and description
   */
  private extractWorkshopDetails(name: string, description?: string) {
    const text = `${name} ${description || ''}`.toLowerCase();

    // Category detection
    let category = 'general';
    if (text.includes('pottery') || text.includes('ceramic')) category = 'pottery';
    else if (text.includes('paint') || text.includes('canvas') || text.includes('art')) category = 'painting';
    else if (text.includes('wood') || text.includes('carpentry')) category = 'woodworking';
    else if (text.includes('jewelry') || text.includes('beading')) category = 'jewelry';
    else if (text.includes('cook') || text.includes('baking') || text.includes('culinary')) category = 'cooking';
    else if (text.includes('music') || text.includes('guitar') || text.includes('piano')) category = 'music';
    else if (text.includes('fitness') || text.includes('yoga') || text.includes('workout')) category = 'fitness';
    else if (text.includes('craft') || text.includes('diy')) category = 'crafts';
    else if (text.includes('massage') || text.includes('spa') || text.includes('beauty')) category = 'wellness';
    else if (text.includes('consult') || text.includes('appointment') || text.includes('session')) category = 'consultation';

    // Skill level detection
    let skillLevel = 'beginner';
    if (text.includes('advanced') || text.includes('expert') || text.includes('master')) skillLevel = 'advanced';
    else if (text.includes('intermediate') || text.includes('level 2')) skillLevel = 'intermediate';
    else if (text.includes('all levels') || text.includes('any level')) skillLevel = 'all_levels';

    // Max participants extraction (often for group sessions)
    let maxParticipants: number | undefined;
    const participantMatch = text.match(/(\d+)\s*(people|participants|students|max|group)/);
    if (participantMatch) {
      maxParticipants = parseInt(participantMatch[1]);
    }

    return { category, skillLevel, maxParticipants };
  }

  /**
   * Import bookings from Square
   */
  async importEvents(
    startDate: Date,
    endDate: Date
  ): Promise<ImportResult> {
    try {
      const [bookings, services, teamMembers] = await Promise.all([
        this.fetchBookings(startDate, endDate),
        this.fetchServices(),
        this.fetchTeamMembers()
      ]);

      const importedEvents: Partial<ImportedEvent>[] = [];
      const errors: string[] = [];

      for (const booking of bookings) {
        try {
          const importedEvent = await this.convertToImportedEvent(booking, services, teamMembers);
          importedEvents.push(importedEvent);
        } catch (error) {
          const err = toError(error);
          errors.push(`Failed to convert booking ${booking.id}: ${err.message}`);
        }
      }

      // Generate mapping suggestions
      const mappingSuggestions = await this.generateMappingSuggestions(importedEvents);

      return {
        total_events: bookings.length,
        successfully_imported: importedEvents.length,
        failed_imports: errors.length,
        requires_review: mappingSuggestions.filter(m => m.requires_manual_review).length,
        duplicate_events: 0, // TODO: Implement duplicate detection
        error_details: errors,
        mapping_suggestions: mappingSuggestions,
      };
    } catch (error) {
      const err = toError(error);
      throw new Error(`Square import failed: ${err.message}`);
    }
  }

  /**
   * Generate smart mapping suggestions for imported events
   */
  private async generateMappingSuggestions(
    events: Partial<ImportedEvent>[]
  ): Promise<EventMapping[]> {
    const mappings: EventMapping[] = [];

    for (const event of events) {
      const mapping: EventMapping = {
        original_event: event as ImportedEvent,
        confidence_score: 0,
        mapping_reasons: [],
        requires_manual_review: true,
      };

      // Auto-mapping logic based on service data
      if (event.category && event.category !== 'general') {
        mapping.confidence_score += 0.4;
        mapping.mapping_reasons.push(`Category detected: ${event.category}`);
      }

      if (event.price && event.price > 0) {
        mapping.confidence_score += 0.3;
        mapping.mapping_reasons.push('Pricing information available');
      }

      if (event.instructor_email) {
        mapping.confidence_score += 0.3;
        mapping.mapping_reasons.push('Instructor information found');
      }

      if (event.max_participants && event.max_participants > 1) {
        mapping.confidence_score += 0.2;
        mapping.mapping_reasons.push('Group session detected');
      }

      // Square bookings tend to be well-structured
      if (event.title && !event.title.includes('Unknown')) {
        mapping.confidence_score += 0.2;
        mapping.mapping_reasons.push('Complete service information');
      }

      // High confidence events don't need manual review
      if (mapping.confidence_score >= 0.8) {
        mapping.requires_manual_review = false;
      }

      mappings.push(mapping);
    }

    return mappings;
  }

  /**
   * Create a new booking in Square (for two-way sync)
   */
  async createBooking(
    serviceVariationId: string,
    teamMemberId: string,
    startTime: Date,
    durationMinutes: number,
    customerEmail?: string
  ): Promise<string> {
    try {
      const endTime = new Date(startTime.getTime() + durationMinutes * 60000);

      const response = await this.makeApiRequest('/v2/bookings', {
        method: 'POST',
        body: JSON.stringify({
          booking: {
            location_id: this.settings.location_id,
            appointment_segments: [{
              start_at: startTime.toISOString(),
              end_at: endTime.toISOString(),
              service_variation_id: serviceVariationId,
              team_member_id: teamMemberId
            }],
            customer_note: 'Created via Hobbyist Studio Management'
          }
        })
      });

      return response.booking.id;
    } catch (error) {
      throw new Error(`Failed to create Square booking: ${error.message}`);
    }
  }

  /**
   * Update existing booking in Square
   */
  async updateBooking(
    bookingId: string,
    startTime: Date,
    durationMinutes: number
  ): Promise<void> {
    try {
      const endTime = new Date(startTime.getTime() + durationMinutes * 60000);

      await this.makeApiRequest(`/v2/bookings/${bookingId}`, {
        method: 'PUT',
        body: JSON.stringify({
          booking: {
            appointment_segments: [{
              start_at: startTime.toISOString(),
              end_at: endTime.toISOString()
            }]
          }
        })
      });
    } catch (error) {
      throw new Error(`Failed to update Square booking: ${error.message}`);
    }
  }

  /**
   * Cancel booking in Square
   */
  async cancelBooking(bookingId: string): Promise<void> {
    try {
      await this.makeApiRequest(`/v2/bookings/${bookingId}/cancel`, {
        method: 'POST',
        body: JSON.stringify({
          booking_version: 1 // Square requires version number
        })
      });
    } catch (error) {
      throw new Error(`Failed to cancel Square booking: ${error.message}`);
    }
  }

  /**
   * Set up webhook for real-time booking updates
   */
  async createWebhook(webhookUrl: string, events: string[] = ['booking.created', 'booking.updated']) {
    try {
      const response = await this.makeApiRequest('/v2/webhooks/subscriptions', {
        method: 'POST',
        body: JSON.stringify({
          subscription: {
            name: 'Hobbyist Studio Bookings Webhook',
            event_types: events,
            notification_url: webhookUrl,
            api_version: '2023-10-18'
          }
        })
      });

      return response.subscription;
    } catch (error) {
      throw new Error(`Failed to create Square webhook: ${error.message}`);
    }
  }

  /**
   * Process webhook payload for real-time sync
   */
  static processWebhookPayload(payload: any): {
    eventType: string;
    eventData: Partial<ImportedEvent>;
  } | null {
    try {
      const { type, data } = payload;

      if (!type || !data) {
        return null;
      }

      let eventData: Partial<ImportedEvent>;

      if (type === 'booking.created' || type === 'booking.updated') {
        const booking = data.object?.booking;
        if (!booking) return null;

        eventData = {
          external_id: booking.id,
          provider: 'square',
          title: 'Square Appointment',
          start_time: booking.appointment_segments?.[0]?.start_at,
          end_time: booking.appointment_segments?.[0]?.end_at,
          location: booking.location_id,
          migration_status: 'pending',
          raw_data: booking,
        };
      } else {
        return null;
      }

      return {
        eventType: type,
        eventData
      };
    } catch (error) {
      console.error('Failed to process Square webhook:', error);
      return null;
    }
  }

  /**
   * Make authenticated API request to Square
   */
  private async makeApiRequest(endpoint: string, options: RequestInit = {}) {
    const url = endpoint.startsWith('http') ? endpoint : `${this.apiBaseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
        'Square-Version': '2023-10-18',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(`Square API error: ${response.status} ${response.statusText} - ${errorData.errors?.[0]?.detail || 'Unknown error'}`);
    }

    return await response.json();
  }

  /**
   * Refresh access token if needed
   */
  async refreshTokenIfNeeded(): Promise<boolean> {
    try {
      // Square access tokens are long-lived, but test the connection
      return await this.testConnection();
    } catch (error) {
      console.error('Failed to refresh Square token:', error);
      return false;
    }
  }
}
