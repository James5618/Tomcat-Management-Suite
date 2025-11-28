#!/bin/bash
# Test script for the new external retry_version_detection.sh script

echo "Testing retry_version_detection.sh external script..."
echo "===================================================="

# Test 1: Normal version (should pass through unchanged)
echo "Test 1: Normal version string"
result=$(bash retry_version_detection.sh "/opt/tomcat" "Apache Tomcat/9.0.50")
echo "Result: $result"
echo "Expected: Apache Tomcat/9.0.50"
echo ""

# Test 2: Permission denied scenario (should trigger retry logic)
echo "Test 2: Permission denied scenario"
result=$(bash retry_version_detection.sh "/opt/tomcat" "Error: permission denied")
echo "Result: $result"
echo "Expected: Error: permission denied (after retry attempts)"
echo ""

# Test 3: Empty directory (should pass through unchanged)
echo "Test 3: Empty directory"
result=$(bash retry_version_detection.sh "/nonexistent" "Directory not found")
echo "Result: $result"
echo "Expected: Directory not found"
echo ""

echo "All tests completed!"
echo "Note: The script will only perform actual user switching if 'permission denied' is detected"
echo "and if the necessary permissions (sudo) are available."

