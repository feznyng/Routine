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

      try {
        const { payload } = await jwtVerify(body.token, secret)
        
        // Check if an account already exists for this email
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        
        const supabase = createClient(supabaseUrl, supabaseServiceKey, {
          auth: {
            autoRefreshToken: false,
            persistSession: false
          }
        })

        // Check if user already exists by listing all users and filtering by email
        const { data: users } = await supabase.auth.admin.listUsers()
        const userExists = users.users.some(user => user.email === payload.email)

        if (userExists) {
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
      } catch (_error) {
        return new Response('Invalid token', { status: 401 })
      }
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
