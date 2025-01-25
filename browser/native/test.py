#!/usr/bin/env python3
import json
import struct
import sys

# Create the message
message = {
    'action': 'ping',
    'data': {}
}

# Convert the message to JSON and encode to bytes
message_json = json.dumps(message)
message_bytes = message_json.encode('utf-8')

# Write the message length as a 32-bit integer
sys.stdout.buffer.write(struct.pack('=I', len(message_bytes)))
# Write the message itself
sys.stdout.buffer.write(message_bytes)
sys.stdout.flush()
