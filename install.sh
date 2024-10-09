#!/bin/bash
# installation script
PROJECT_NAME="DockLock"
SCRIPT_NAME="wrap.sh"
INSTALL_DIR="$HOME/bin"
CONFIG_FILE="protect.json"
CONFIG_DIR="$HOME/.docker-protect"
echo "
    ___           _      __            _            
   /   \___   ___| | __ / /  ___   ___| | __    _   
  / /\ / _ \ / __| |/ // /  / _ \ / __| |/ /  _| |_ 
 / /_// (_) | (__|   </ /__| (_) | (__|   <  |_   _|
/___,' \___/ \___|_|\_\____/\___/ \___|_|\_\   |_|  
                                                

"

# Create the install directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating install directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Copy the main script to the install directory
echo "Installing $PROJECT_NAME to $INSTALL_DIR..."
cp "$SCRIPT_NAME" "$INSTALL_DIR/docker-lock"
chmod +x "$INSTALL_DIR/docker-lock"

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "Created configuration directory at $CONFIG_DIR"
fi

# Copy the default configuration file
if [ ! -f "$CONFIG_DIR/$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_DIR/$CONFIG_FILE"
    echo "Copied default configuration file to $CONFIG_DIR/$CONFIG_FILE"
else
    echo "Configuration file already exists at $CONFIG_DIR/$CONFIG_FILE"
fi

# Add uninstall option to remove the installed files
UNINSTALL_SCRIPT="$INSTALL_DIR/uninstall.sh"
echo -e "#!/bin/bash\n" > "$UNINSTALL_SCRIPT"

# Remove the installed files
echo "rm -f \"$INSTALL_DIR/docker-lock\"" >> "$UNINSTALL_SCRIPT"
echo "rm -rf \"$CONFIG_DIR\"" >> "$UNINSTALL_SCRIPT"

# Remove Docker alias from .bashrc or .zshrc
if [[ -f "$HOME/.bashrc" ]]; then
    echo "sed -i '' '/alias docker=.*$/d' \"$HOME/.bashrc\"" >> "$UNINSTALL_SCRIPT"
    echo "echo 'Uninstalled! Pls open new tab/restart the shell to reflect changes.'" >> "$UNINSTALL_SCRIPT"
    #echo $HOME/.bashrc
elif [[ -f "$HOME/.zshrc" ]]; then
    echo "sed -i '' '/alias docker=.*$/d' \"$HOME/.zshrc\"" >> "$UNINSTALL_SCRIPT"
    echo "echo 'Uninstalled! Pls open new tab/restart the shell to reflect changes.'" >> "$UNINSTALL_SCRIPT"
   # echo $HOME/.zshrc
else
    echo "echo 'No .bashrc or .zshrc file found. Please remove the alias manually.'" >> "$UNINSTALL_SCRIPT"
fi


# Make the uninstall script executable
chmod +x "$UNINSTALL_SCRIPT"
echo "To uninstall, run: $UNINSTALL_SCRIPT"

# Add Docker alias to .bashrc or .zshrc
if [[ -f "$HOME/.bashrc" ]]; then
    echo "alias docker='$INSTALL_DIR/docker-lock'" >> "$HOME/.bashrc"
    echo "Added Docker alias to .bashrc"
    
elif [[ -f "$HOME/.zshrc" ]]; then
    echo "alias docker='$INSTALL_DIR/docker-lock'" >> "$HOME/.zshrc"
    echo "Added Docker alias to .zshrc"
    
else
    echo "No .bashrc or .zshrc file found. Please add the alias manually."
fi

# Prompt the user to reload their shell or run source
echo "Please restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc' to apply the changes."

echo "$PROJECT_NAME has been installed successfully!"

exit 0
