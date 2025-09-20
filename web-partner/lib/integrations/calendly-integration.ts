import type {
  CalendarIntegration,
  ImportedEvent,
  ImportResult,
  EventMapping,
  CalendlySettings,
  CalendlyEvent,
  CalendlyEventType
} from '@/types/calendar-integration';

export class CalendlyIntegration {
  private apiBaseUrl = 'https://api.calendly.com';
  private accessToken: string;

  constructor(
    private integration: CalendarIntegration,
    private settings: CalendlySettings
  ) {
    this.accessToken = integration.access_token || '';
  }

  /**
   * Get Calendly OAuth authorization URL for initial setup
   */
  static getAuthUrl(): string {
    const scopes = [
      'read:scheduled_events',
      'read:event_types',
      'read:users',
      'read:organizations'
    ].join('%20');

    const params = new URLSearchParams({
      client_id: process.env.CALENDLY_CLIENT_ID || '',
      response_type: 'code',
      redirect_uri: process.env.CALENDLY_REDIRECT_URI || '',
      scope: scopes,
      state: 'calendly_integration'
    });

    return `https://auth.calendly.com/oauth/authorize?${params.toString()}`;
  }

  /**
   * Exchange authorization code for access token
   */
  static async exchangeCodeForTokens(code: string) {
    const response = await fetch('https://auth.calendly.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        grant_type: 'authorization_code',
        client_id: process.env.CALENDLY_CLIENT_ID,
        client_secret: process.env.CALENDLY_CLIENT_SECRET,
        redirect_uri: process.env.CALENDLY_REDIRECT_URI,
        code,
      }),
    });

    if (!response.ok) {
      throw new Error(`Calendly token exchange failed: ${response.statusText}`);
    }

    return await response.json();
  }

  /**
   * Test the Calendly connection
   */
  async testConnection(): Promise<boolean> {
    try {
      const response = await this.makeApiRequest('/users/me');
      return !!response.resource;
    } catch (error) {
      console.error('Calendly connection test failed:', error);
      return false;
    }
  }

  /**
   * Get user information and organization details
   */
  async getUserInfo() {
    const user = await this.makeApiRequest('/users/me');
    const organization = await this.makeApiRequest(`/organizations/${user.resource.current_organization}`);

    return {
      user: user.resource,
      organization: organization.resource
    };
  }

  /**
   * Fetch event types for the user
   */
  async fetchEventTypes(): Promise<CalendlyEventType[]> {
    try {
      const user = await this.getUserInfo();
      const response = await this.makeApiRequest(
        `/event_types?user=${user.user.uri}&active=true`
      );

      return response.collection || [];
    } catch (error) {
      console.error('Failed to fetch Calendly event types:', error);
      throw new Error(`Calendly API error: ${error.message}`);
    }
  }

  /**
   * Fetch scheduled events from Calendly
   */
  async fetchEvents(
    startDate: Date,
    endDate: Date
  ): Promise<CalendlyEvent[]> {
    try {
      const user = await this.getUserInfo();
      const params = new URLSearchParams({
        user: user.user.uri,
        min_start_time: startDate.toISOString(),
        max_start_time: endDate.toISOString(),
        status: 'active',
        sort: 'start_time:asc'
      });

      const response = await this.makeApiRequest(`/scheduled_events?${params.toString()}`);

      return response.collection || [];
    } catch (error) {
      console.error('Failed to fetch Calendly events:', error);
      throw new Error(`Calendly API error: ${error.message}`);
    }
  }

  /**
   * Convert Calendly event to ImportedEvent format
   */
  private convertToImportedEvent(
    calendlyEvent: CalendlyEvent,
    eventType?: CalendlyEventType
  ): Partial<ImportedEvent> {
    const startTime = calendlyEvent.start_time;
    const endTime = calendlyEvent.end_time;

    // Extract workshop details from event type and name
    const { category, skillLevel, maxParticipants, price } = this.extractWorkshopDetails(
      eventType?.name || calendlyEvent.name,
      eventType?.description
    );

    return {
      external_id: calendlyEvent.uri.split('/').pop(),
      provider: 'calendly',
      title: eventType?.name || calendlyEvent.name,
      description: eventType?.description,
      start_time: startTime,
      end_time: endTime,
      all_day: false,
      location: calendlyEvent.location?.location,
      instructor_name: calendlyEvent.event_memberships?.[0]?.user_name,
      instructor_email: calendlyEvent.event_memberships?.[0]?.user_email,
      category,
      skill_level: skillLevel,
      max_participants: maxParticipants,
      current_participants: calendlyEvent.invitees_counter?.total || 1,
      price,
      migration_status: 'pending',
      raw_data: calendlyEvent,
    };
  }

  /**
   * Extract workshop details from event type name and description
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

    // Skill level detection
    let skillLevel = 'beginner';
    if (text.includes('advanced') || text.includes('expert') || text.includes('master')) skillLevel = 'advanced';
    else if (text.includes('intermediate') || text.includes('level 2')) skillLevel = 'intermediate';
    else if (text.includes('all levels') || text.includes('any level')) skillLevel = 'all_levels';

    // Max participants extraction
    let maxParticipants: number | undefined;
    const participantMatch = text.match(/(\d+)\s*(people|participants|students|max|limit)/);
    if (participantMatch) {
      maxParticipants = parseInt(participantMatch[1]);
    }

    // Price extraction
    let price: number | undefined;
    const priceMatch = text.match(/\$(\d+(?:\.\d{2})?)/);
    if (priceMatch) {
      price = parseFloat(priceMatch[1]);
    }

    return { category, skillLevel, maxParticipants, price };
  }

  /**
   * Import events from Calendly
   */
  async importEvents(
    startDate: Date,
    endDate: Date
  ): Promise<ImportResult> {
    try {
      const [calendlyEvents, eventTypes] = await Promise.all([
        this.fetchEvents(startDate, endDate),
        this.fetchEventTypes()
      ]);

      const importedEvents: Partial<ImportedEvent>[] = [];
      const errors: string[] = [];

      // Create event type lookup map
      const eventTypeMap = new Map(
        eventTypes.map(type => [type.uri, type])
      );

      for (const calendlyEvent of calendlyEvents) {
        try {
          const eventType = eventTypeMap.get(calendlyEvent.event_type);
          const importedEvent = this.convertToImportedEvent(calendlyEvent, eventType);
          importedEvents.push(importedEvent);
        } catch (error) {
          errors.push(`Failed to convert event ${calendlyEvent.uri}: ${error.message}`);
        }
      }

      // Generate mapping suggestions
      const mappingSuggestions = await this.generateMappingSuggestions(importedEvents);

      return {
        total_events: calendlyEvents.length,
        successfully_imported: importedEvents.length,
        failed_imports: errors.length,
        requires_review: mappingSuggestions.filter(m => m.requires_manual_review).length,
        duplicate_events: 0, // TODO: Implement duplicate detection
        error_details: errors,
        mapping_suggestions: mappingSuggestions,
      };
    } catch (error) {
      throw new Error(`Calendly import failed: ${error.message}`);
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

      // Auto-mapping logic based on event type and patterns
      if (event.category && event.category !== 'general') {
        mapping.confidence_score += 0.4;
        mapping.mapping_reasons.push(`Category detected: ${event.category}`);
      }

      if (event.price && event.price > 0) {
        mapping.confidence_score += 0.2;
        mapping.mapping_reasons.push('Pricing information found');
      }

      if (event.max_participants) {
        mapping.confidence_score += 0.2;
        mapping.mapping_reasons.push('Participant limit found');
      }

      if (event.title?.toLowerCase().includes('workshop') ||
          event.title?.toLowerCase().includes('class')) {
        mapping.confidence_score += 0.3;
        mapping.mapping_reasons.push('Workshop/class keywords found');
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
   * Create webhook subscription for real-time updates
   */
  async createWebhook(webhookUrl: string, events: string[] = ['invitee.created', 'invitee.canceled']) {
    try {
      const user = await this.getUserInfo();

      const response = await this.makeApiRequest('/webhook_subscriptions', {
        method: 'POST',
        body: JSON.stringify({
          url: webhookUrl,
          events,
          organization: user.organization.uri,
          scope: 'organization'
        })
      });

      return response.resource;
    } catch (error) {
      throw new Error(`Failed to create Calendly webhook: ${error.message}`);
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
      const { event, created_by, payload: eventPayload } = payload;

      if (!event || !eventPayload) {
        return null;
      }

      let eventData: Partial<ImportedEvent>;

      if (event === 'invitee.created') {
        eventData = {
          external_id: eventPayload.uri.split('/').pop(),
          provider: 'calendly',
          title: eventPayload.event.name,
          start_time: eventPayload.event.start_time,
          end_time: eventPayload.event.end_time,
          instructor_email: eventPayload.event.event_memberships?.[0]?.user_email,
          migration_status: 'pending',
          raw_data: eventPayload,
        };
      } else if (event === 'invitee.canceled') {
        eventData = {
          external_id: eventPayload.uri.split('/').pop(),
          provider: 'calendly',
          migration_status: 'skipped', // Mark as skipped since it's canceled
          raw_data: eventPayload,
        };
      } else {
        return null;
      }

      return {
        eventType: event,
        eventData
      };
    } catch (error) {
      console.error('Failed to process Calendly webhook:', error);
      return null;
    }
  }

  /**
   * Make authenticated API request to Calendly
   */
  private async makeApiRequest(endpoint: string, options: RequestInit = {}) {
    const url = endpoint.startsWith('http') ? endpoint : `${this.apiBaseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(`Calendly API error: ${response.status} ${response.statusText} - ${errorData.message || 'Unknown error'}`);
    }

    return await response.json();
  }

  /**
   * Refresh access token if needed
   */
  async refreshTokenIfNeeded(): Promise<boolean> {
    try {
      // Calendly uses long-lived tokens, but implement refresh logic if needed
      // For now, just test the connection
      return await this.testConnection();
    } catch (error) {
      console.error('Failed to refresh Calendly token:', error);
      return false;
    }
  }
}