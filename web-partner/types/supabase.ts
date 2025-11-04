export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.3 (519615d)"
  }
  public: {
    Tables: {
      api_rate_limits: {
        Row: {
          created_at: string | null
          endpoint: string
          id: string
          request_count: number | null
          updated_at: string | null
          user_id: string | null
          window_end: string | null
          window_start: string | null
        }
        Insert: {
          created_at?: string | null
          endpoint: string
          id?: string
          request_count?: number | null
          updated_at?: string | null
          user_id?: string | null
          window_end?: string | null
          window_start?: string | null
        }
        Update: {
          created_at?: string | null
          endpoint?: string
          id?: string
          request_count?: number | null
          updated_at?: string | null
          user_id?: string | null
          window_end?: string | null
          window_start?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "api_rate_limits_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      calendar_integrations: {
        Row: {
          access_token: string | null
          created_at: string | null
          error_message: string | null
          id: string
          last_sync_at: string | null
          provider: string
          provider_account_id: string | null
          refresh_token: string | null
          settings: Json | null
          studio_id: string
          sync_direction: string | null
          sync_enabled: boolean | null
          sync_status: string | null
          token_expires_at: string | null
          updated_at: string | null
        }
        Insert: {
          access_token?: string | null
          created_at?: string | null
          error_message?: string | null
          id?: string
          last_sync_at?: string | null
          provider: string
          provider_account_id?: string | null
          refresh_token?: string | null
          settings?: Json | null
          studio_id: string
          sync_direction?: string | null
          sync_enabled?: boolean | null
          sync_status?: string | null
          token_expires_at?: string | null
          updated_at?: string | null
        }
        Update: {
          access_token?: string | null
          created_at?: string | null
          error_message?: string | null
          id?: string
          last_sync_at?: string | null
          provider?: string
          provider_account_id?: string | null
          refresh_token?: string | null
          settings?: Json | null
          studio_id?: string
          sync_direction?: string | null
          sync_enabled?: boolean | null
          sync_status?: string | null
          token_expires_at?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      categories: {
        Row: {
          color: string | null
          created_at: string | null
          description: string | null
          display_order: number | null
          icon: string | null
          id: string
          is_active: boolean | null
          name: string
          slug: string
          updated_at: string | null
        }
        Insert: {
          color?: string | null
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          icon?: string | null
          id?: string
          is_active?: boolean | null
          name: string
          slug: string
          updated_at?: string | null
        }
        Update: {
          color?: string | null
          created_at?: string | null
          description?: string | null
          display_order?: number | null
          icon?: string | null
          id?: string
          is_active?: boolean | null
          name?: string
          slug?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      class_recommendations: {
        Row: {
          algorithm_type: string | null
          class_id: string
          created_at: string | null
          dismissed: boolean | null
          id: string
          reason: string | null
          score: number | null
          user_id: string
        }
        Insert: {
          algorithm_type?: string | null
          class_id: string
          created_at?: string | null
          dismissed?: boolean | null
          id?: string
          reason?: string | null
          score?: number | null
          user_id: string
        }
        Update: {
          algorithm_type?: string | null
          class_id?: string
          created_at?: string | null
          dismissed?: boolean | null
          id?: string
          reason?: string | null
          score?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "class_recommendations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      class_reminders: {
        Row: {
          booking_id: string
          created_at: string | null
          id: string
          reminder_time: string
          reminder_type: string | null
          sent: boolean | null
          user_id: string
        }
        Insert: {
          booking_id: string
          created_at?: string | null
          id?: string
          reminder_time: string
          reminder_type?: string | null
          sent?: boolean | null
          user_id: string
        }
        Update: {
          booking_id?: string
          created_at?: string | null
          id?: string
          reminder_time?: string
          reminder_type?: string | null
          sent?: boolean | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "class_reminders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      class_reviews: {
        Row: {
          class_id: string
          created_at: string | null
          id: string
          instructor_id: string
          is_anonymous: boolean | null
          is_approved: boolean | null
          rating: number
          review_text: string | null
          updated_at: string | null
          user_id: string
          verified_booking: boolean | null
        }
        Insert: {
          class_id: string
          created_at?: string | null
          id?: string
          instructor_id: string
          is_anonymous?: boolean | null
          is_approved?: boolean | null
          rating: number
          review_text?: string | null
          updated_at?: string | null
          user_id: string
          verified_booking?: boolean | null
        }
        Update: {
          class_id?: string
          created_at?: string | null
          id?: string
          instructor_id?: string
          is_anonymous?: boolean | null
          is_approved?: boolean | null
          rating?: number
          review_text?: string | null
          updated_at?: string | null
          user_id?: string
          verified_booking?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "class_reviews_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      class_tiers: {
        Row: {
          created_at: string | null
          credit_required: number
          description: string | null
          id: string
          name: string
          price_range_max: number | null
          price_range_min: number | null
        }
        Insert: {
          created_at?: string | null
          credit_required: number
          description?: string | null
          id?: string
          name: string
          price_range_max?: number | null
          price_range_min?: number | null
        }
        Update: {
          created_at?: string | null
          credit_required?: number
          description?: string | null
          id?: string
          name?: string
          price_range_max?: number | null
          price_range_min?: number | null
        }
        Relationships: []
      }
      class_waitlists: {
        Row: {
          auto_book: boolean | null
          class_id: string
          created_at: string | null
          id: string
          position: number
          user_id: string
        }
        Insert: {
          auto_book?: boolean | null
          class_id: string
          created_at?: string | null
          id?: string
          position: number
          user_id: string
        }
        Update: {
          auto_book?: boolean | null
          class_id?: string
          created_at?: string | null
          id?: string
          position?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "class_waitlists_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      commission_overrides: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          commission_percentage: number
          created_at: string | null
          id: string
          is_active: boolean | null
          reason: string | null
          target_id: string
          target_type: string
          updated_at: string | null
          valid_from: string
          valid_until: string | null
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          commission_percentage: number
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          reason?: string | null
          target_id: string
          target_type: string
          updated_at?: string | null
          valid_from: string
          valid_until?: string | null
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          commission_percentage?: number
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          reason?: string | null
          target_id?: string
          target_type?: string
          updated_at?: string | null
          valid_from?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "commission_overrides_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string | null
          id: string
          instructor_id: string
          last_message: string | null
          last_message_at: string | null
          name: string
          participants: string[]
          studio_id: string | null
          type: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          instructor_id: string
          last_message?: string | null
          last_message_at?: string | null
          name: string
          participants?: string[]
          studio_id?: string | null
          type?: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          instructor_id?: string
          last_message?: string | null
          last_message_at?: string | null
          name?: string
          participants?: string[]
          studio_id?: string | null
          type?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      credit_rollovers: {
        Row: {
          created_at: string | null
          expires_at: string | null
          id: string
          original_credits: number
          rollover_credits: number
          rollover_percentage: number
          subscription_id: string | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          expires_at?: string | null
          id?: string
          original_credits: number
          rollover_credits: number
          rollover_percentage: number
          subscription_id?: string | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          expires_at?: string | null
          id?: string
          original_credits?: number
          rollover_credits?: number
          rollover_percentage?: number
          subscription_id?: string | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "credit_rollovers_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      encryption_keys: {
        Row: {
          algorithm: string | null
          created_at: string | null
          id: string
          is_active: boolean | null
          key_name: string
          key_version: number | null
          rotated_at: string | null
        }
        Insert: {
          algorithm?: string | null
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          key_name: string
          key_version?: number | null
          rotated_at?: string | null
        }
        Update: {
          algorithm?: string | null
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          key_name?: string
          key_version?: number | null
          rotated_at?: string | null
        }
        Relationships: []
      }
      failed_login_attempts: {
        Row: {
          attempt_count: number | null
          created_at: string | null
          email: string
          error_message: string | null
          id: string
          ip_address: unknown
          locked_until: string | null
          updated_at: string | null
          user_agent: string | null
        }
        Insert: {
          attempt_count?: number | null
          created_at?: string | null
          email: string
          error_message?: string | null
          id?: string
          ip_address?: unknown
          locked_until?: string | null
          updated_at?: string | null
          user_agent?: string | null
        }
        Update: {
          attempt_count?: number | null
          created_at?: string | null
          email?: string
          error_message?: string | null
          id?: string
          ip_address?: unknown
          locked_until?: string | null
          updated_at?: string | null
          user_agent?: string | null
        }
        Relationships: []
      }
      imported_events: {
        Row: {
          all_day: boolean | null
          category: string | null
          created_at: string | null
          current_participants: number | null
          description: string | null
          end_time: string
          error_details: Json | null
          external_id: string
          id: string
          instructor_email: string | null
          instructor_name: string | null
          integration_id: string
          location: string | null
          mapped_class_id: string | null
          mapped_schedule_id: string | null
          material_fee: number | null
          max_participants: number | null
          migration_status: string | null
          price: number | null
          provider: string
          raw_data: Json | null
          room: string | null
          skill_level: string | null
          start_time: string
          studio_id: string
          title: string
          updated_at: string | null
        }
        Insert: {
          all_day?: boolean | null
          category?: string | null
          created_at?: string | null
          current_participants?: number | null
          description?: string | null
          end_time: string
          error_details?: Json | null
          external_id: string
          id?: string
          instructor_email?: string | null
          instructor_name?: string | null
          integration_id: string
          location?: string | null
          mapped_class_id?: string | null
          mapped_schedule_id?: string | null
          material_fee?: number | null
          max_participants?: number | null
          migration_status?: string | null
          price?: number | null
          provider: string
          raw_data?: Json | null
          room?: string | null
          skill_level?: string | null
          start_time: string
          studio_id: string
          title: string
          updated_at?: string | null
        }
        Update: {
          all_day?: boolean | null
          category?: string | null
          created_at?: string | null
          current_participants?: number | null
          description?: string | null
          end_time?: string
          error_details?: Json | null
          external_id?: string
          id?: string
          instructor_email?: string | null
          instructor_name?: string | null
          integration_id?: string
          location?: string | null
          mapped_class_id?: string | null
          mapped_schedule_id?: string | null
          material_fee?: number | null
          max_participants?: number | null
          migration_status?: string | null
          price?: number | null
          provider?: string
          raw_data?: Json | null
          room?: string | null
          skill_level?: string | null
          start_time?: string
          studio_id?: string
          title?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "imported_events_integration_id_fkey"
            columns: ["integration_id"]
            isOneToOne: false
            referencedRelation: "calendar_integrations"
            referencedColumns: ["id"]
          },
        ]
      }
      instructor_applications: {
        Row: {
          admin_notes: string | null
          categories: string[]
          created_at: string | null
          experience: string
          id: string
          qualifications: string
          status: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          admin_notes?: string | null
          categories: string[]
          created_at?: string | null
          experience: string
          id?: string
          qualifications: string
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          admin_notes?: string | null
          categories?: string[]
          created_at?: string | null
          experience?: string
          id?: string
          qualifications?: string
          status?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_instructor_applications_user"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      instructor_follows: {
        Row: {
          created_at: string | null
          id: string
          instructor_id: string
          notify_new_classes: boolean | null
          notify_schedule_changes: boolean | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          instructor_id: string
          notify_new_classes?: boolean | null
          notify_schedule_changes?: boolean | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          instructor_id?: string
          notify_new_classes?: boolean | null
          notify_schedule_changes?: boolean | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "instructor_follows_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      instructor_profiles: {
        Row: {
          accepts_custom_rates: boolean | null
          availability: Json | null
          average_rating: number | null
          background_check_date: string | null
          bio: string | null
          certifications: Json | null
          cover_image_url: string | null
          created_at: string | null
          currency: string | null
          display_name: string
          hourly_rate: number | null
          id: string
          instagram_handle: string | null
          is_active: boolean | null
          is_featured: boolean | null
          is_verified: boolean | null
          languages: string[] | null
          max_class_size: number | null
          min_class_size: number | null
          portfolio_items: Json | null
          profile_image_url: string | null
          slug: string
          specialties: string[] | null
          tagline: string | null
          total_classes_taught: number | null
          total_reviews: number | null
          total_students: number | null
          travel_radius_km: number | null
          updated_at: string | null
          user_id: string
          verification_date: string | null
          website_url: string | null
          years_experience: number | null
          youtube_channel: string | null
        }
        Insert: {
          accepts_custom_rates?: boolean | null
          availability?: Json | null
          average_rating?: number | null
          background_check_date?: string | null
          bio?: string | null
          certifications?: Json | null
          cover_image_url?: string | null
          created_at?: string | null
          currency?: string | null
          display_name: string
          hourly_rate?: number | null
          id?: string
          instagram_handle?: string | null
          is_active?: boolean | null
          is_featured?: boolean | null
          is_verified?: boolean | null
          languages?: string[] | null
          max_class_size?: number | null
          min_class_size?: number | null
          portfolio_items?: Json | null
          profile_image_url?: string | null
          slug: string
          specialties?: string[] | null
          tagline?: string | null
          total_classes_taught?: number | null
          total_reviews?: number | null
          total_students?: number | null
          travel_radius_km?: number | null
          updated_at?: string | null
          user_id: string
          verification_date?: string | null
          website_url?: string | null
          years_experience?: number | null
          youtube_channel?: string | null
        }
        Update: {
          accepts_custom_rates?: boolean | null
          availability?: Json | null
          average_rating?: number | null
          background_check_date?: string | null
          bio?: string | null
          certifications?: Json | null
          cover_image_url?: string | null
          created_at?: string | null
          currency?: string | null
          display_name?: string
          hourly_rate?: number | null
          id?: string
          instagram_handle?: string | null
          is_active?: boolean | null
          is_featured?: boolean | null
          is_verified?: boolean | null
          languages?: string[] | null
          max_class_size?: number | null
          min_class_size?: number | null
          portfolio_items?: Json | null
          profile_image_url?: string | null
          slug?: string
          specialties?: string[] | null
          tagline?: string | null
          total_classes_taught?: number | null
          total_reviews?: number | null
          total_students?: number | null
          travel_radius_km?: number | null
          updated_at?: string | null
          user_id?: string
          verification_date?: string | null
          website_url?: string | null
          years_experience?: number | null
          youtube_channel?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "instructor_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      instructor_responses: {
        Row: {
          created_at: string | null
          id: string
          instructor_id: string
          response_text: string
          review_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          instructor_id: string
          response_text: string
          review_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          instructor_id?: string
          response_text?: string
          review_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "instructor_responses_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: true
            referencedRelation: "class_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      instructor_reviews: {
        Row: {
          booking_id: string | null
          comment: string | null
          created_at: string | null
          helpful_count: number | null
          id: string
          instructor_id: string
          instructor_response: string | null
          is_verified_booking: boolean | null
          is_visible: boolean | null
          rating: number
          response_date: string | null
          student_id: string
          title: string | null
          updated_at: string | null
        }
        Insert: {
          booking_id?: string | null
          comment?: string | null
          created_at?: string | null
          helpful_count?: number | null
          id?: string
          instructor_id: string
          instructor_response?: string | null
          is_verified_booking?: boolean | null
          is_visible?: boolean | null
          rating: number
          response_date?: string | null
          student_id: string
          title?: string | null
          updated_at?: string | null
        }
        Update: {
          booking_id?: string | null
          comment?: string | null
          created_at?: string | null
          helpful_count?: number | null
          id?: string
          instructor_id?: string
          instructor_response?: string | null
          is_verified_booking?: boolean | null
          is_visible?: boolean | null
          rating?: number
          response_date?: string | null
          student_id?: string
          title?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "instructor_reviews_instructor_id_fkey"
            columns: ["instructor_id"]
            isOneToOne: false
            referencedRelation: "instructor_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "instructor_reviews_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      location_amenities: {
        Row: {
          additional_cost: number | null
          category: string | null
          created_at: string | null
          description: string | null
          icon: string | null
          id: string
          is_available: boolean | null
          location_id: string
          name: string
        }
        Insert: {
          additional_cost?: number | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          is_available?: boolean | null
          location_id: string
          name: string
        }
        Update: {
          additional_cost?: number | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          is_available?: boolean | null
          location_id?: string
          name?: string
        }
        Relationships: []
      }
      messages: {
        Row: {
          attachments: Json | null
          content: string
          conversation_id: string
          created_at: string | null
          id: string
          read_at: string | null
          sender_id: string | null
          updated_at: string | null
        }
        Insert: {
          attachments?: Json | null
          content: string
          conversation_id: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id?: string | null
          updated_at?: string | null
        }
        Update: {
          attachments?: Json | null
          content?: string
          conversation_id?: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string
          created_at: string | null
          data: Json | null
          id: string
          is_read: boolean | null
          message: string | null
          read: boolean | null
          related_id: string | null
          title: string
          type: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string | null
          data?: Json | null
          id?: string
          is_read?: boolean | null
          message?: string | null
          read?: boolean | null
          related_id?: string | null
          title: string
          type: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string | null
          data?: Json | null
          id?: string
          is_read?: boolean | null
          message?: string | null
          read?: boolean | null
          related_id?: string | null
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_notifications_user"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      payout_batches: {
        Row: {
          batch_number: string
          completed_at: string | null
          created_at: string | null
          currency: string | null
          error_details: Json | null
          failed_count: number | null
          id: string
          processor: string | null
          processor_batch_id: string | null
          scheduled_for: string | null
          started_at: string | null
          status: string | null
          successful_count: number | null
          total_amount: number
          total_requests: number
          updated_at: string | null
        }
        Insert: {
          batch_number: string
          completed_at?: string | null
          created_at?: string | null
          currency?: string | null
          error_details?: Json | null
          failed_count?: number | null
          id?: string
          processor?: string | null
          processor_batch_id?: string | null
          scheduled_for?: string | null
          started_at?: string | null
          status?: string | null
          successful_count?: number | null
          total_amount: number
          total_requests: number
          updated_at?: string | null
        }
        Update: {
          batch_number?: string
          completed_at?: string | null
          created_at?: string | null
          currency?: string | null
          error_details?: Json | null
          failed_count?: number | null
          id?: string
          processor?: string | null
          processor_batch_id?: string | null
          scheduled_for?: string | null
          started_at?: string | null
          status?: string | null
          successful_count?: number | null
          total_amount?: number
          total_requests?: number
          updated_at?: string | null
        }
        Relationships: []
      }
      payout_requests: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          batch_id: string | null
          created_at: string | null
          currency: string | null
          id: string
          metadata: Json | null
          notes: string | null
          payout_details: Json | null
          payout_method: string
          processed_at: string | null
          requester_id: string
          requester_type: string
          status: string | null
          transaction_id: string | null
          updated_at: string | null
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          batch_id?: string | null
          created_at?: string | null
          currency?: string | null
          id?: string
          metadata?: Json | null
          notes?: string | null
          payout_details?: Json | null
          payout_method: string
          processed_at?: string | null
          requester_id: string
          requester_type: string
          status?: string | null
          transaction_id?: string | null
          updated_at?: string | null
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          batch_id?: string | null
          created_at?: string | null
          currency?: string | null
          id?: string
          metadata?: Json | null
          notes?: string | null
          payout_details?: Json | null
          payout_method?: string
          processed_at?: string | null
          requester_id?: string
          requester_type?: string
          status?: string | null
          transaction_id?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payout_requests_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payout_requests_batch_id_fkey"
            columns: ["batch_id"]
            isOneToOne: false
            referencedRelation: "payout_batches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payout_requests_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          bio: string | null
          created_at: string | null
          credits: number | null
          email: string | null
          gender: string | null
          id: string
          is_instructor: boolean | null
          marketing_consent: boolean | null
          name: string | null
          newsletter_consent: boolean | null
          preferences: Json | null
          profile_image: string | null
          role: Database["public"]["Enums"]["user_role"] | null
          saved_classes: string[] | null
          updated_at: string | null
        }
        Insert: {
          bio?: string | null
          created_at?: string | null
          credits?: number | null
          email?: string | null
          gender?: string | null
          id: string
          is_instructor?: boolean | null
          marketing_consent?: boolean | null
          name?: string | null
          newsletter_consent?: boolean | null
          preferences?: Json | null
          profile_image?: string | null
          role?: Database["public"]["Enums"]["user_role"] | null
          saved_classes?: string[] | null
          updated_at?: string | null
        }
        Update: {
          bio?: string | null
          created_at?: string | null
          credits?: number | null
          email?: string | null
          gender?: string | null
          id?: string
          is_instructor?: boolean | null
          marketing_consent?: boolean | null
          name?: string | null
          newsletter_consent?: boolean | null
          preferences?: Json | null
          profile_image?: string | null
          role?: Database["public"]["Enums"]["user_role"] | null
          saved_classes?: string[] | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      push_tokens: {
        Row: {
          created_at: string | null
          device_info: Json | null
          id: string
          is_active: boolean | null
          platform: string
          token: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform: string
          token: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          device_info?: Json | null
          id?: string
          is_active?: boolean | null
          platform?: string
          token?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "push_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reservations: {
        Row: {
          amount_paid: number | null
          cancellation_reason: string | null
          cancellation_time: string | null
          check_in_time: string | null
          created_at: string | null
          credits_used: number | null
          id: string
          payment_method: string | null
          promoted_from_waitlist_at: string | null
          session_id: string
          status: string | null
          student_id: string
          updated_at: string | null
          waitlist_joined_at: string | null
          waitlist_position: number | null
        }
        Insert: {
          amount_paid?: number | null
          cancellation_reason?: string | null
          cancellation_time?: string | null
          check_in_time?: string | null
          created_at?: string | null
          credits_used?: number | null
          id?: string
          payment_method?: string | null
          promoted_from_waitlist_at?: string | null
          session_id: string
          status?: string | null
          student_id: string
          updated_at?: string | null
          waitlist_joined_at?: string | null
          waitlist_position?: number | null
        }
        Update: {
          amount_paid?: number | null
          cancellation_reason?: string | null
          cancellation_time?: string | null
          check_in_time?: string | null
          created_at?: string | null
          credits_used?: number | null
          id?: string
          payment_method?: string | null
          promoted_from_waitlist_at?: string | null
          session_id?: string
          status?: string | null
          student_id?: string
          updated_at?: string | null
          waitlist_joined_at?: string | null
          waitlist_position?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "reservations_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      revenue_shares: {
        Row: {
          booking_id: string
          created_at: string | null
          id: string
          instructor_id: string | null
          instructor_percentage: number | null
          instructor_share: number | null
          payout_request_id: string | null
          platform_fee: number | null
          platform_percentage: number | null
          processed_at: string | null
          status: string | null
          studio_id: string | null
          studio_percentage: number | null
          studio_share: number | null
          total_amount: number
          updated_at: string | null
        }
        Insert: {
          booking_id: string
          created_at?: string | null
          id?: string
          instructor_id?: string | null
          instructor_percentage?: number | null
          instructor_share?: number | null
          payout_request_id?: string | null
          platform_fee?: number | null
          platform_percentage?: number | null
          processed_at?: string | null
          status?: string | null
          studio_id?: string | null
          studio_percentage?: number | null
          studio_share?: number | null
          total_amount: number
          updated_at?: string | null
        }
        Update: {
          booking_id?: string
          created_at?: string | null
          id?: string
          instructor_id?: string | null
          instructor_percentage?: number | null
          instructor_share?: number | null
          payout_request_id?: string | null
          platform_fee?: number | null
          platform_percentage?: number | null
          processed_at?: string | null
          status?: string | null
          studio_id?: string | null
          studio_percentage?: number | null
          studio_share?: number | null
          total_amount?: number
          updated_at?: string | null
        }
        Relationships: []
      }
      review_media: {
        Row: {
          created_at: string | null
          file_size: number | null
          id: string
          media_type: string
          media_url: string
          mime_type: string | null
          review_id: string
          thumbnail_url: string | null
        }
        Insert: {
          created_at?: string | null
          file_size?: number | null
          id?: string
          media_type: string
          media_url: string
          mime_type?: string | null
          review_id: string
          thumbnail_url?: string | null
        }
        Update: {
          created_at?: string | null
          file_size?: number | null
          id?: string
          media_type?: string
          media_url?: string
          mime_type?: string | null
          review_id?: string
          thumbnail_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "review_media_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "class_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      review_moderation: {
        Row: {
          created_at: string | null
          id: string
          moderator_id: string
          reason: string | null
          review_id: string
          status: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          moderator_id: string
          reason?: string | null
          review_id: string
          status: string
        }
        Update: {
          created_at?: string | null
          id?: string
          moderator_id?: string
          reason?: string | null
          review_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_moderation_moderator_id_fkey"
            columns: ["moderator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_moderation_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "class_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      review_tags: {
        Row: {
          created_at: string | null
          id: string
          review_id: string
          tag: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          review_id: string
          tag: string
        }
        Update: {
          created_at?: string | null
          id?: string
          review_id?: string
          tag?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_tags_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "class_reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      review_votes: {
        Row: {
          created_at: string | null
          id: string
          review_id: string
          user_id: string
          vote_type: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          review_id: string
          user_id: string
          vote_type: string
        }
        Update: {
          created_at?: string | null
          id?: string
          review_id?: string
          user_id?: string
          vote_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_votes_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "class_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      reviews: {
        Row: {
          class_id: string | null
          comment: string | null
          created_at: string | null
          id: string
          rating: number
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          class_id?: string | null
          comment?: string | null
          created_at?: string | null
          id?: string
          rating: number
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          class_id?: string | null
          comment?: string | null
          created_at?: string | null
          id?: string
          rating?: number
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_reviews_user"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_classes: {
        Row: {
          class_id: string
          created_at: string | null
          id: string
          notes: string | null
          user_id: string
        }
        Insert: {
          class_id: string
          created_at?: string | null
          id?: string
          notes?: string | null
          user_id: string
        }
        Update: {
          class_id?: string
          created_at?: string | null
          id?: string
          notes?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_classes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      security_audit_log: {
        Row: {
          action: string | null
          created_at: string | null
          event_type: string
          id: string
          ip_address: unknown
          metadata: Json | null
          resource_id: string | null
          resource_type: string | null
          result: string | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          action?: string | null
          created_at?: string | null
          event_type: string
          id?: string
          ip_address?: unknown
          metadata?: Json | null
          resource_id?: string | null
          resource_type?: string | null
          result?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string | null
          created_at?: string | null
          event_type?: string
          id?: string
          ip_address?: unknown
          metadata?: Json | null
          resource_id?: string | null
          resource_type?: string | null
          result?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "security_audit_log_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      student_activities: {
        Row: {
          activity_type: string
          created_at: string | null
          id: string
          metadata: Json | null
          target_id: string | null
          target_type: string | null
          user_id: string
        }
        Insert: {
          activity_type: string
          created_at?: string | null
          id?: string
          metadata?: Json | null
          target_id?: string | null
          target_type?: string | null
          user_id: string
        }
        Update: {
          activity_type?: string
          created_at?: string | null
          id?: string
          metadata?: Json | null
          target_id?: string | null
          target_type?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      student_preferences: {
        Row: {
          created_at: string | null
          id: string
          max_distance_km: number | null
          preferred_categories: string[] | null
          preferred_locations: string[] | null
          preferred_times: Json | null
          skill_levels: Json | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          max_distance_km?: number | null
          preferred_categories?: string[] | null
          preferred_locations?: string[] | null
          preferred_times?: Json | null
          skill_levels?: Json | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          max_distance_km?: number | null
          preferred_categories?: string[] | null
          preferred_locations?: string[] | null
          preferred_times?: Json | null
          skill_levels?: Json | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      students: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string | null
          credit_balance: number | null
          date_of_birth: string | null
          email: string
          emergency_contact: Json | null
          favorite_categories: string[] | null
          first_name: string | null
          id: string
          last_active_at: string | null
          last_name: string | null
          medical_notes: string | null
          member_since: string | null
          notification_settings: Json | null
          phone: string | null
          preferences: Json | null
          status: string | null
          total_classes_attended: number | null
          total_credits_purchased: number | null
          total_credits_used: number | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          credit_balance?: number | null
          date_of_birth?: string | null
          email: string
          emergency_contact?: Json | null
          favorite_categories?: string[] | null
          first_name?: string | null
          id?: string
          last_active_at?: string | null
          last_name?: string | null
          medical_notes?: string | null
          member_since?: string | null
          notification_settings?: Json | null
          phone?: string | null
          preferences?: Json | null
          status?: string | null
          total_classes_attended?: number | null
          total_credits_purchased?: number | null
          total_credits_used?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          credit_balance?: number | null
          date_of_birth?: string | null
          email?: string
          emergency_contact?: Json | null
          favorite_categories?: string[] | null
          first_name?: string | null
          id?: string
          last_active_at?: string | null
          last_name?: string | null
          medical_notes?: string | null
          member_since?: string | null
          notification_settings?: Json | null
          phone?: string | null
          preferences?: Json | null
          status?: string | null
          total_classes_attended?: number | null
          total_credits_purchased?: number | null
          total_credits_used?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "students_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      studio_onboarding_submissions: {
        Row: {
          business_name: string
          created_at: string
          email: string
          id: string
          payment_setup: Json | null
          status: string
          studio_id: string | null
          submitted_data: Json
          updated_at: string
          user_id: string | null
          verification_documents: Json | null
        }
        Insert: {
          business_name: string
          created_at?: string
          email: string
          id?: string
          payment_setup?: Json | null
          status?: string
          studio_id?: string | null
          submitted_data: Json
          updated_at?: string
          user_id?: string | null
          verification_documents?: Json | null
        }
        Update: {
          business_name?: string
          created_at?: string
          email?: string
          id?: string
          payment_setup?: Json | null
          status?: string
          studio_id?: string | null
          submitted_data?: Json
          updated_at?: string
          user_id?: string | null
          verification_documents?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "studio_onboarding_submissions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      studio_preferences: {
        Row: {
          dismissed_reminders: string[]
          studio_id: string
          updated_at: string
        }
        Insert: {
          dismissed_reminders?: string[]
          studio_id: string
          updated_at?: string
        }
        Update: {
          dismissed_reminders?: string[]
          studio_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      studio_staff: {
        Row: {
          avatar_url: string | null
          bio: string | null
          commission_rate: number | null
          created_at: string | null
          email: string
          first_name: string | null
          id: string
          invitation_accepted_at: string | null
          invitation_sent_at: string | null
          invitation_token: string | null
          last_name: string | null
          location_id: string | null
          payroll_info: Json | null
          performance_metrics: Json | null
          permissions: Json | null
          phone: string | null
          role: string
          schedule_preferences: Json | null
          specialties: string[] | null
          status: string | null
          studio_id: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          commission_rate?: number | null
          created_at?: string | null
          email: string
          first_name?: string | null
          id?: string
          invitation_accepted_at?: string | null
          invitation_sent_at?: string | null
          invitation_token?: string | null
          last_name?: string | null
          location_id?: string | null
          payroll_info?: Json | null
          performance_metrics?: Json | null
          permissions?: Json | null
          phone?: string | null
          role?: string
          schedule_preferences?: Json | null
          specialties?: string[] | null
          status?: string | null
          studio_id: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          commission_rate?: number | null
          created_at?: string | null
          email?: string
          first_name?: string | null
          id?: string
          invitation_accepted_at?: string | null
          invitation_sent_at?: string | null
          invitation_token?: string | null
          last_name?: string | null
          location_id?: string | null
          payroll_info?: Json | null
          performance_metrics?: Json | null
          permissions?: Json | null
          phone?: string | null
          role?: string
          schedule_preferences?: Json | null
          specialties?: string[] | null
          status?: string | null
          studio_id?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "studio_staff_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_consent: {
        Row: {
          consent_type: string
          granted: boolean
          granted_at: string | null
          id: string
          ip_address: unknown
          user_agent: string | null
          user_id: string
          version: string
          withdrawn_at: string | null
        }
        Insert: {
          consent_type: string
          granted: boolean
          granted_at?: string | null
          id?: string
          ip_address?: unknown
          user_agent?: string | null
          user_id: string
          version: string
          withdrawn_at?: string | null
        }
        Update: {
          consent_type?: string
          granted?: boolean
          granted_at?: string | null
          id?: string
          ip_address?: unknown
          user_agent?: string | null
          user_id?: string
          version?: string
          withdrawn_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_consent_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_preferences: {
        Row: {
          created_at: string | null
          id: string
          max_price_preference: number | null
          preferred_categories: string[] | null
          preferred_days: number[] | null
          preferred_time_of_day: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          max_price_preference?: number | null
          preferred_categories?: string[] | null
          preferred_days?: number[] | null
          preferred_time_of_day?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          max_price_preference?: number | null
          preferred_categories?: string[] | null
          preferred_days?: number[] | null
          preferred_time_of_day?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_user_preferences_user"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string | null
          full_name: string | null
          id: string
          phone: string | null
          preferences: Json | null
          updated_at: string | null
          user_type: string | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          full_name?: string | null
          id: string
          phone?: string | null
          preferences?: Json | null
          updated_at?: string | null
          user_type?: string | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string | null
          full_name?: string | null
          id?: string
          phone?: string | null
          preferences?: Json | null
          updated_at?: string | null
          user_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_sessions: {
        Row: {
          created_at: string | null
          device_fingerprint: string | null
          expires_at: string
          id: string
          ip_address: unknown
          is_active: boolean | null
          last_activity: string | null
          location_city: string | null
          location_country: string | null
          session_token: string
          user_agent: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          device_fingerprint?: string | null
          expires_at: string
          id?: string
          ip_address: unknown
          is_active?: boolean | null
          last_activity?: string | null
          location_city?: string | null
          location_country?: string | null
          session_token: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          device_fingerprint?: string | null
          expires_at?: string
          id?: string
          ip_address?: unknown
          is_active?: boolean | null
          last_activity?: string | null
          location_city?: string | null
          location_country?: string | null
          session_token?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      waitlist: {
        Row: {
          auto_enroll: boolean | null
          enrolled_at: string | null
          expired_at: string | null
          id: string
          joined_at: string | null
          notification_expires_at: string | null
          notification_preference: string | null
          notification_sent_at: string | null
          position: number
          priority: string | null
          session_id: string
          status: string | null
          student_id: string
        }
        Insert: {
          auto_enroll?: boolean | null
          enrolled_at?: string | null
          expired_at?: string | null
          id?: string
          joined_at?: string | null
          notification_expires_at?: string | null
          notification_preference?: string | null
          notification_sent_at?: string | null
          position: number
          priority?: string | null
          session_id: string
          status?: string | null
          student_id: string
        }
        Update: {
          auto_enroll?: boolean | null
          enrolled_at?: string | null
          expired_at?: string | null
          id?: string
          joined_at?: string | null
          notification_expires_at?: string | null
          notification_preference?: string | null
          notification_sent_at?: string | null
          position?: number
          priority?: string | null
          session_id?: string
          status?: string | null
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "waitlist_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      revenue_analytics: {
        Row: {
          avg_instructor_percentage: number | null
          avg_studio_percentage: number | null
          gross_revenue: number | null
          instructor_earnings: number | null
          instructor_id: string | null
          month: string | null
          platform_revenue: number | null
          studio_earnings: number | null
          studio_id: string | null
          total_bookings: number | null
        }
        Relationships: []
      }
      stripe_user_orders: {
        Row: {
          amount_subtotal: number | null
          amount_total: number | null
          checkout_session_id: string | null
          currency: string | null
          customer_id: string | null
          order_date: string | null
          order_id: number | null
          order_status:
            | Database["public"]["Enums"]["stripe_order_status"]
            | null
          payment_intent_id: string | null
          payment_status: string | null
        }
        Relationships: []
      }
      stripe_user_subscriptions: {
        Row: {
          cancel_at_period_end: boolean | null
          current_period_end: number | null
          current_period_start: number | null
          customer_id: string | null
          payment_method_brand: string | null
          payment_method_last4: string | null
          price_id: string | null
          subscription_id: string | null
          subscription_status:
            | Database["public"]["Enums"]["stripe_subscription_status"]
            | null
        }
        Relationships: []
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          email: string | null
          full_name: string | null
          id: string | null
          updated_at: string | null
        }
        Insert: {
          avatar_url?: never
          created_at?: string | null
          email?: string | null
          full_name?: never
          id?: string | null
          updated_at?: string | null
        }
        Update: {
          avatar_url?: never
          created_at?: string | null
          email?: string | null
          full_name?: never
          id?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      v_studio_imported_events_recent: {
        Row: {
          all_day: boolean | null
          category: string | null
          current_participants: number | null
          description: string | null
          end_time: string | null
          id: string | null
          instructor_email: string | null
          instructor_name: string | null
          integration_id: string | null
          location: string | null
          mapped_class_id: string | null
          mapped_schedule_id: string | null
          material_fee: number | null
          max_participants: number | null
          migration_status: string | null
          price: number | null
          provider: string | null
          raw_data: Json | null
          room: string | null
          skill_level: string | null
          start_time: string | null
          studio_id: string | null
          title: string | null
        }
        Relationships: [
          {
            foreignKeyName: "imported_events_integration_id_fkey"
            columns: ["integration_id"]
            isOneToOne: false
            referencedRelation: "calendar_integrations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      add_user_credits: {
        Args: {
          p_credits: number
          p_reference_id?: string
          p_source: string
          p_user_id: string
        }
        Returns: boolean
      }
      add_user_credits_with_transaction:
        | {
            Args: {
              credits_to_add: number
              reference_id?: string
              transaction_type?: string
              user_id: string
            }
            Returns: boolean
          }
        | {
            Args: {
              p_amount: number
              p_description: string
              p_package_id?: string
              p_payment_intent_id?: string
              p_related_booking_id?: string
              p_transaction_id?: string
              p_type?: string
              p_user_id: string
            }
            Returns: Json
          }
      auto_enroll_from_waitlist: { Args: never; Returns: undefined }
      book_class: {
        Args: { p_class_id: string; p_user_id: string }
        Returns: Json
      }
      calculate_booking_commission: { Args: never; Returns: undefined }
      calculate_credits_needed: {
        Args: { p_class_id: string; p_schedule_time: string }
        Returns: number
      }
      calculate_workshop_material_cost: {
        Args: { template_id: string }
        Returns: number
      }
      cancel_booking: {
        Args: { p_booking_id: string; p_reason?: string; p_user_id: string }
        Returns: boolean
      }
      check_avatar_columns_exist: { Args: never; Returns: boolean }
      check_rate_limit: {
        Args: { p_endpoint: string; p_max_requests?: number; p_user_id: string }
        Returns: boolean
      }
      check_suspicious_activity: {
        Args: { p_user_id: string }
        Returns: boolean
      }
      create_booking_optimized: { Args: { p_booking: Json }; Returns: Json }
      deduct_user_credits_with_transaction:
        | {
            Args: {
              credits_to_deduct: number
              reference_id?: string
              transaction_type?: string
              user_id: string
            }
            Returns: boolean
          }
        | {
            Args: {
              p_amount: number
              p_description: string
              p_related_booking_id?: string
              p_type?: string
              p_user_id: string
            }
            Returns: Json
          }
      delete_user: { Args: { user_id: string }; Returns: undefined }
      fn_get_dashboard_activity: {
        Args: {
          p_limit?: number
          p_period_end: string
          p_period_start: string
          p_studio_id: string
        }
        Returns: {
          actor: string
          amount: number
          created_at: string
          id: string
          message: string
          meta: Json
          title: string
          type: string
        }[]
      }
      get_class_average_rating: {
        Args: { class_uuid: string }
        Returns: number
      }
      get_featured_classes: {
        Args: { category_filter?: string }
        Returns: {
          category: string
          description: string
          featured_until: string
          id: string
          title: string
        }[]
      }
      get_revenue_analytics: {
        Args: { p_end_date?: string; p_start_date?: string }
        Returns: {
          avg_instructor_percentage: number
          avg_studio_percentage: number
          gross_revenue: number
          instructor_earnings: number
          instructor_id: string
          month: string
          platform_revenue: number
          studio_earnings: number
          studio_id: string
          total_bookings: number
        }[]
      }
      get_review_stats: {
        Args: { instructor_uuid: string }
        Returns: {
          avg_rating: number
          five_star_count: number
          four_star_count: number
          one_star_count: number
          three_star_count: number
          total_reviews: number
          two_star_count: number
        }[]
      }
      get_studio_analytics_optimized: {
        Args: { p_date_from?: string; p_date_to?: string }
        Returns: Json
      }
      get_user_bookings: {
        Args: { user_id_param: string }
        Returns: {
          booking_date: string
          class_id: string
          credits_used: number
          id: string
          status: string
        }[]
      }
      get_user_credit_summary: {
        Args: { user_id_param: string }
        Returns: {
          available_credits: number
          expired_credits: number
          total_credits: number
          used_credits: number
        }[]
      }
      log_security_event: {
        Args: {
          p_action?: string
          p_event_type: string
          p_metadata?: Json
          p_resource_id?: string
          p_resource_type?: string
          p_result?: string
          p_user_id?: string
        }
        Returns: string
      }
      process_booking: {
        Args: { p_class_schedule_id: string; p_user_id: string }
        Returns: string
      }
      process_credit_purchase: {
        Args: {
          p_pack_id: string
          p_payment_intent_id: string
          p_user_id: string
        }
        Returns: Json
      }
      process_credit_refund:
        | {
            Args: { booking_id: string; refund_reason?: string }
            Returns: boolean
          }
        | {
            Args: {
              p_amount: number
              p_description: string
              p_original_transaction_id?: string
              p_refund_id?: string
              p_user_id: string
            }
            Returns: Json
          }
      process_monthly_rollover: { Args: never; Returns: undefined }
      purchase_credits: {
        Args: {
          amount_paid_param: number
          credits_param: number
          user_id_param: string
        }
        Returns: string
      }
      update_calendar_sync_status:
        | { Args: { sync_status: string; user_id: string }; Returns: undefined }
        | {
            Args: { error_msg?: string; integration_id: string; status: string }
            Returns: undefined
          }
    }
    Enums: {
      stripe_order_status: "pending" | "completed" | "canceled"
      stripe_subscription_status:
        | "not_started"
        | "incomplete"
        | "incomplete_expired"
        | "trialing"
        | "active"
        | "past_due"
        | "canceled"
        | "unpaid"
        | "paused"
      user_role: "student" | "instructor" | "admin"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      stripe_order_status: ["pending", "completed", "canceled"],
      stripe_subscription_status: [
        "not_started",
        "incomplete",
        "incomplete_expired",
        "trialing",
        "active",
        "past_due",
        "canceled",
        "unpaid",
        "paused",
      ],
      user_role: ["student", "instructor", "admin"],
    },
  },
} as const
