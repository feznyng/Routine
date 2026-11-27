import { createClient } from 'npm:@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

interface ErrorDetail {
  error: string;
  message: string;
}

function createErrorResponse(error: string, message: string): Response {
  return new Response(
    JSON.stringify({ error, message }),
    { 
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}

// Deleting the auth user removes the user's rows in devices, routines, groups
// and users through their `on delete cascade` foreign keys. Postgres runs the
// cascade in the same statement, so either everything is deleted or nothing is.
async function deleteAuthUser(userId: string): Promise<void> {
  const { error } = await supabase.auth.admin.deleteUser(userId);

  if (error) {
    console.error('Error deleting user account:', error);
    throw { error: 'Failed to delete user account', message: error.message } as ErrorDetail;
  }

  console.log('Successfully deleted auth user');
}

async function handleRequest(req: Request): Promise<Response> {
  try {
    // Get user from authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Missing authentication token' }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    const { data } = await supabase.auth.getUser(token);
    const user = data.user;

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Invalid authentication token' }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    console.log(`Starting account deletion process for user: ${user.id}`);

    try {
      await deleteAuthUser(user.id);
    } catch (err) {
      const error = err as ErrorDetail;
      return createErrorResponse(error.error, error.message);
    }

    console.log(`Successfully deleted user account: ${user.id}`);
    
    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Account and all associated data successfully deleted'
      }),
      { 
        headers: { 'Content-Type': 'application/json' }
      }
    );
  } catch (err) {
    console.error('Unexpected error:', err);
    return createErrorResponse(
      'Internal server error',
      err instanceof Error ? err.message : 'An unknown error occurred'
    );
  }
}

Deno.serve(handleRequest);