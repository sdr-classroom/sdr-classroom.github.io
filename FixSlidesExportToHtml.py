import os
import sys
import re

# If no filename is given as first argument, exit
if len(sys.argv) < 2:
    print("No filename given as first argument")
    exit()

# Get file given as first argument to this script
filename = sys.argv[1]

fixedStamp = "<!-- Fixed after export -->"

# Text to be inserted before the last <script> tag:
toInsertLast = fixedStamp + '''
    <script src="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.3.1/plugin/notes/notes.js"></script>
    <script src="./script.js"></script>
    '''

toInsertHead = '''<script src="/print.js" defer></script>
'''

# Open the file with rw permissions
with open(filename, "r+") as f:
    # Read the file
    contents = f.read()

    # If the file contains fixed stamp
    if fixedStamp in contents:
        print(f"Already fixed {filename}")
        exit()

    # Find the closing </head> tag
    index = contents.find("</head>")

    # insert the script tag before the closing </head> tag
    if index != -1:
        contents = contents[:index] + toInsertHead + contents[index:]
    else:
        print("No </head> tag found")
        exit()
    
    # Find the last occurrence of 
    index = contents.rfind("<script>")

    # If no <script> tag was found, exit
    if index == -1:
        print("No <script> tag found")
        exit()
    
    # Insert empty script tag before the last script tag
    contents = contents[:index] + toInsertLast + contents[index:]

    # Where "plugins: [ RevealHighlight ]" is in the contents, insert ", RevealNotes" after "RevealHighlight"
    contents = re.sub(r"plugins: \[ *RevealHighlight *\]", r"plugins: [ RevealHighlight, RevealNotes ]", contents)

    # Remove ": Slides" at the end of the <title> tag, if it is there
    contents = re.sub(r"<title>(.*) *: Slides</title>", r"<title>\1</title>", contents)
    
    # Replace file contents with new contents
    f.seek(0)
    f.write(contents)
    f.truncate()

