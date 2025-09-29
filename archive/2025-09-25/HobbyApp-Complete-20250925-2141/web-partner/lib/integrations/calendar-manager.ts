import { createClient } from '@supabase/supabase-js';
import { GoogleCalendarIntegration } from './google-calendar';
import { CalendlyIntegration } from './calendly-integration';
import { SquareIntegration } from './square-integration';
import type {
  CalendarIntegration,
  CalendarProvider,
  ImportResult,
  CalendarSyncConfig,
  ImportedEvent,
  EventMapping
} from '@/types/calendar-integration';

export class CalendarIntegrationManager {
  private supabase;

  constructor() {
    this.supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
  }

  /**
   * Create a new calendar integration for a studio
   */
  async createIntegration(
    studioId: string,
    provider: CalendarProvider,
    accessToken: string,
    refreshToken?: string,
    settings: Record<string, any> = {}
  ): Promise<CalendarIntegration> {
    const { data, error } = await this.supabase
      .from('calendar_integrations')
      .insert({
        studio_id: studioId,
        provider,
        access_token: accessToken, // Should be encrypted in production
        refresh_token: refreshToken, // Should be encrypted in production
        settings,
        sync_status: 'active',
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create calendar integration: ${error.message}`);
    }

    return data;
  }

  /**
   * Get all integrations for a studio
   */
  async getStudioIntegrations(studioId: string): Promise<CalendarIntegration[]> {
    const { data, error } = await this.supabase
      .from('calendar_integrations')
      .select('*')
      .eq('studio_id', studioId)
      .eq('sync_enabled', true);

    if (error) {
      throw new Error(`Failed to fetch integrations: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Get specific integration by ID
   */
  async getIntegration(integrationId: string): Promise<CalendarIntegration | null> {
    const { data, error } = await this.supabase
      .from('calendar_integrations')
      .select('*')
      .eq('id', integrationId)
      .single();

    if (error) {
      return null;
    }

    return data;
  }

  /**
   * Update integration sync status
   */
  async updateSyncStatus(
    integrationId: string,
    status: 'active' | 'error' | 'paused' | 'expired',
    errorMessage?: string
  ): Promise<void> {
    const { error } = await this.supabase
      .from('calendar_integrations')
      .update({
        sync_status: status,
        error_message: errorMessage,
        last_sync_at: status === 'active' ? new Date().toISOString() : undefined,
        updated_at: new Date().toISOString(),
      })
      .eq('id', integrationId);

    if (error) {
      throw new Error(`Failed to update sync status: ${error.message}`);
    }
  }

  /**
   * Import events from a specific integration
   */
  async importEvents(
    integrationId: string,
    startDate: Date,
    endDate: Date
  ): Promise<ImportResult> {
    const integration = await this.getIntegration(integrationId);
    if (!integration) {
      throw new Error('Integration not found');
    }

    try {
      let result: ImportResult;

      switch (integration.provider) {
        case 'google':
          const googleIntegration = new GoogleCalendarIntegration(
            integration,
            integration.settings
          );
          result = await googleIntegration.importEvents(startDate, endDate);
          break;

        case 'calendly':
          const calendlyIntegration = new CalendlyIntegration(
            integration,
            integration.settings
          );
          result = await calendlyIntegration.importEvents(startDate, endDate);
          break;

        case 'square':
          const squareIntegration = new SquareIntegration(
            integration,
            integration.settings
          );
          result = await squareIntegration.importEvents(startDate, endDate);
          break;

        case 'outlook':
          // TODO: Implement Outlook integration
          throw new Error('Outlook integration not yet implemented');

        case 'mindbody':
          // TODO: Implement Mindbody integration
          throw new Error('Mindbody integration not yet implemented');

        case 'acuity':
          // TODO: Implement Acuity integration
          throw new Error('Acuity integration not yet implemented');

        default:
          throw new Error(`Unsupported provider: ${integration.provider}`);
      }

      // Store imported events in database
      if (result.mapping_suggestions.length > 0) {
        await this.storeImportedEvents(integrationId, result.mapping_suggestions);
      }

      // Update sync status
      await this.updateSyncStatus(integrationId, 'active');

      return result;
    } catch (error) {
      await this.updateSyncStatus(integrationId, 'error', error.message);
      throw error;
    }
  }

  /**
   * Store imported events in the database
   */
  private async storeImportedEvents(
    integrationId: string,
    mappings: EventMapping[]
  ): Promise<void> {
    const events = mappings.map(mapping => ({
      integration_id: integrationId,
      external_id: mapping.original_event.external_id,
      provider: mapping.original_event.provider,
      studio_id: mapping.original_event.studio_id,
      title: mapping.original_event.title,
      description: mapping.original_event.description,
      start_time: mapping.original_event.start_time,
      end_time: mapping.original_event.end_time,
      all_day: mapping.original_event.all_day,
      instructor_name: mapping.original_event.instructor_name,
      instructor_email: mapping.original_event.instructor_email,
      location: mapping.original_event.location,
      room: mapping.original_event.room,
      category: mapping.original_event.category,
      skill_level: mapping.original_event.skill_level,
      max_participants: mapping.original_event.max_participants,
      current_participants: mapping.original_event.current_participants || 0,
      price: mapping.original_event.price,
      material_fee: mapping.original_event.material_fee,
      migration_status: mapping.requires_manual_review ? 'pending' : 'mapped',
      mapped_class_id: mapping.suggested_class_id,
      raw_data: mapping.original_event.raw_data,
    }));

    const { error } = await this.supabase
      .from('imported_events')
      .upsert(events, {
        onConflict: 'integration_id,external_id',
      });

    if (error) {
      throw new Error(`Failed to store imported events: ${error.message}`);
    }
  }

  /**
   * Get imported events that need manual review
   */
  async getEventsNeedingReview(studioId: string): Promise<ImportedEvent[]> {
    const { data, error } = await this.supabase
      .from('imported_events')
      .select('*')
      .eq('studio_id', studioId)
      .eq('migration_status', 'pending')
      .order('start_time', { ascending: true });

    if (error) {
      throw new Error(`Failed to fetch events needing review: ${error.message}`);
    }

    return data || [];
  }

  /**
   * Approve and map an imported event to a class/schedule
   */
  async approveEventMapping(
    eventId: string,
    classId?: string,
    scheduleId?: string,
    createNew: boolean = false
  ): Promise<void> {
    const updateData: any = {
      migration_status: 'imported',
      updated_at: new Date().toISOString(),
    };

    if (classId) updateData.mapped_class_id = classId;
    if (scheduleId) updateData.mapped_schedule_id = scheduleId;

    const { error } = await this.supabase
      .from('imported_events')
      .update(updateData)
      .eq('id', eventId);

    if (error) {
      throw new Error(`Failed to approve event mapping: ${error.message}`);
    }

    // If creating new class/schedule, trigger that process
    if (createNew) {
      await this.createClassFromImportedEvent(eventId);
    }
  }

  /**
   * Create a new class and schedule from an imported event
   */
  private async createClassFromImportedEvent(eventId: string): Promise<void> {
    const { data: event, error: fetchError } = await this.supabase
      .from('imported_events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (fetchError || !event) {
      throw new Error('Failed to fetch imported event');
    }

    // Create new class
    const { data: newClass, error: classError } = await this.supabase
      .from('classes')
      .insert({
        studio_id: event.studio_id,
        name: event.title,
        description: event.description,
        category: event.category,
        difficulty_level: event.skill_level,
        duration: Math.round(
          (new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 60000
        ),
        max_participants: event.max_participants || 8,
        price: event.price || 0,
        is_active: true,
      })
      .select()
      .single();

    if (classError) {
      throw new Error(`Failed to create class: ${classError.message}`);
    }

    // Create schedule entry
    const { error: scheduleError } = await this.supabase
      .from('class_schedules')
      .insert({
        class_id: newClass.id,
        start_time: event.start_time,
        end_time: event.end_time,
        spots_available: event.max_participants || 8,
        spots_total: event.max_participants || 8,
      });

    if (scheduleError) {
      throw new Error(`Failed to create schedule: ${scheduleError.message}`);
    }

    // Update imported event with mapping
    await this.supabase
      .from('imported_events')
      .update({
        mapped_class_id: newClass.id,
        migration_status: 'imported',
      })
      .eq('id', eventId);
  }

  /**
   * Sync all active integrations for a studio
   */
  async syncAllIntegrations(studioId: string): Promise<Record<string, ImportResult>> {
    const integrations = await this.getStudioIntegrations(studioId);
    const results: Record<string, ImportResult> = {};

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    for (const integration of integrations) {
      try {
        const result = await this.importEvents(
          integration.id,
          thirtyDaysAgo,
          thirtyDaysFromNow
        );
        results[integration.provider] = result;
      } catch (error) {
        results[integration.provider] = {
          total_events: 0,
          successfully_imported: 0,
          failed_imports: 1,
          requires_review: 0,
          duplicate_events: 0,
          error_details: [error.message],
          mapping_suggestions: [],
        };
      }
    }

    return results;
  }

  /**
   * Delete an integration and all its imported events
   */
  async deleteIntegration(integrationId: string): Promise<void> {
    // Delete imported events first
    const { error: eventsError } = await this.supabase
      .from('imported_events')
      .delete()
      .eq('integration_id', integrationId);

    if (eventsError) {
      throw new Error(`Failed to delete imported events: ${eventsError.message}`);
    }

    // Delete integration
    const { error: integrationError } = await this.supabase
      .from('calendar_integrations')
      .delete()
      .eq('id', integrationId);

    if (integrationError) {
      throw new Error(`Failed to delete integration: ${integrationError.message}`);
    }
  }

  /**
   * Get sync statistics for dashboard
   */
  async getSyncStats(studioId: string): Promise<{
    total_integrations: number;
    active_integrations: number;
    last_sync: string | null;
    pending_reviews: number;
    total_imported: number;
  }> {
    const [integrations, pendingEvents, importedEvents] = await Promise.all([
      this.getStudioIntegrations(studioId),
      this.getEventsNeedingReview(studioId),
      this.supabase
        .from('imported_events')
        .select('id')
        .eq('studio_id', studioId)
        .eq('migration_status', 'imported'),
    ]);

    const lastSync = integrations
      .filter(i => i.last_sync_at)
      .sort((a, b) => new Date(b.last_sync_at!).getTime() - new Date(a.last_sync_at!).getTime())[0]
      ?.last_sync_at || null;

    return {
      total_integrations: integrations.length,
      active_integrations: integrations.filter(i => i.sync_status === 'active').length,
      last_sync: lastSync,
      pending_reviews: pendingEvents.length,
      total_imported: importedEvents.data?.length || 0,
    };
  }
}