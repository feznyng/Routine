import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface WebhookPayload {
  body: string,
  source_id: string
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  const authHeader = req.headers.get('Authorization')!;  
  const token = authHeader.replace('Bearer ', '');  
  const { data } = await supabase.auth.getUser(token);
  const user = data.user;

  if (!user) {
    return new Response(JSON.stringify({message: 'failed'}), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const { data: devices } = await supabase
    .from('devices')
    .select('fcm_token, id')
    .eq('user_id', user.id)
    .neq('id', payload.source_id)
    .or('deleted.is.null,deleted.eq.false')
    .not('fcm_token', 'is', null)

  if (devices && devices.length > 0) {
    // Get access token once for all notifications
    const accessToken = await getAccessToken({
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key,
    })
    
    // Process notifications for all devices in parallel
    const notificationResults = await Promise.allSettled(
      devices.map(async (device) => {
        const fcmToken = device.fcm_token as string;
        
        try {
          const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({
                message: {
                  token: fcmToken,
                  data: {},
                  apns: {
                    headers: {
                      'apns-priority': '10',
                      'apns-push-type': 'background'
                    },
                    payload: {
                      aps: {
                        'content-available': 1
                      }
                    }
                  }
                },
              }),
            }
          );
          
          const resData = await res.json()
          console.log('message status for device', device.id, ':', res.status, resData);
          return { deviceId: device.id, status: res.status, data: resData };
        } catch (error) {
          console.error('Error sending notification to device', device.id, ':', error);
          return { deviceId: device.id, error };
        }
      })
    );
    
    console.log(`Sent notifications to ${notificationResults.length} devices`);
  }

  return new Response(JSON.stringify({message: 'successful'}), {
    headers: { 'Content-Type': 'application/json' },
  })
})

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}