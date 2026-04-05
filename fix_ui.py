import os
import re

import glob

def scale_font_sizes(content):
    # Mapping of old size to new size (incrementing to improve readability)
    def replacer(match):
        size = int(match.group(1))
        # Scale logic
        if size == 9: new_size = 11
        elif size == 10: new_size = 12
        elif size == 11: new_size = 13
        elif size == 12: new_size = 14
        elif size == 13: new_size = 15
        elif size == 14: new_size = 16
        elif size == 15: new_size = 17
        elif size == 16: new_size = 18
        elif size == 17: new_size = 20
        elif size == 18: new_size = 22
        elif size == 20: new_size = 24
        elif size == 22: new_size = 26
        elif size == 24: new_size = 28
        else: new_size = size + 2
        return f"fontSize: {new_size}"

    # Replace fontSize: XX
    new_content = re.sub(r'fontSize:\s*(\d+)', replacer, content)
    return new_content

def fix_hardcoded_sizes(content):
    # specific size fixes for main.dart and other files
    # main.dart: SizedBox(height: 175) -> SizedBox(height: 220)
    content = re.sub(r'height:\s*175\s*,', r'height: 220,', content)
    # main.dart: width: 148 -> width: 180
    content = re.sub(r'width:\s*148\s*,', r'width: 180,', content)
    # main.dart height: 90 -> height: 110 (image part of card)
    content = re.sub(r'height:\s*90\s*,', r'height: 110,', content)
    
    # general fixes for small containers with icons
    content = re.sub(r'width:\s*60\s*,\s*height:\s*60', r'width: 70, height: 70', content)
    content = re.sub(r'width:\s*44\s*,\s*height:\s*44', r'width: 52, height: 52', content)
    content = re.sub(r'width:\s*32\s*,\s*height:\s*32', r'width: 40, height: 40', content)
    content = re.sub(r'width:\s*42\s*,\s*height:\s*42', r'width: 50, height: 50', content)
    
    return content

def main():
    base_dir = r"c:\dev\pet_pal_app\lib"
    dart_files = glob.glob(os.path.join(base_dir, "**", "*.dart"), recursive=True)
    
    for file_path in dart_files:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        new_content = scale_font_sizes(content)
        new_content = fix_hardcoded_sizes(new_content)
        
        if content != new_content:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated {file_path}")

if __name__ == "__main__":
    main()
