import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

type NotificationRow = {
  id: string
  user_id: string | null
  title: string
  body: string
  type: string
  target_id: string | null
}

type PushTokenRow = {
  id: string
  token: string
  platform: string | null
  device_locale: string | null
  last_seen_at: string | null
}

type NotificationPushJob = {
  notification: NotificationRow | null
  tokens: PushTokenRow[]
}

type ServiceAccount = {
  client_email: string
  private_key: string
  project_id: string
}

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  })
}

function buildPushData(notification: NotificationRow): Record<string, string> {
  const data: Record<string, string> = {
    notification_id: notification.id,
    type: notification.type,
  }

  if (notification.target_id) {
    data.target_id = notification.target_id
  }

  return data
}

function extractFcmErrorCode(payload: unknown): string | null {
  if (!payload || typeof payload !== 'object') return null

  const errorPayload =
    'error' in payload && payload.error && typeof payload.error === 'object'
      ? payload.error
      : null

  if (!errorPayload) return null

  if ('details' in errorPayload && Array.isArray(errorPayload.details)) {
    for (const detail of errorPayload.details) {
      if (
        detail &&
        typeof detail === 'object' &&
        'errorCode' in detail &&
        typeof detail.errorCode === 'string'
      ) {
        return detail.errorCode
      }
    }
  }

  if ('status' in errorPayload && typeof errorPayload.status === 'string') {
    return errorPayload.status
  }

  return null
}

function extractFcmErrorMessage(payload: unknown): string | null {
  if (!payload || typeof payload !== 'object') return null

  const errorPayload =
    'error' in payload && payload.error && typeof payload.error === 'object'
      ? payload.error
      : null

  if (!errorPayload) return null

  if ('message' in errorPayload && typeof errorPayload.message === 'string') {
    return errorPayload.message
  }

  return null
}

function shouldDeactivateToken(payload: unknown): boolean {
  const errorCode = extractFcmErrorCode(payload)
  return errorCode === 'UNREGISTERED'
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })

  const tokens = await jwtClient.authorize()
  const accessToken = tokens.access_token

  if (!accessToken) {
    throw new Error('FCM access token could not be created')
  }

  return accessToken
}

async function logDeliveryAttempt(
  adminClient: ReturnType<typeof createClient>,
  payload: Record<string, unknown>,
): Promise<void> {
  const { error } = await adminClient
    .from('notification_push_deliveries')
    .insert(payload)

  if (error) {
    console.error('notification_push_deliveries insert failed', error)
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return jsonResponse({ error: 'Server configuration is incomplete' }, 500)
  }

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  const providedSecret =
    request.headers.get('X-Notification-Webhook-Secret')?.trim() ?? ''

  const { data: expectedSecret, error: secretError } = await adminClient.rpc(
    'get_push_dispatch_secret',
  )

  if (secretError) {
    console.error('push dispatch secret could not be loaded', secretError)
    return jsonResponse({ error: 'Secret validation failed' }, 500)
  }

  if (!expectedSecret || providedSecret != expectedSecret) {
    return jsonResponse({ error: 'Forbidden' }, 403)
  }

  const requestBody = await request.json().catch(() => null)
  const notificationId =
    requestBody &&
    typeof requestBody === 'object' &&
    'notification_id' in requestBody &&
    typeof requestBody.notification_id === 'string'
      ? requestBody.notification_id
      : ''

  if (!notificationId) {
    return jsonResponse({ error: 'notification_id is required' }, 400)
  }

  const { data: jobData, error: jobError } = await adminClient.rpc(
    'get_notification_push_job',
    {
      p_notification_id: notificationId,
    },
  )

  if (jobError) {
    console.error('notification push job could not be loaded', jobError)
    return jsonResponse({ error: 'Notification payload could not be loaded' }, 500)
  }

  const job = (jobData ?? null) as NotificationPushJob | null
  const notification = job?.notification ?? null
  const tokens = Array.isArray(job?.tokens) ? job!.tokens : []

  if (!notification) {
    return jsonResponse({ ok: true, skipped: 'notification_not_found' })
  }

  if (!notification.user_id) {
    return jsonResponse({ ok: true, skipped: 'notification_has_no_user' })
  }

  if (tokens.length === 0) {
    await logDeliveryAttempt(adminClient, {
      notification_id: notification.id,
      user_id: notification.user_id,
      status: 'skipped',
      error_message: 'No active push token found for notification target user',
      response_body: { reason: 'no_active_tokens' },
    })

    return jsonResponse({ ok: true, skipped: 'no_active_tokens' })
  }

  const { data: serviceAccountJson, error: serviceAccountError } =
    await adminClient.rpc('get_fcm_service_account_json')

  if (serviceAccountError) {
    console.error(
      'firebase_service_account_json secret could not be loaded',
      serviceAccountError,
    )
    return jsonResponse({ error: 'FCM configuration could not be loaded' }, 500)
  }

  if (!serviceAccountJson || typeof serviceAccountJson !== 'string') {
    await logDeliveryAttempt(adminClient, {
      notification_id: notification.id,
      user_id: notification.user_id,
      status: 'failed',
      error_message:
        'firebase_service_account_json secret is missing in Supabase Vault',
      response_body: { reason: 'missing_fcm_service_account_secret' },
    })

    return jsonResponse(
      { error: 'FCM service account secret is missing' },
      500,
    )
  }

  let serviceAccount: ServiceAccount
  try {
    serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount
  } catch (error) {
    console.error('firebase_service_account_json is invalid JSON', error)
    return jsonResponse({ error: 'FCM service account JSON is invalid' }, 500)
  }

  const accessToken = await getAccessToken(serviceAccount)
  let sentCount = 0
  let failedCount = 0

  for (const tokenRow of tokens) {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: tokenRow.token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: buildPushData(notification),
          },
        }),
      },
    )

    const responsePayload = await response.json().catch(() => null)

    if (response.ok) {
      sentCount += 1
      await logDeliveryAttempt(adminClient, {
        notification_id: notification.id,
        user_id: notification.user_id,
        push_token_id: tokenRow.id,
        platform: tokenRow.platform,
        status: 'sent',
        provider_message_id:
          responsePayload &&
          typeof responsePayload === 'object' &&
          'name' in responsePayload &&
          typeof responsePayload.name === 'string'
            ? responsePayload.name
            : null,
        response_status: response.status,
        response_body: responsePayload,
        delivered_at: new Date().toISOString(),
      })
      continue
    }

    failedCount += 1
    const errorMessage =
      extractFcmErrorMessage(responsePayload) ??
      `FCM request failed with HTTP ${response.status}`

    await logDeliveryAttempt(adminClient, {
      notification_id: notification.id,
      user_id: notification.user_id,
      push_token_id: tokenRow.id,
      platform: tokenRow.platform,
      status: 'failed',
      response_status: response.status,
      response_body: responsePayload,
      error_message: errorMessage,
    })

    if (shouldDeactivateToken(responsePayload)) {
      const { error } = await adminClient
        .from('user_push_tokens')
        .update({
          is_active: false,
          last_seen_at: new Date().toISOString(),
        })
        .eq('id', tokenRow.id)

      if (error) {
        console.error('expired push token could not be deactivated', error)
      }
    }
  }

  return jsonResponse({
    ok: true,
    notification_id: notification.id,
    sent: sentCount,
    failed: failedCount,
  })
})
