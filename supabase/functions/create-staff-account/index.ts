import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type StaffRole = 'admin' | 'sks';

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
        },
    });
}

function parseStringList(value: unknown): string[] {
    if (!Array.isArray(value)) return [];
    return value.filter((item): item is string => typeof item === 'string');
}

Deno.serve(async (request) => {
    if (request.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
        return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
        return jsonResponse({ error: 'Server configuration is incomplete' }, 500);
    }

    const authHeader = request.headers.get('Authorization');
    if (!authHeader) {
        return jsonResponse({ error: 'Missing authorization header' }, 401);
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
    });

    const actorClient = createClient(supabaseUrl, supabaseAnonKey, {
        global: {
            headers: {
                Authorization: authHeader,
            },
        },
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
    });

    const actorResult = await actorClient.auth.getUser();
    const actor = actorResult.data.user;
    if (actorResult.error != null || actor == null) {
        return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const isAdminFromMetadata = actor.app_metadata?.role === 'admin';
    let isAdminFromRoleTable = false;

    if (!isAdminFromMetadata) {
        const roleResult = await adminClient
            .from('user_roles')
            .select('role')
            .eq('user_id', actor.id)
            .eq('role', 'admin')
            .limit(1);

        if (roleResult.error != null) {
            return jsonResponse({ error: 'Role check failed', detail: roleResult.error.message }, 500);
        }

        isAdminFromRoleTable = Array.isArray(roleResult.data) && roleResult.data.length > 0;
    }

    if (!isAdminFromMetadata && !isAdminFromRoleTable) {
        return jsonResponse({ error: 'Forbidden' }, 403);
    }

    const body = await request.json().catch(() => null);
    if (body == null || typeof body !== 'object') {
        return jsonResponse({ error: 'Invalid JSON body' }, 400);
    }

    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const password = typeof body.password === 'string' ? body.password : '';
    const displayName = typeof body.display_name === 'string' ? body.display_name.trim() : '';

    if (!email.includes('@')) {
        return jsonResponse({ error: 'Valid email is required' }, 400);
    }

    if (password.length < 6) {
        return jsonResponse({ error: 'Password must be at least 6 characters' }, 400);
    }

    if (displayName.length === 0) {
        return jsonResponse({ error: 'Display name is required' }, 400);
    }

    const requestedRoles = parseStringList(body.roles);
    const sanitizedRoles = Array.from(
        new Set(
            requestedRoles.filter((role): role is StaffRole => role === 'admin' || role === 'sks'),
        ),
    );

    const requestedVenueIds = parseStringList(body.editable_venue_ids);
    const sanitizedVenueIds = Array.from(
        new Set(requestedVenueIds.map((id) => id.trim()).filter((id) => id.length > 0)),
    );

    let createdUserId: string | null = null;

    try {
        const createUserResult = await adminClient.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: {
                display_name: displayName,
            },
        });

        if (createUserResult.error != null || createUserResult.data.user == null) {
            return jsonResponse(
                {
                    error: createUserResult.error?.message ?? 'User could not be created',
                },
                400,
            );
        }

        createdUserId = createUserResult.data.user.id;

        const upsertProfileResult = await adminClient.from('users').upsert({
            id: createdUserId,
            email,
            display_name: displayName,
            created_at: new Date().toISOString(),
        });

        if (upsertProfileResult.error != null) {
            throw new Error(upsertProfileResult.error.message);
        }

        const clearRolesResult = await adminClient
            .from('user_roles')
            .delete()
            .eq('user_id', createdUserId);

        if (clearRolesResult.error != null) {
            throw new Error(clearRolesResult.error.message);
        }

        if (sanitizedRoles.length > 0) {
            const insertRolesResult = await adminClient.from('user_roles').insert(
                sanitizedRoles.map((role) => ({
                    user_id: createdUserId,
                    role,
                    created_by: actor.id,
                })),
            );

            if (insertRolesResult.error != null) {
                throw new Error(insertRolesResult.error.message);
            }
        }

        const clearVenuePermissionsResult = await adminClient
            .from('user_venue_permissions')
            .delete()
            .eq('user_id', createdUserId);

        if (clearVenuePermissionsResult.error != null) {
            throw new Error(clearVenuePermissionsResult.error.message);
        }

        if (sanitizedVenueIds.length > 0) {
            const insertVenuePermissionsResult = await adminClient.from('user_venue_permissions').insert(
                sanitizedVenueIds.map((venueId) => ({
                    user_id: createdUserId,
                    venue_id: venueId,
                    created_by: actor.id,
                })),
            );

            if (insertVenuePermissionsResult.error != null) {
                throw new Error(insertVenuePermissionsResult.error.message);
            }
        }

        return jsonResponse({ user_id: createdUserId }, 201);
    } catch (error) {
        if (createdUserId != null) {
            await adminClient.auth.admin.deleteUser(createdUserId);
        }

        return jsonResponse(
            {
                error: 'Provisioning failed',
                detail: error instanceof Error ? error.message : String(error),
            },
            500,
        );
    }
});
