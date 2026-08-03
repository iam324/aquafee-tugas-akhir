import os
import glob
import re

lib_dir = r"f:\TA\aquafeed\lib"
files = glob.glob(os.path.join(lib_dir, "**/*.dart"), recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove const before Icon that has AppTheme
    new_content = re.sub(r'const\s+(Icon\([^;{}]*AppTheme\.colors[^;{}]*\))', r'\1', content)
    # Remove const before UnderlineInputBorder
    new_content = re.sub(r'const\s+(UnderlineInputBorder\([^;{}]*AppTheme\.colors[^;{}]*\))', r'\1', new_content)
    
    if new_content != content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
