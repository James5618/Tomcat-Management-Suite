#!/bin/bash
set -e

TOMCAT_DIR="$1"
ORIGINAL_VERSION="$2"
CURRENT_USER="$(whoami)"

# Only retry if version detection failed due to permissions
if echo "$ORIGINAL_VERSION" | grep -q "permission denied"; then
  echo "DEBUG: Retrying version detection with proper user context for $TOMCAT_DIR" >&2
  echo "DEBUG: Current user: $CURRENT_USER" >&2
  
  # Method 1: Try to find the Tomcat process owner
  TOMCAT_USER=""
  for pid in $(ps aux | grep java | grep -i catalina | grep "$TOMCAT_DIR" | grep -v grep | awk '{print $2}'); do
    if [ -n "$pid" ]; then
      TOMCAT_USER=$(ps -o user= -p $pid 2>/dev/null | tr -d ' ')
      if [ -n "$TOMCAT_USER" ]; then
        echo "DEBUG: Found Tomcat process running as user: $TOMCAT_USER" >&2
        break
      fi
    fi
  done
  
  # Method 2: If no running process, detect directory owner
  if [ -z "$TOMCAT_USER" ]; then
    if [ -d "$TOMCAT_DIR" ]; then
      TOMCAT_USER=$(stat -c '%U' "$TOMCAT_DIR" 2>/dev/null || ls -ld "$TOMCAT_DIR" 2>/dev/null | awk '{print $3}')
      if [ -n "$TOMCAT_USER" ]; then
        echo "DEBUG: Detected directory owner: $TOMCAT_USER" >&2
      fi
    fi
  fi
  
  # Method 3: Check specific file ownership if directory owner failed
  if [ -z "$TOMCAT_USER" ]; then
    for file in "$TOMCAT_DIR/bin/catalina.sh" "$TOMCAT_DIR/bin/version.sh" "$TOMCAT_DIR/lib/catalina.jar"; do
      if [ -f "$file" ]; then
        TOMCAT_USER=$(stat -c '%U' "$file" 2>/dev/null || ls -l "$file" 2>/dev/null | awk '{print $3}')
        if [ -n "$TOMCAT_USER" ]; then
          echo "DEBUG: Detected file owner from $file: $TOMCAT_USER" >&2
          break
        fi
      fi
    done
  fi
  
  # Store original user and group for restoration
  ORIGINAL_USER="$CURRENT_USER"
  ORIGINAL_GROUP="$(id -gn 2>/dev/null || echo 'unknown')"
  
  # Function to safely switch user and run command
  run_as_user() {
    local target_user="$1"
    local command="$2"
    
    if [ "$target_user" = "$CURRENT_USER" ]; then
      # Already the correct user, run directly
      eval "$command"
    elif [ "$CURRENT_USER" = "root" ]; then
      # Running as root, can switch to any user
      su - "$target_user" -c "$command" 2>/dev/null
    elif command -v sudo >/dev/null 2>&1; then
      # Try sudo if available
      sudo -u "$target_user" bash -c "$command" 2>/dev/null
    else
      # Cannot switch user
      echo "DEBUG: Cannot switch to user $target_user, insufficient privileges" >&2
      return 1
    fi
  }
  
  # Try version detection as the detected user
  if [ -n "$TOMCAT_USER" ] && [ "$TOMCAT_USER" != "root" ] && [ "$TOMCAT_USER" != "$CURRENT_USER" ]; then
    echo "DEBUG: Attempting version detection as user: $TOMCAT_USER" >&2
    
    # Try to run version.sh as the Tomcat user
    if [ -f "$TOMCAT_DIR/bin/version.sh" ]; then
      VERSION=$(run_as_user "$TOMCAT_USER" "cd $TOMCAT_DIR/bin && ./version.sh 2>/dev/null | grep 'Server version' | head -1 | sed 's/Server version: //'")
      if [ -n "$VERSION" ]; then
        echo "$VERSION (user: $TOMCAT_USER)"
        exit 0
      fi
    fi
    
    # Try to run catalina.sh as the Tomcat user
    if [ -f "$TOMCAT_DIR/bin/catalina.sh" ]; then
      VERSION=$(run_as_user "$TOMCAT_USER" "cd $TOMCAT_DIR/bin && ./catalina.sh version 2>/dev/null | grep 'Server version' | head -1 | sed 's/Server version: //'")
      if [ -n "$VERSION" ]; then
        echo "$VERSION (user: $TOMCAT_USER)"
        exit 0
      fi
    fi
    
    # Try Java-based version detection as the Tomcat user
    if [ -f "$TOMCAT_DIR/lib/catalina.jar" ]; then
      # First try with Java
      JAVA_CMD=""
      if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        JAVA_CMD="$JAVA_HOME/bin/java"
      elif command -v java >/dev/null 2>&1; then
        JAVA_CMD="java"
      fi
      
      if [ -n "$JAVA_CMD" ]; then
        VERSION=$(run_as_user "$TOMCAT_USER" "cd $TOMCAT_DIR/lib && $JAVA_CMD -cp catalina.jar org.apache.catalina.util.ServerInfo 2>/dev/null | grep 'Server version' | head -1 | sed 's/Server version: //'")
        if [ -n "$VERSION" ]; then
          echo "$VERSION (user: $TOMCAT_USER, Java method)"
          exit 0
        fi
      fi
      
      # Try manifest extraction as the Tomcat user
      VERSION=$(run_as_user "$TOMCAT_USER" "cd $TOMCAT_DIR/lib && unzip -q -c catalina.jar META-INF/MANIFEST.MF 2>/dev/null | grep 'Implementation-Version' | cut -d: -f2 | tr -d ' ' | head -1")
      if [ -n "$VERSION" ]; then
        echo "Apache Tomcat/$VERSION (user: $TOMCAT_USER, manifest)"
        exit 0
      fi
    fi
  fi
  
  # Try with root permissions as a last resort
  if [ "$CURRENT_USER" != "root" ] && command -v sudo >/dev/null 2>&1; then
    echo "DEBUG: Attempting version detection with root permissions" >&2
    
    # Try version.sh with root
    if [ -f "$TOMCAT_DIR/bin/version.sh" ]; then
      VERSION=$(sudo bash -c "cd $TOMCAT_DIR/bin && ./version.sh 2>/dev/null | grep 'Server version' | head -1 | sed 's/Server version: //'")
      if [ -n "$VERSION" ]; then
        echo "$VERSION (root permissions)"
        exit 0
      fi
    fi
    
    # Try catalina.sh with root
    if [ -f "$TOMCAT_DIR/bin/catalina.sh" ]; then
      VERSION=$(sudo bash -c "cd $TOMCAT_DIR/bin && ./catalina.sh version 2>/dev/null | grep 'Server version' | head -1 | sed 's/Server version: //'")
      if [ -n "$VERSION" ]; then
        echo "$VERSION (root permissions)"
        exit 0
      fi
    fi
    
    # Try manifest extraction with root
    if [ -f "$TOMCAT_DIR/lib/catalina.jar" ]; then
      VERSION=$(sudo bash -c "cd $TOMCAT_DIR/lib && unzip -q -c catalina.jar META-INF/MANIFEST.MF 2>/dev/null | grep 'Implementation-Version' | cut -d: -f2 | tr -d ' ' | head -1")
      if [ -n "$VERSION" ]; then
        echo "Apache Tomcat/$VERSION (root permissions)"
        exit 0
      fi
    fi
  fi
  
  # Ensure we're back to the original user context
  if [ "$CURRENT_USER" != "$(whoami)" ]; then
    echo "DEBUG: Switching back to original user: $ORIGINAL_USER" >&2
    # This should not happen in a shell script context, but added for safety
    if [ "$ORIGINAL_USER" = "root" ]; then
      su - root 2>/dev/null || true
    else
      sudo -u "$ORIGINAL_USER" bash 2>/dev/null || true
    fi
  fi
fi

# Return original version if no elevated permissions worked
echo "$ORIGINAL_VERSION"

