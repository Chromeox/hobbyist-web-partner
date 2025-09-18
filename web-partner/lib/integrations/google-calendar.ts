import { google } from 'googleapis';
import type {
  CalendarIntegration,
  ImportedEvent,
  GoogleCalendarEvent,
  ImportResult,
  EventMapping,
  GoogleCalendarSettings
} from '@/types/calendar-integration';

export class GoogleCalendarIntegration {
  private oauth2Client: any;
  private calendar: any;

  constructor(
    private integration: CalendarIntegration,
    private settings: GoogleCalendarSettings
  ) {
    this.oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    // Set credentials if we have them
    if (integration.access_token && integration.refresh_token) {
      this.oauth2Client.setCredentials({
        access_token: integration.access_token,
        refresh_token: integration.refresh_token,
      });
    }

    this.calendar = google.calendar({ version: 'v3', auth: this.oauth2Client });
  }

  /**
   * Get Google OAuth authorization URL for initial setup
   */
  static getAuthUrl(): string {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    const scopes = [
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/calendar.events',
    ];

    return oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: scopes,
      prompt: 'consent',
    });
  }

  /**
   * Exchange authorization code for tokens
   */
  static async exchangeCodeForTokens(code: string) {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    const { tokens } = await oauth2Client.getToken(code);
    return tokens;
  }

  /**
   * Test the calendar connection
   */
  async testConnection(): Promise<boolean> {
    try {
      const response = await this.calendar.calendars.get({
        calendarId: this.settings.calendar_id || 'primary',
      });
      return !!response.data;
    } catch (error) {
      console.error('Google Calendar connection test failed:', error);
      return false;
    }
  }

  /**
   * Fetch events from Google Calendar
   */
  async fetchEvents(
    startDate: Date,
    endDate: Date
  ): Promise<GoogleCalendarEvent[]> {
    try {
      const response = await this.calendar.events.list({
        calendarId: this.settings.calendar_id || 'primary',
        timeMin: startDate.toISOString(),
        timeMax: endDate.toISOString(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 1000,
      });

      return response.data.items || [];
    } catch (error) {
      console.error('Failed to fetch Google Calendar events:', error);
      throw new Error(`Google Calendar API error: ${error.message}`);
    }
  }

  /**
   * Convert Google Calendar event to ImportedEvent format
   */
  private convertToImportedEvent(
    googleEvent: GoogleCalendarEvent
  ): Partial<ImportedEvent> {
    const startTime = googleEvent.start.dateTime || googleEvent.start.date;
    const endTime = googleEvent.end.dateTime || googleEvent.end.date;
    const allDay = !googleEvent.start.dateTime;

    // Try to extract workshop details from title and description
    const { category, skillLevel, maxParticipants } = this.extractWorkshopDetails(
      googleEvent.summary,
      googleEvent.description
    );

    return {
      external_id: googleEvent.id,
      provider: 'google',
      title: googleEvent.summary,
      description: googleEvent.description,
      start_time: startTime,
      end_time: endTime,
      all_day: allDay,
      location: googleEvent.location,
      instructor_name: googleEvent.creator?.displayName,
      instructor_email: googleEvent.creator?.email,
      category,
      skill_level: skillLevel,
      max_participants: maxParticipants,
      migration_status: 'pending',
      raw_data: googleEvent,
    };
  }

  /**
   * Extract workshop details from event title and description
   */
  private extractWorkshopDetails(title: string, description?: string) {
    const text = `${title} ${description || ''}`.toLowerCase();

    // Category detection
    let category = 'general';
    if (text.includes('pottery') || text.includes('ceramic')) category = 'pottery';
    else if (text.includes('paint') || text.includes('canvas')) category = 'painting';
    else if (text.includes('wood') || text.includes('carpentry')) category = 'woodworking';
    else if (text.includes('jewelry') || text.includes('beading')) category = 'jewelry';
    else if (text.includes('cook') || text.includes('baking')) category = 'cooking';
    else if (text.includes('music') || text.includes('guitar') || text.includes('piano')) category = 'music';

    // Skill level detection
    let skillLevel = 'beginner';
    if (text.includes('advanced') || text.includes('expert')) skillLevel = 'advanced';
    else if (text.includes('intermediate') || text.includes('level 2')) skillLevel = 'intermediate';
    else if (text.includes('all levels') || text.includes('any level')) skillLevel = 'all_levels';

    // Participants extraction
    let maxParticipants: number | undefined;
    const participantMatch = text.match(/(\d+)\s*(people|participants|students|max)/);
    if (participantMatch) {
      maxParticipants = parseInt(participantMatch[1]);
    }

    return { category, skillLevel, maxParticipants };
  }

  /**
   * Import events from Google Calendar
   */
  async importEvents(
    startDate: Date,
    endDate: Date
  ): Promise<ImportResult> {
    try {
      const googleEvents = await this.fetchEvents(startDate, endDate);
      const importedEvents: Partial<ImportedEvent>[] = [];
      const errors: string[] = [];

      for (const googleEvent of googleEvents) {
        try {
          const importedEvent = this.convertToImportedEvent(googleEvent);
          importedEvents.push(importedEvent);
        } catch (error) {
          errors.push(`Failed to convert event ${googleEvent.id}: ${error.message}`);
        }
      }

      // Generate mapping suggestions
      const mappingSuggestions = await this.generateMappingSuggestions(importedEvents);

      return {
        total_events: googleEvents.length,
        successfully_imported: importedEvents.length,
        failed_imports: errors.length,
        requires_review: mappingSuggestions.filter(m => m.requires_manual_review).length,
        duplicate_events: 0, // TODO: Implement duplicate detection
        error_details: errors,
        mapping_suggestions: mappingSuggestions,
      };
    } catch (error) {
      throw new Error(`Import failed: ${error.message}`);
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

      // Auto-mapping logic based on title, category, and patterns
      if (event.category && event.category !== 'general') {
        mapping.confidence_score += 0.3;
        mapping.mapping_reasons.push(`Category detected: ${event.category}`);
      }

      if (event.instructor_email) {
        mapping.confidence_score += 0.4;
        mapping.mapping_reasons.push('Instructor email found');
      }

      if (event.title?.includes('workshop') || event.title?.includes('class')) {
        mapping.confidence_score += 0.2;
        mapping.mapping_reasons.push('Workshop/class keywords found');
      }

      // High confidence events don't need manual review
      if (mapping.confidence_score >= 0.7) {
        mapping.requires_manual_review = false;
      }

      mappings.push(mapping);
    }

    return mappings;
  }

  /**
   * Create event in Google Calendar (for two-way sync)
   */
  async createEvent(
    title: string,
    description: string,
    startTime: Date,
    endTime: Date,
    location?: string,
    attendees?: string[]
  ): Promise<string> {
    try {
      const event = {
        summary: title,
        description,
        start: {
          dateTime: startTime.toISOString(),
          timeZone: this.settings.timezone || 'America/Vancouver',
        },
        end: {
          dateTime: endTime.toISOString(),
          timeZone: this.settings.timezone || 'America/Vancouver',
        },
        location,
        attendees: attendees?.map(email => ({ email })),
        reminders: {
          useDefault: false,
          overrides: [
            { method: 'email', minutes: this.settings.default_reminder_minutes || 60 },
            { method: 'popup', minutes: 10 },
          ],
        },
      };

      const response = await this.calendar.events.insert({
        calendarId: this.settings.calendar_id || 'primary',
        resource: event,
      });

      return response.data.id;
    } catch (error) {
      throw new Error(`Failed to create Google Calendar event: ${error.message}`);
    }
  }

  /**
   * Update existing event in Google Calendar
   */
  async updateEvent(
    eventId: string,
    title: string,
    description: string,
    startTime: Date,
    endTime: Date,
    location?: string
  ): Promise<void> {
    try {
      const event = {
        summary: title,
        description,
        start: {
          dateTime: startTime.toISOString(),
          timeZone: this.settings.timezone || 'America/Vancouver',
        },
        end: {
          dateTime: endTime.toISOString(),
          timeZone: this.settings.timezone || 'America/Vancouver',
        },
        location,
      };

      await this.calendar.events.update({
        calendarId: this.settings.calendar_id || 'primary',
        eventId,
        resource: event,
      });
    } catch (error) {
      throw new Error(`Failed to update Google Calendar event: ${error.message}`);
    }
  }

  /**
   * Delete event from Google Calendar
   */
  async deleteEvent(eventId: string): Promise<void> {
    try {
      await this.calendar.events.delete({
        calendarId: this.settings.calendar_id || 'primary',
        eventId,
      });
    } catch (error) {
      throw new Error(`Failed to delete Google Calendar event: ${error.message}`);
    }
  }

  /**
   * Refresh access token if needed
   */
  async refreshTokenIfNeeded(): Promise<boolean> {
    try {
      const { credentials } = await this.oauth2Client.refreshAccessToken();
      this.oauth2Client.setCredentials(credentials);

      // Update the integration record with new tokens
      // This should be handled by the calling service
      return true;
    } catch (error) {
      console.error('Failed to refresh Google Calendar token:', error);
      return false;
    }
  }
}