import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { jwtVerify } from "npm:jose@5.9.6"

interface VerifyRequest {
  type: 'verify'
  token: string
}

interface RegisterRequest {
  type: 'register'
  token: string
  email: string
  password: string
}

type RequestBody = VerifyRequest | RegisterRequest

// listUsers() is paginated (50 per page by default), so a single call silently
// stops finding matches once there are more users than fit on one page.
async function userExistsByEmail(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  email: string,
): Promise<boolean> {
  const target = email.toLowerCase()
  const perPage = 1000

  for (let page = 1; ; page++) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage })
    if (error) throw error

    const users = data?.users ?? []
    if (users.some((user: { email?: string }) => user.email?.toLowerCase() === target)) {
      return true
    }
    // A short page means we've reached the end of the list.
    if (users.length < perPage) return false
  }
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const body: RequestBody = await req.json()
    
    if (!body.type) {
      return new Response('Missing type field', { status: 400 })
    }

    const inviteSecret = Deno.env.get('INVITE_SECRET')
    if (!inviteSecret) {
      return new Response('Server configuration error', { status: 500 })
    }

    const secret = new TextEncoder().encode(inviteSecret)

    if (body.type === 'verify') {
      if (!body.token) {
        return new Response('Missing token', { status: 400 })
      }

      let payload: Record<string, unknown>
      try {
        const result = await jwtVerify(body.token, secret)
        payload = result.payload
      } catch (_error) {
        return new Response('Invalid token', { status: 401 })
      }

      const invitedEmail = typeof payload.email === 'string' ? payload.email : ''
      if (!invitedEmail) {
        return new Response('Invalid token payload', { status: 401 })
      }

      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

      const supabase = createClient(supabaseUrl, supabaseServiceKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      })

      // Check if an account already exists for the email in the token
      if (await userExistsByEmail(supabase, invitedEmail)) {
        return new Response(JSON.stringify({
          error: 'ACCOUNT_EXISTS',
          message: 'An account with this email already exists'
        }), {
          status: 409,
          headers: { 'Content-Type': 'application/json' }
        })
      }

      return new Response(JSON.stringify(payload), {
        headers: { 'Content-Type': 'application/json' }
      })
    }

    if (body.type === 'register') {
      if (!body.token || !body.email || !body.password) {
        return new Response('Missing required fields', { status: 400 })
      }

      let payload: Record<string, unknown>
      try {
        const result = await jwtVerify(body.token, secret)
        payload = result.payload
      } catch (_error) {
        return new Response('Invalid token', { status: 401 })
      }

      if (payload.email !== body.email) {
        return new Response('Email mismatch', { status: 400 })
      }

      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      
      const supabase = createClient(supabaseUrl, supabaseServiceKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      })

      const { data, error } = await supabase.auth.admin.createUser({
        email: body.email,
        password: body.password,
        email_confirm: true
      })

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        })
      }

      // Best effort: the account exists either way, so a ledger failure must not
      // fail the registration the user just completed.
      const { error: ledgerError } = await supabase
        .from('invites')
        .update({ accepted_at: new Date().toISOString() })
        .eq('email', body.email)

      if (ledgerError) {
        console.error('Failed to mark invite accepted:', ledgerError.message)
      }

      return new Response(JSON.stringify({
        user: data.user,
        message: 'User registered successfully'
      }), {
        headers: { 'Content-Type': 'application/json' }
      })
    }

    return new Response('Invalid type', { status: 400 })

  } catch (error) {
    console.error('Function error:', error)
    return new Response('Internal server error', { status: 500 })
  }
})
