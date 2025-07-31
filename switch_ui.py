#!/usr/bin/env python3
"""
UI Switcher for WhisperLiveKit
Switch between original and modern UI versions
"""

import os
import shutil
import sys

def switch_ui(version):
    """Switch between UI versions"""
    web_dir = "whisperlivekit/web"
    
    if version == "modern":
        # Switch to modern UI
        if os.path.exists(f"{web_dir}/live_transcription_modern.html"):
            shutil.copy(f"{web_dir}/live_transcription_modern.html", f"{web_dir}/live_transcription.html")
            print("✅ Switched to Modern UI")
        else:
            print("❌ Modern UI file not found")
            return False
    elif version == "original":
        # Switch to original UI
        if os.path.exists(f"{web_dir}/live_transcription_original.html"):
            shutil.copy(f"{web_dir}/live_transcription_original.html", f"{web_dir}/live_transcription.html")
            print("✅ Switched to Original UI")
        else:
            print("❌ Original UI file not found")
            return False
    else:
        print("❌ Invalid version. Use 'modern' or 'original'")
        return False
    
    return True

def backup_original():
    """Backup the original UI file"""
    web_dir = "whisperlivekit/web"
    original_file = f"{web_dir}/live_transcription.html"
    backup_file = f"{web_dir}/live_transcription_original.html"
    
    if os.path.exists(original_file) and not os.path.exists(backup_file):
        shutil.copy(original_file, backup_file)
        print("📦 Original UI backed up")

def main():
    if len(sys.argv) != 2:
        print("Usage: python switch_ui.py [modern|original]")
        print("\nExamples:")
        print("  python switch_ui.py modern   # Switch to modern UI")
        print("  python switch_ui.py original # Switch to original UI")
        return
    
    version = sys.argv[1].lower()
    
    # Backup original if not already done
    backup_original()
    
    # Switch UI
    if switch_ui(version):
        print(f"\n🎨 UI switched to {version} version")
        print("🔄 Restart your WhisperLiveKit server to see the changes")
    else:
        print("\n❌ Failed to switch UI")

if __name__ == "__main__":
    main() 