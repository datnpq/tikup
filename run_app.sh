#!/bin/bash

# Check if Flutter is in the common locations
FLUTTER_PATHS=(
  "$HOME/flutter/bin/flutter"
  "$HOME/development/flutter/bin/flutter"
  "$HOME/Documents/flutter/bin/flutter"
  "$HOME/Downloads/flutter/bin/flutter"
  "/usr/local/flutter/bin/flutter"
)

FLUTTER_CMD=""

for path in "${FLUTTER_PATHS[@]}"; do
  if [ -f "$path" ]; then
    FLUTTER_CMD="$path"
    break
  fi
done

if [ -z "$FLUTTER_CMD" ]; then
  echo "Flutter SDK not found in common locations."
  echo "Please enter the full path to your Flutter SDK bin directory:"
  read -p "> " FLUTTER_DIR
  FLUTTER_CMD="$FLUTTER_DIR/flutter"
  
  if [ ! -f "$FLUTTER_CMD" ]; then
    echo "Flutter command not found at $FLUTTER_CMD"
    exit 1
  fi
fi

echo "Using Flutter at: $FLUTTER_CMD"
echo "Running app..."

# Run the app
"$FLUTTER_CMD" run

# If you want to specify a device, uncomment the line below
# "$FLUTTER_CMD" run -d <device-id> 