// Real-time Subscription Handlers Edge Function
// Manages WebSocket connections, real-time updates, and live notifications

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createSupabaseClient, corsHeaders, createResponse, errorResponse, getUserId, validateBody } from '../_shared/utils.ts';
import { RealtimeMessage, Notification, ChatMessage, Conversation } from '../_shared/types.ts';

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const method = req.method;
  const path = url.pathname.replace('/realtime', '');

  try {
    const authHeader = req.headers.get('Authorization');

    // Route requests
    switch (method) {
      case 'POST':
        switch (path) {
          case '/subscribe':
            return handleSubscribe(req, authHeader);
          case '/unsubscribe':
            return handleUnsubscribe(req, authHeader);
          case '/broadcast':
            return handleBroadcast(req, authHeader);
          case '/presence':
            return handlePresence(req, authHeader);
          case '/typing':
            return handleTypingStatus(req, authHeader);
          case '/live-updates':
            return handleLiveUpdates(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'GET':
        switch (path) {
          case '/status':
            return handleGetRealtimeStatus(req, authHeader);
          case '/active-users':
            return handleGetActiveUsers(req, authHeader);
          case '/notifications':
            return handleGetNotifications(req, authHeader);
          case '/conversations':
            return handleGetConversations(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      case 'PUT':
        switch (path) {
          case '/mark-notifications-read':
            return handleMarkNotificationsRead(req, authHeader);
          default:
            return errorResponse('Endpoint not found', 'NOT_FOUND', 404);
        }
      default:
        return errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED', 405);
    }
  } catch (error) {
    console.error('Realtime function error:', error);
    return errorResponse(
      'Internal server error',
      'INTERNAL_ERROR',
      500,
      { message: error.message }
    );
  }
});

// In-memory store for real-time connections (in production, use Redis)
const activeConnections = new Map<string, {
  userId: string;
  channels: Set<string>;
  lastSeen: Date;
  userAgent?: string;
  ipAddress?: string;
}>();

const typingUsers = new Map<string, {
  userId: string;
  conversationId: string;
  timestamp: Date;
}>();

async function handleSubscribe(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['channel', 'connection_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { channel, connection_id, filters } = validation.data;
  const supabase = createSupabaseClient(authHeader);

  try {
    // Validate channel permissions
    const hasPermission = await validateChannelPermission(userId, channel, supabase);
    if (!hasPermission) {
      return errorResponse('Access denied to channel', 'FORBIDDEN', 403);
    }

    // Store connection info
    const connection = activeConnections.get(connection_id) || {
      userId,
      channels: new Set(),
      lastSeen: new Date(),
      userAgent: req.headers.get('user-agent') || undefined,
      ipAddress: req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || undefined,
    };

    connection.channels.add(channel);
    connection.lastSeen = new Date();
    activeConnections.set(connection_id, connection);

    // Set up Supabase realtime subscription based on channel type
    let subscriptionConfig = {};
    
    switch (channel) {
      case 'bookings':
        subscriptionConfig = {
          table: 'bookings',
          filter: `user_id=eq.${userId}`,
          event: '*',
        };
        break;
      
      case 'classes':
        subscriptionConfig = {
          table: 'classes',
          filter: 'status=eq.published',
          event: '*',
        };
        break;
      
      case 'instructor_bookings':
        // Get instructor ID first
        const { data: instructor } = await supabase
          .from('instructor_profiles')
          .select('id')
          .eq('user_id', userId)
          .single();
        
        if (instructor) {
          subscriptionConfig = {
            table: 'bookings',
            filter: `class.instructor_id=eq.${instructor.id}`,
            event: '*',
          };
        }
        break;
      
      case 'notifications':
        subscriptionConfig = {
          table: 'notifications',
          filter: `user_id=eq.${userId}`,
          event: '*',
        };
        break;
      
      case `conversation_${channel.split('_')[1]}`:
        const conversationId = channel.split('_')[1];
        // Verify user is part of conversation
        const { data: conversation } = await supabase
          .from('conversations')
          .select('participants')
          .eq('id', conversationId)
          .single();
        
        if (conversation && conversation.participants.includes(userId)) {
          subscriptionConfig = {
            table: 'chat_messages',
            filter: `conversation_id=eq.${conversationId}`,
            event: '*',
          };
        }
        break;
      
      default:
        return errorResponse('Invalid channel', 'INVALID_CHANNEL', 400);
    }

    // Log subscription for analytics
    await supabase
      .from('realtime_subscriptions')
      .insert({
        user_id: userId,
        channel,
        connection_id,
        filters: filters || {},
        subscribed_at: new Date().toISOString(),
      })
      .select()
      .single();

    return createResponse({
      channel,
      connection_id,
      status: 'subscribed',
      active_connections: activeConnections.size,
      subscription_config: subscriptionConfig,
      message: `Successfully subscribed to ${channel}`,
    }, undefined, 201);
  } catch (error) {
    console.error('Subscribe error:', error);
    return errorResponse(
      'Failed to subscribe',
      'SUBSCRIBE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleUnsubscribe(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['connection_id']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { connection_id, channel } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Remove connection or specific channel
    if (channel) {
      const connection = activeConnections.get(connection_id);
      if (connection && connection.userId === userId) {
        connection.channels.delete(channel);
        if (connection.channels.size === 0) {
          activeConnections.delete(connection_id);
        } else {
          activeConnections.set(connection_id, connection);
        }
      }
    } else {
      // Remove entire connection
      const connection = activeConnections.get(connection_id);
      if (connection && connection.userId === userId) {
        activeConnections.delete(connection_id);
      }
    }

    // Update subscription log
    await supabase
      .from('realtime_subscriptions')
      .update({
        unsubscribed_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('connection_id', connection_id)
      .is('unsubscribed_at', null);

    return createResponse({
      connection_id,
      channel: channel || 'all',
      status: 'unsubscribed',
      active_connections: activeConnections.size,
      message: channel ? `Unsubscribed from ${channel}` : 'Disconnected from all channels',
    });
  } catch (error) {
    console.error('Unsubscribe error:', error);
    return errorResponse(
      'Failed to unsubscribe',
      'UNSUBSCRIBE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleBroadcast(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['channel', 'event', 'payload']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { channel, event, payload, target_user_id } = validation.data;
  const supabase = createSupabaseClient();

  try {
    // Validate broadcast permissions
    const canBroadcast = await validateBroadcastPermission(userId, channel, event, supabase);
    if (!canBroadcast) {
      return errorResponse('Insufficient permissions to broadcast', 'FORBIDDEN', 403);
    }

    // Prepare broadcast message
    const message: RealtimeMessage = {
      event: event as any,
      schema: 'public',
      table: channel,
      old_record: null,
      new_record: payload,
      timestamp: new Date().toISOString(),
    };

    // Find target connections
    let targetConnections: string[] = [];
    
    if (target_user_id) {
      // Broadcast to specific user
      for (const [connectionId, connection] of activeConnections) {
        if (connection.userId === target_user_id && connection.channels.has(channel)) {
          targetConnections.push(connectionId);
        }
      }
    } else {
      // Broadcast to all subscribers of the channel
      for (const [connectionId, connection] of activeConnections) {
        if (connection.channels.has(channel)) {
          targetConnections.push(connectionId);
        }
      }
    }

    // In a real implementation, this would send through WebSocket connections
    // For now, we'll simulate by storing messages for retrieval
    const broadcastRecord = {
      channel,
      event,
      payload,
      sender_id: userId,
      target_connections: targetConnections,
      message,
      created_at: new Date().toISOString(),
    };

    // Log broadcast for analytics and debugging
    await supabase
      .from('realtime_broadcasts')
      .insert(broadcastRecord);

    return createResponse({
      channel,
      event,
      targets_reached: targetConnections.length,
      message_id: crypto.randomUUID(),
      timestamp: message.timestamp,
      message: `Broadcast sent to ${targetConnections.length} connection(s)`,
    });
  } catch (error) {
    console.error('Broadcast error:', error);
    return errorResponse(
      'Failed to broadcast',
      'BROADCAST_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handlePresence(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['channel', 'status']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { channel, status, metadata } = validation.data;
  const supabase = createSupabaseClient(authHeader);

  try {
    // Update user presence
    const presenceData = {
      user_id: userId,
      channel,
      status, // 'online', 'away', 'busy', 'offline'
      metadata: metadata || {},
      last_seen: new Date().toISOString(),
    };

    const { data: presence, error } = await supabase
      .from('user_presence')
      .upsert(presenceData, {
        onConflict: 'user_id,channel',
        ignoreDuplicates: false,
      })
      .select()
      .single();

    if (error) {
      return errorResponse(
        'Failed to update presence',
        'PRESENCE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    // Broadcast presence change to other users in the channel
    await handleBroadcast(new Request(req.url, {
      method: 'POST',
      headers: req.headers,
      body: JSON.stringify({
        channel,
        event: 'presence',
        payload: {
          user_id: userId,
          status,
          metadata,
          timestamp: presenceData.last_seen,
        },
      }),
    }), authHeader);

    return createResponse({
      user_id: userId,
      channel,
      status,
      metadata,
      last_seen: presenceData.last_seen,
    });
  } catch (error) {
    console.error('Presence error:', error);
    return errorResponse(
      'Failed to update presence',
      'PRESENCE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleTypingStatus(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['conversation_id', 'typing']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { conversation_id, typing } = validation.data;
  const supabase = createSupabaseClient(authHeader);

  try {
    // Verify user is part of conversation
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('participants')
      .eq('id', conversation_id)
      .single();

    if (convError || !conversation.participants.includes(userId)) {
      return errorResponse('Conversation not found or access denied', 'FORBIDDEN', 403);
    }

    const typingKey = `${conversation_id}_${userId}`;
    
    if (typing) {
      // User started typing
      typingUsers.set(typingKey, {
        userId,
        conversationId: conversation_id,
        timestamp: new Date(),
      });

      // Auto-remove after 10 seconds
      setTimeout(() => {
        typingUsers.delete(typingKey);
      }, 10000);
    } else {
      // User stopped typing
      typingUsers.delete(typingKey);
    }

    // Broadcast typing status to other conversation participants
    const otherParticipants = conversation.participants.filter(p => p !== userId);
    
    for (const participantId of otherParticipants) {
      await handleBroadcast(new Request(req.url, {
        method: 'POST',
        headers: req.headers,
        body: JSON.stringify({
          channel: `conversation_${conversation_id}`,
          event: 'typing',
          payload: {
            user_id: userId,
            conversation_id,
            typing,
            timestamp: new Date().toISOString(),
          },
          target_user_id: participantId,
        }),
      }), authHeader);
    }

    return createResponse({
      conversation_id,
      user_id: userId,
      typing,
      active_typers: Array.from(typingUsers.values())
        .filter(t => t.conversationId === conversation_id && t.userId !== userId)
        .length,
    });
  } catch (error) {
    console.error('Typing status error:', error);
    return errorResponse(
      'Failed to update typing status',
      'TYPING_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleLiveUpdates(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const validation = validateBody(body, ['updates']);
  
  if (!validation.valid) {
    return errorResponse('Invalid request body', 'VALIDATION_ERROR', 400, {
      errors: validation.errors,
    });
  }

  const { updates } = validation.data;
  const supabase = createSupabaseClient();

  try {
    const results = [];

    for (const update of updates) {
      const { type, id, data } = update;
      
      switch (type) {
        case 'class_update':
          // Real-time class updates (capacity, schedule changes, etc.)
          const { data: classData, error: classError } = await supabase
            .from('classes')
            .select('*, instructor:instructor_profiles!inner(user_id)')
            .eq('id', id)
            .single();

          if (!classError && classData.instructor.user_id === userId) {
            await supabase
              .from('classes')
              .update(data)
              .eq('id', id);
            
            // Broadcast to all class subscribers
            await handleBroadcast(new Request(req.url, {
              method: 'POST',
              headers: req.headers,
              body: JSON.stringify({
                channel: 'classes',
                event: 'UPDATE',
                payload: { ...classData, ...data },
              }),
            }), authHeader);

            results.push({ type, id, status: 'success' });
          } else {
            results.push({ type, id, status: 'failed', error: 'Not authorized or class not found' });
          }
          break;

        case 'booking_status':
          // Real-time booking status updates
          const { data: bookingData, error: bookingError } = await supabase
            .from('bookings')
            .select('*, class:classes!inner(instructor:instructor_profiles!inner(user_id))')
            .eq('id', id)
            .single();

          if (!bookingError && 
              (bookingData.user_id === userId || bookingData.class.instructor.user_id === userId)) {
            await supabase
              .from('bookings')
              .update(data)
              .eq('id', id);

            // Broadcast to relevant users
            await handleBroadcast(new Request(req.url, {
              method: 'POST',
              headers: req.headers,
              body: JSON.stringify({
                channel: 'bookings',
                event: 'UPDATE',
                payload: { ...bookingData, ...data },
                target_user_id: bookingData.user_id,
              }),
            }), authHeader);

            if (bookingData.class.instructor.user_id !== userId) {
              await handleBroadcast(new Request(req.url, {
                method: 'POST',
                headers: req.headers,
                body: JSON.stringify({
                  channel: 'instructor_bookings',
                  event: 'UPDATE',
                  payload: { ...bookingData, ...data },
                  target_user_id: bookingData.class.instructor.user_id,
                }),
              }), authHeader);
            }

            results.push({ type, id, status: 'success' });
          } else {
            results.push({ type, id, status: 'failed', error: 'Not authorized or booking not found' });
          }
          break;

        default:
          results.push({ type, id, status: 'failed', error: 'Unsupported update type' });
      }
    }

    return createResponse({
      updates_processed: results.length,
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Live updates error:', error);
    return errorResponse(
      'Failed to process live updates',
      'LIVE_UPDATES_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetNotifications(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const unread_only = url.searchParams.get('unread_only') === 'true';
  const supabase = createSupabaseClient(authHeader);

  try {
    let query = supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (unread_only) {
      query = query.eq('read', false);
    }

    const { data: notifications, error } = await query;

    if (error) {
      return errorResponse(
        'Failed to get notifications',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    const unreadCount = unread_only 
      ? notifications?.length || 0
      : await supabase
          .from('notifications')
          .select('id', { count: 'exact' })
          .eq('user_id', userId)
          .eq('read', false)
          .then(({ count }) => count || 0);

    return createResponse({
      notifications,
      unread_count: typeof unreadCount === 'number' ? unreadCount : notifications?.filter(n => !n.read).length || 0,
      total_count: notifications?.length || 0,
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    return errorResponse(
      'Failed to get notifications',
      'NOTIFICATIONS_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleMarkNotificationsRead(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const body = await req.json();
  const { notification_ids } = body;
  const supabase = createSupabaseClient();

  try {
    let query = supabase
      .from('notifications')
      .update({ 
        read: true, 
        read_at: new Date().toISOString() 
      })
      .eq('user_id', userId);

    if (notification_ids && Array.isArray(notification_ids)) {
      query = query.in('id', notification_ids);
    } else {
      // Mark all notifications as read
      query = query.eq('read', false);
    }

    const { data, error } = await query.select();

    if (error) {
      return errorResponse(
        'Failed to mark notifications as read',
        'UPDATE_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      marked_read: data?.length || 0,
      notification_ids: data?.map(n => n.id) || [],
      message: `${data?.length || 0} notification(s) marked as read`,
    });
  } catch (error) {
    console.error('Mark notifications read error:', error);
    return errorResponse(
      'Failed to mark notifications as read',
      'UPDATE_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function validateChannelPermission(userId: string, channel: string, supabase: any): Promise<boolean> {
  // Implement channel permission logic based on your business rules
  switch (channel) {
    case 'bookings':
    case 'notifications':
      return true; // Users can subscribe to their own bookings and notifications
    
    case 'classes':
      return true; // Anyone can subscribe to public classes
    
    case 'instructor_bookings':
      // Check if user is an instructor
      const { data: instructor } = await supabase
        .from('instructor_profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
      return !!instructor;
    
    default:
      if (channel.startsWith('conversation_')) {
        const conversationId = channel.split('_')[1];
        const { data: conversation } = await supabase
          .from('conversations')
          .select('participants')
          .eq('id', conversationId)
          .single();
        return conversation && conversation.participants.includes(userId);
      }
      return false;
  }
}

async function validateBroadcastPermission(userId: string, channel: string, event: string, supabase: any): Promise<boolean> {
  // Implement broadcast permission logic
  switch (channel) {
    case 'classes':
      // Only instructors can broadcast class updates
      const { data: instructor } = await supabase
        .from('instructor_profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
      return !!instructor;
    
    case 'bookings':
    case 'instructor_bookings':
      // Users can broadcast their own booking updates
      return true;
    
    default:
      if (channel.startsWith('conversation_')) {
        const conversationId = channel.split('_')[1];
        const { data: conversation } = await supabase
          .from('conversations')
          .select('participants')
          .eq('id', conversationId)
          .single();
        return conversation && conversation.participants.includes(userId);
      }
      return false;
  }
}

async function handleGetActiveUsers(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  const url = new URL(req.url);
  const channel = url.searchParams.get('channel');
  const supabase = createSupabaseClient(authHeader);

  try {
    let query = supabase
      .from('user_presence')
      .select(`
        *,
        user:user_profiles!inner(first_name, last_name, avatar_url)
      `)
      .neq('status', 'offline')
      .gte('last_seen', new Date(Date.now() - 5 * 60 * 1000).toISOString()); // Last 5 minutes

    if (channel) {
      query = query.eq('channel', channel);
    }

    const { data: activeUsers, error } = await query;

    if (error) {
      return errorResponse(
        'Failed to get active users',
        'FETCH_ERROR',
        500,
        { supabase_error: error }
      );
    }

    return createResponse({
      active_users: activeUsers,
      count: activeUsers?.length || 0,
      channel: channel || 'all',
    });
  } catch (error) {
    console.error('Get active users error:', error);
    return errorResponse(
      'Failed to get active users',
      'ACTIVE_USERS_ERROR',
      500,
      { error: error.message }
    );
  }
}

async function handleGetRealtimeStatus(req: Request, authHeader?: string): Promise<Response> {
  const userId = await getUserId(authHeader);
  if (!userId) {
    return errorResponse('Authentication required', 'UNAUTHORIZED', 401);
  }

  try {
    const userConnections = Array.from(activeConnections.values())
      .filter(conn => conn.userId === userId);

    const status = {
      connected: userConnections.length > 0,
      connections: userConnections.length,
      channels: [...new Set(userConnections.flatMap(conn => Array.from(conn.channels)))],
      last_activity: userConnections.length > 0 
        ? Math.max(...userConnections.map(conn => conn.lastSeen.getTime()))
        : null,
      server_time: new Date().toISOString(),
      active_connections_total: activeConnections.size,
    };

    return createResponse(status);
  } catch (error) {
    console.error('Get realtime status error:', error);
    return errorResponse(
      'Failed to get realtime status',
      'STATUS_ERROR',
      500,
      { error: error.message }
    );
  }
}