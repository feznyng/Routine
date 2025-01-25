import json
import struct
import subprocess
import threading
import queue
from typing import Dict, Any

class NativeMessagingTest:
    def __init__(self, native_host_path: str):
        self.native_host_path = native_host_path
        self.process = None
        self.response_queue = queue.Queue()
        self.success_count = 0
        self.fail_count = 0

    def write_message(self, message: Dict[str, Any]) -> None:
        message_json = json.dumps(message)
        message_bytes = message_json.encode('utf-8')
        
        # Write message length as native-endian unsigned 32-bit integer
        self.process.stdin.write(struct.pack('=I', len(message_bytes)))
        # Write the message itself
        self.process.stdin.write(message_bytes)
        self.process.stdin.flush()

    def read_message(self) -> Dict[str, Any]:
        # Read the message length (first 4 bytes)
        length_bytes = self.process.stdout.read(4)
        if len(length_bytes) == 0:
            raise EOFError("No data received from native host")
        
        message_length = struct.unpack('=I', length_bytes)[0]
        
        # Read the message content
        message_bytes = self.process.stdout.read(message_length)
        if len(message_bytes) != message_length:
            raise EOFError(f"Expected {message_length} bytes, got {len(message_bytes)}")
        
        return json.loads(message_bytes.decode('utf-8'))

    def reader_thread(self) -> None:
        try:
            while True:
                response = self.read_message()
                self.response_queue.put(response)
        except (EOFError, json.JSONDecodeError) as e:
            self.response_queue.put({"error": str(e)})

    def run_test(self, test_name: str, message: Dict[str, Any], expected_response: Dict[str, Any]) -> None:
        print(f"\nRunning test: {test_name}")
        print(f"Sending message: {json.dumps(message)}")
        
        try:
            self.write_message(message)
            response = self.response_queue.get(timeout=5)
            print(f"Received response: {json.dumps(response)}")
            
            if response == expected_response:
                print(" Test passed")
                self.success_count += 1
            else:
                print(" Test failed")
                print(f"Expected: {json.dumps(expected_response)}")
                print(f"Got: {json.dumps(response)}")
                self.fail_count += 1
        except queue.Empty:
            print(" Test failed: No response received within timeout")
            self.fail_count += 1
        except Exception as e:
            print(f" Test failed with error: {e}")
            self.fail_count += 1

    def run_all_tests(self) -> None:
        try:
            # Start the native host process
            self.process = subprocess.Popen(
                [self.native_host_path],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0  # Disable buffering
            )

            # Start reader thread
            reader = threading.Thread(target=self.reader_thread)
            reader.daemon = True
            reader.start()

            # Test cases
            tests = [
                (
                    "Basic ping test",
                    {"action": "ping", "data": {}},
                    {"action": "response", "data": {"status": "pong"}}
                ),
                (
                    "Site blocked notification test",
                    {
                        "action": "site_blocked",
                        "data": {
                            "url": "https://discord.com",
                            "timestamp": 1234567890
                        }
                    },
                    {"action": "response", "data": {"error": "Unknown action"}}
                ),
                (
                    "Invalid action test",
                    {"action": "invalid_action", "data": {}},
                    {"action": "response", "data": {"error": "Unknown action"}}
                )
            ]

            for test_name, message, expected_response in tests:
                self.run_test(test_name, message, expected_response)

            # Print summary
            print("\nTest Summary:")
            print(f"Passed: {self.success_count}")
            print(f"Failed: {self.fail_count}")
            print(f"Total: {self.success_count + self.fail_count}")

        finally:
            # Cleanup
            if self.process:
                self.process.terminate()
                self.process.wait(timeout=5)

if __name__ == "__main__":
    native_host_path = "./target/release/native"
    tester = NativeMessagingTest(native_host_path)
    tester.run_all_tests()