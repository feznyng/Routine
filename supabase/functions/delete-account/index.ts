import { createClient } from 'npm:@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

interface DeleteOperation {
  table: string;
  idField: string;
  errorMessage: string;
}

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

async function deleteFromTable(
  userId: string,
  operation: DeleteOperation
): Promise<void> {
  const { error } = await supabase
    .from(operation.table)
    .delete()
    .eq(operation.idField, userId);

  if (error) {
    console.error(`Error deleting ${operation.table}:`, error);
    throw { error: operation.errorMessage, message: error.message } as ErrorDetail;
  }

  console.log(`Successfully deleted ${operation.table} data`);
}

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

    // Define deletion operations
    const operations: DeleteOperation[] = [
      { table: 'groups', idField: 'user_id', errorMessage: 'Failed to delete groups' },
      { table: 'routines', idField: 'user_id', errorMessage: 'Failed to delete routines' },
      { table: 'devices', idField: 'user_id', errorMessage: 'Failed to delete devices' },
      { table: 'users', idField: 'id', errorMessage: 'Failed to delete user data' }
    ];

    try {
      for (const operation of operations) {
        await deleteFromTable(user.id, operation);
      }
      
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