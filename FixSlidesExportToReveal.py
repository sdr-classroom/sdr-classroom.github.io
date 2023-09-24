

# For all files in this folder and subfolders, if contains "reveal" in the contents, replace any occurrence of "data-name" with "data-id"

import os
import re

# Get all files in this folder and subfolders
for root, dirs, files in os.walk("."):
    for filename in files:
        # For each file
        # if file is html open the file with rw permissions
        if filename.endswith(".html"):
            with open(os.path.join(root, filename), "r+") as f:
                # Read the file
                contents = f.read()
                # If the file contains "reveal"
                if "<div class=\"reveal\">" in contents:
                    # Replace all occurrences of "data-name" with "data-id" and count occurrences
                    contents, count1 = re.subn("data-name", "data-id", contents)
                    contents, count2 = re.subn("data-auto-animate=\"\"", "data-auto-animate", contents)
                    print(f"Found reveal in {os.path.join(root, filename)}, replaced {count1} data-names, {count2} auto-animates.");
                    # Replace file contents with new contents
                    f.seek(0)
                    f.write(contents)
                    f.truncate()
