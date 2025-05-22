import os
import re
import shutil

# --- CONFIGURATION ---
obsidian_dir = r"C:\Users\Tom Coffey\Desktop\Technical\Obsidian Notes\Mediengestaltung Notes\Posts for website"
hugo_posts_dir = r"C:\Users\Tom Coffey\Documents\website\content\posts"
hugo_images_dir = r"C:\Users\Tom Coffey\Documents\website\content\posts"

# --- ENSURE DIRECTORIES EXIST ---
os.makedirs(hugo_images_dir, exist_ok=True)

# --- FILE EXTENSIONS TO SYNC ---
image_extensions = (".jpg", ".jpeg", ".png", ".gif", ".webp")

# --- COPY IMAGES FROM OBSIDIAN TO HUGO STATIC IMAGES FOLDER ---
copied = 0
skipped = 0

for filename in os.listdir(obsidian_dir):
    if filename.lower().endswith(image_extensions):
        source_path = os.path.join(obsidian_dir, filename)
        target_path = os.path.join(hugo_images_dir, filename)

        if not os.path.exists(target_path):
            shutil.copy2(source_path, target_path)
            print(f"Copied: {filename}")
            copied += 1
        else:
            skipped += 1

print(f"Image sync complete. {copied} copied, {skipped} skipped.")

# --- UPDATE MARKDOWN FILES TO USE CORRECT MARKDOWN IMAGE SYNTAX ---
for filename in os.listdir(hugo_posts_dir):
    if filename.endswith(".md"):
        filepath = os.path.join(hugo_posts_dir, filename)

        with open(filepath, "r", encoding="utf-8") as file:
            content = file.read()

        # Find Obsidian-style image links: ![[image.jpg]]
        images = re.findall(r'!\[\[([^\]]+\.(?:png|jpe?g|gif|webp))\]\]', content, re.IGNORECASE)

        if images:
            print(f"Found in {filename}: {images}")

        # Replace them with Hugo-compatible Markdown image links
        for image in images:
            markdown_image = f"![{image}](/images/{image.replace(' ', '%20')})"
            content = content.replace(f"![[{image}]]", markdown_image)

        # Save updated file
        with open(filepath, "w", encoding="utf-8") as file:
            file.write(content)

print("Markdown image links updated.")