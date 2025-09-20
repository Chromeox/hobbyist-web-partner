// Generated types based on your main Supabase schema
// This should be kept in sync with your main project's database schema

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string
          role: 'student' | 'instructor' | 'admin'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          email: string
          role?: 'student' | 'instructor' | 'admin'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          role?: 'student' | 'instructor' | 'admin'
          created_at?: string
          updated_at?: string
        }
      }
      user_profiles: {
        Row: {
          id: string
          user_id: string
          first_name: string
          last_name: string
          phone?: string
          avatar_url?: string
          bio?: string
          date_of_birth?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          first_name: string
          last_name: string
          phone?: string
          avatar_url?: string
          bio?: string
          date_of_birth?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          first_name?: string
          last_name?: string
          phone?: string
          avatar_url?: string
          bio?: string
          date_of_birth?: string
          created_at?: string
          updated_at?: string
        }
      }
      instructors: {
        Row: {
          id: string
          user_id: string
          business_name?: string
          stripe_account_id?: string
          stripe_account_status: 'pending' | 'active' | 'restricted' | 'disabled'
          commission_rate: number
          rating: number
          total_reviews: number
          total_students: number
          verified: boolean
          specialties: string[]
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          business_name?: string
          stripe_account_id?: string
          stripe_account_status?: 'pending' | 'active' | 'restricted' | 'disabled'
          commission_rate?: number
          rating?: number
          total_reviews?: number
          total_students?: number
          verified?: boolean
          specialties?: string[]
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          business_name?: string
          stripe_account_id?: string
          stripe_account_status?: 'pending' | 'active' | 'restricted' | 'disabled'
          commission_rate?: number
          rating?: number
          total_reviews?: number
          total_students?: number
          verified?: boolean
          specialties?: string[]
          created_at?: string
          updated_at?: string
        }
      }
      classes: {
        Row: {
          id: string
          instructor_id: string
          category_id: string
          title: string
          description: string
          price: number
          duration_minutes: number
          max_participants: number
          current_participants: number
          difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
          tags: string[]
          status: 'draft' | 'published' | 'cancelled' | 'completed'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          instructor_id: string
          category_id: string
          title: string
          description: string
          price: number
          duration_minutes: number
          max_participants: number
          current_participants?: number
          difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
          tags?: string[]
          status?: 'draft' | 'published' | 'cancelled' | 'completed'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          instructor_id?: string
          category_id?: string
          title?: string
          description?: string
          price?: number
          duration_minutes?: number
          max_participants?: number
          current_participants?: number
          difficulty_level?: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
          tags?: string[]
          status?: 'draft' | 'published' | 'cancelled' | 'completed'
          created_at?: string
          updated_at?: string
        }
      }
      bookings: {
        Row: {
          id: string
          user_id: string
          class_id: string
          session_id?: string
          status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
          payment_status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_intent_id?: string
          amount: number
          commission_amount: number
          instructor_payout: number
          booking_date: string
          notes?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          class_id: string
          session_id?: string
          status?: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
          payment_status?: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_intent_id?: string
          amount: number
          commission_amount: number
          instructor_payout: number
          booking_date: string
          notes?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          class_id?: string
          session_id?: string
          status?: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
          payment_status?: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_intent_id?: string
          amount?: number
          commission_amount?: number
          instructor_payout?: number
          booking_date?: string
          notes?: string
          created_at?: string
          updated_at?: string
        }
      }
      payments: {
        Row: {
          id: string
          booking_id: string
          user_id: string
          amount: number
          currency: string
          status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_method: 'card' | 'apple_pay' | 'google_pay' | 'bank_transfer'
          stripe_payment_intent_id?: string
          stripe_charge_id?: string
          stripe_refund_id?: string
          metadata: any
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          booking_id: string
          user_id: string
          amount: number
          currency?: string
          status?: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_method: 'card' | 'apple_pay' | 'google_pay' | 'bank_transfer'
          stripe_payment_intent_id?: string
          stripe_charge_id?: string
          stripe_refund_id?: string
          metadata?: any
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          booking_id?: string
          user_id?: string
          amount?: number
          currency?: string
          status?: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
          payment_method?: 'card' | 'apple_pay' | 'google_pay' | 'bank_transfer'
          stripe_payment_intent_id?: string
          stripe_charge_id?: string
          stripe_refund_id?: string
          metadata?: any
          created_at?: string
          updated_at?: string
        }
      }
      reviews: {
        Row: {
          id: string
          user_id: string
          class_id: string
          instructor_id: string
          booking_id: string
          rating: number
          title?: string
          comment?: string
          instructor_response?: string
          helpful_count: number
          verified_booking: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          class_id: string
          instructor_id: string
          booking_id: string
          rating: number
          title?: string
          comment?: string
          instructor_response?: string
          helpful_count?: number
          verified_booking?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          class_id?: string
          instructor_id?: string
          booking_id?: string
          rating?: number
          title?: string
          comment?: string
          instructor_response?: string
          helpful_count?: number
          verified_booking?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      categories: {
        Row: {
          id: string
          name: string
          slug: string
          description?: string
          icon?: string
          image_url?: string
          parent_id?: string
          order: number
          is_active: boolean
        }
        Insert: {
          id?: string
          name: string
          slug: string
          description?: string
          icon?: string
          image_url?: string
          parent_id?: string
          order?: number
          is_active?: boolean
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          description?: string
          icon?: string
          image_url?: string
          parent_id?: string
          order?: number
          is_active?: boolean
        }
      }
      conversations: {
        Row: {
          id: string
          studio_id?: string
          instructor_id: string
          type: 'individual' | 'group'
          name: string
          participants: string[]
          last_message?: string
          last_message_at?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          studio_id?: string
          instructor_id: string
          type: 'individual' | 'group'
          name: string
          participants: string[]
          last_message?: string
          last_message_at?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          studio_id?: string
          instructor_id?: string
          type?: 'individual' | 'group'
          name?: string
          participants?: string[]
          last_message?: string
          last_message_at?: string
          created_at?: string
          updated_at?: string
        }
      }
      messages: {
        Row: {
          id: string
          conversation_id: string
          sender_id: string
          content: string
          attachments?: Array<{
            type: 'image' | 'file'
            url: string
            name: string
          }>
          read_at?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          conversation_id: string
          sender_id: string
          content: string
          attachments?: Array<{
            type: 'image' | 'file'
            url: string
            name: string
          }>
          read_at?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          conversation_id?: string
          sender_id?: string
          content?: string
          attachments?: Array<{
            type: 'image' | 'file'
            url: string
            name: string
          }>
          read_at?: string
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      user_role: 'student' | 'instructor' | 'admin'
      booking_status: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
      payment_status: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded'
      class_status: 'draft' | 'published' | 'cancelled' | 'completed'
      difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'all_levels'
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}