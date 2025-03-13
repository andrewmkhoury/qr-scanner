#!/bin/bash
# QR Screen Scanner - Fix Permissions Script
# This script removes the quarantine attribute that causes the "damaged" warning

# Text styling
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RESET="\033[0m"

echo "${BOLD}QR Screen Scanner - Fix Permissions Utility${RESET}"
echo "This script will attempt to remove the macOS quarantine attribute"
echo "that causes the app to show as 'damaged'."
echo ""

# First check if the DMG is mounted
if [ -d "/Volumes/QR Screen Scanner" ]; then
    echo "${BLUE}Found mounted DMG at /Volumes/QR Screen Scanner${RESET}"
    
    if [ -d "/Volumes/QR Screen Scanner/QR Scanner.app" ]; then
        echo "Removing quarantine attribute from app in DMG..."
        xattr -d com.apple.quarantine "/Volumes/QR Screen Scanner/QR Scanner.app" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "${GREEN}Successfully removed quarantine attribute from app in DMG!${RESET}"
            echo "You can now drag the app to your Applications folder."
        else
            echo "${RED}Failed to remove quarantine attribute.${RESET}"
            echo "This might be due to permissions. Trying with sudo..."
            sudo xattr -d com.apple.quarantine "/Volumes/QR Screen Scanner/QR Scanner.app" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "${GREEN}Successfully removed quarantine attribute with sudo!${RESET}"
                echo "You can now drag the app to your Applications folder."
            else
                echo "${RED}Failed to remove quarantine attribute even with sudo.${RESET}"
                echo "You may need to try the manual steps in the install_instructions.md file."
            fi
        fi
    else
        echo "${RED}Could not find the app in the mounted DMG.${RESET}"
        echo "Please make sure the DMG is mounted correctly."
    fi
fi

# Also check if the app is in the Applications folder
if [ -d "/Applications/QR Scanner.app" ]; then
    echo "${BLUE}Found app in Applications folder${RESET}"
    echo "Removing quarantine attribute from installed app..."
    xattr -d com.apple.quarantine "/Applications/QR Scanner.app" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}Successfully removed quarantine attribute from installed app!${RESET}"
        echo "You should now be able to open the app normally."
    else
        echo "${RED}Failed to remove quarantine attribute.${RESET}"
        echo "This might be due to permissions. Trying with sudo..."
        sudo xattr -d com.apple.quarantine "/Applications/QR Scanner.app" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "${GREEN}Successfully removed quarantine attribute with sudo!${RESET}"
            echo "You should now be able to open the app normally."
        else
            echo "${RED}Failed to remove quarantine attribute even with sudo.${RESET}"
            echo "You may need to try the manual steps in the install_instructions.md file."
        fi
    fi
fi

# Check if the app is in the current directory or parent directories
for APP_PATH in \
    "./QR Scanner.app" \
    "../QR Scanner.app" \
    "QR Scanner.app"; do
    if [ -d "$APP_PATH" ]; then
        echo "${BLUE}Found app at ${APP_PATH}${RESET}"
        echo "Removing quarantine attribute..."
        xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "${GREEN}Successfully removed quarantine attribute!${RESET}"
            echo "You should now be able to open the app normally."
        else
            echo "${RED}Failed to remove quarantine attribute.${RESET}"
            echo "This might be due to permissions. Trying with sudo..."
            sudo xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "${GREEN}Successfully removed quarantine attribute with sudo!${RESET}"
                echo "You should now be able to open the app normally."
            else
                echo "${RED}Failed to remove quarantine attribute even with sudo.${RESET}"
                echo "You may need to try the manual steps in the install_instructions.md file."
            fi
        fi
    fi
done

echo ""
echo "${BOLD}Script complete.${RESET}"
echo "If you still have issues, please refer to the install_instructions.md file"
echo "or visit the GitHub repository for more help."
echo ""
echo "Press any key to exit..."
read -n 1 -s

exit 0 