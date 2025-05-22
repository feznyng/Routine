import { createClient } from 'npm:@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  try {
    // Get user from authorization header
    const authHeader = req.headers.get('Authorization')!;
    const token = authHeader.replace('Bearer ', '');
    const { data } = await supabase.auth.getUser(token);
    const user = data.user;

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Invalid or missing authentication token' }),
        { 
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    console.log(`Starting account deletion process for user: ${user.id}`);

    const { error: groupsError } = await supabase
      .from('groups')
      .delete()
      .eq('user_id', user.id);
    
    if (groupsError) {
      console.error('Error deleting groups:', groupsError);
    } else {
      console.log('Successfully deleted groups data');
    }

    const { error: routinesError } = await supabase
      .from('routines')
      .delete()
      .eq('user_id', user.id);
    
    if (routinesError) {
      console.error('Error deleting routines:', routinesError);
    } else {
      console.log('Successfully deleted routines data');
    }

    const { error: devicesError } = await supabase
      .from('devices')
      .delete()
      .eq('user_id', user.id);
    
    if (devicesError) {
      console.error('Error deleting devices:', devicesError);
    } else {
      console.log('Successfully deleted devices data');
    }

    const { error: usersError } = await supabase
      .from('users')
      .delete()
      .eq('id', user.id);
    
    if (usersError) {
      console.error('Error deleting user data:', usersError);
    } else {
      console.log('Successfully deleted user data');
    }

    const { error: authError } = await supabase.auth.admin.deleteUser(
      user.id
    );

    if (authError) {
      console.error('Error deleting user account:', authError);
      return new Response(
        JSON.stringify({ 
          error: 'Failed to delete user account',
          message: authError.message
        }),
        { 
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        }
      );
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
  } catch (error) {
    console.error('Unexpected error during account deletion:', error);
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'Unknown error occurred'
      }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
})