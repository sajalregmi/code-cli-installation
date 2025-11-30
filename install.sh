#!/usr/bin/env bash

set -e

EXE_NAME="arkios-code"

OS_TYPE=$(uname)
echo "Detected OS: $OS_TYPE"

if [[ "$OS_TYPE" == "Darwin" || "$OS_TYPE" == "Linux" ]]; then
    INSTALL_DIR="${HOME}/.arkios/code/bin"
else
    echo "Unknown OS: $OS_TYPE"
    exit 1
fi

if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS detected. Note: You may need to run 'xattr -d com.apple.quarantine /usr/local/bin/${EXE_NAME%.exe}' after installation.
    DOWNLOAD_URL="https://storage.googleapis.com/executable-arkios/Arkios-Code-Mac/cli-app-macos"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Add your Linux download URL here
    DOWNLOAD_URL="https://storage.googleapis.com/executable-arkios/Arkios-Code-Linux/arkios-code-linux"
else
    echo "Unsupported OS: $OS_TYPE"
    exit 1
fi

INSTALL_PATH="$INSTALL_DIR/${EXE_NAME}"

# Create installation directory if it doesn't exist
echo "Ensuring installation directory exists..."
mkdir -p "$INSTALL_DIR"

echo "Downloading $EXE_NAME..."
curl -L -o /tmp/$EXE_NAME "$DOWNLOAD_URL"

echo "Installing to $INSTALL_PATH..."
cp -f /tmp/$EXE_NAME "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
rm -f /tmp/$EXE_NAME

echo ""
echo "Installation complete!"
echo "Arkios Code installed to $INSTALL_PATH"
echo ""

# PATH configuration
echo "Configuring PATH..."

# Function to safely add PATH to shell config
add_to_path() {
    local config_file="$1"
    local path_export="export PATH=\"\$HOME/.arkios/code/bin:\$PATH\""

    # Expand tilde to actual home directory
    config_file="${config_file/#\~/$HOME}"

    # Create config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file" || {
            echo "Warning: Cannot create $config_file"
            return 1
        }
    fi

    # Check if PATH is already configured in this file
    if grep -q ".arkios/code/bin" "$config_file" 2>/dev/null; then
        echo "  ✓ Already configured in $config_file"
        return 0
    fi

    # Add PATH export to config file
    {
        echo ""
        echo "# Added by Arkios Code installer"
        echo "$path_export"
    } >> "$config_file" || {
        echo "Warning: Cannot write to $config_file"
        return 1
    }

    echo "  ✓ Added to $config_file"
    return 0
}

# Check if already in current PATH
if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "PATH already configured in current session"
else
    # Detect user's shell and update appropriate config file(s)
    case "${SHELL##*/}" in
        zsh)
            add_to_path "$HOME/.zshrc"
            ;;
        bash)
            # For bash, update both .bashrc and .bash_profile if they exist
            add_to_path "$HOME/.bashrc"
            if [[ -f "$HOME/.bash_profile" ]]; then
                add_to_path "$HOME/.bash_profile"
            fi
            ;;
        *)
            # Fallback for other shells
            add_to_path "$HOME/.profile"
            ;;
    esac

    echo ""
    echo "PATH configured successfully!"
    echo ""
    echo "To use arkios-code in this terminal session, run:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "Or open a new terminal and run: arkios-code"
fi
