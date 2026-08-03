import os
import glob
import re

lib_dir = r"f:\TA\aquafeed\lib"
files = glob.glob(os.path.join(lib_dir, "**/*.dart"), recursive=True)

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'theme.dart' in file or 'theme_provider.dart' in file:
        continue

    # Regex to find AppTheme.something
    # Replace AppTheme.accent -> AppTheme.colors.accent
    new_content = re.sub(r'AppTheme\.(?!colors|darkTheme|lightTheme)([a-zA-Z0-9_]+)', r'AppTheme.colors.\1', content)
    
    if new_content != content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
