#!/usr/bin/env python3
"""
Generate app icons for HobbyistSwiftUI iOS app
Creates a modern, gradient-based icon with an "H" lettermark
"""

from PIL import Image, ImageDraw, ImageFont
import os
import json

def create_base_icon(size=1024):
    """Create the base 1024x1024 icon design"""
    # Create image with gradient background
    img = Image.new('RGB', (size, size), '#FFFFFF')
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (purple to blue)
    for y in range(size):
        # Gradient from top (#8B5CF6) to bottom (#3B82F6)
        ratio = y / size
        r = int(139 * (1 - ratio) + 59 * ratio)
        g = int(92 * (1 - ratio) + 130 * ratio)
        b = int(246 * (1 - ratio) + 246 * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b))
    
    # Draw rounded square background
    padding = int(size * 0.1)
    corner_radius = int(size * 0.15)
    
    # Create mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [(padding, padding), (size - padding, size - padding)],
        radius=corner_radius,
        fill=255
    )
    
    # Create white rounded square
    white_bg = Image.new('RGB', (size, size), '#FFFFFF')
    white_draw = ImageDraw.Draw(white_bg)
    white_draw.rounded_rectangle(
        [(padding, padding), (size - padding, size - padding)],
        radius=corner_radius,
        fill='#FFFFFF'
    )
    
    # Composite with transparency
    img = Image.composite(white_bg, img, mask)
    draw = ImageDraw.Draw(img)
    
    # Draw the "H" lettermark
    # Calculate font size (approximately 40% of icon size)
    font_size = int(size * 0.4)
    
    # Try to use system font, fall back to default if not available
    try:
        # Try SF Pro Display or Helvetica
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Use default font with smaller size
        font = ImageFont.load_default()
        font_size = int(size * 0.3)
    
    # Draw "H" in gradient colors
    text = "H"
    
    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - int(size * 0.05)  # Slight upward adjustment
    
    # Draw text with gradient effect (simplified - using solid color)
    draw.text((x, y), text, fill='#8B5CF6', font=font)
    
    # Add subtle inner shadow/depth to the letter
    draw.text((x + 2, y + 2), text, fill='#7C3AED', font=font)
    
    # Add a subtle circular element around the H
    circle_padding = int(size * 0.25)
    draw.ellipse(
        [(circle_padding, circle_padding), 
         (size - circle_padding, size - circle_padding)],
        outline='#E9D5FF',
        width=int(size * 0.01)
    )
    
    return img

def generate_icon_sizes():
    """Generate all required iOS icon sizes"""
    # iOS App Icon sizes (in points, will be saved at 1x, 2x, 3x)
    icon_sizes = [
        # iPhone Notification
        (20, 2, "iphone", "20x20@2x"),  # 40x40
        (20, 3, "iphone", "20x20@3x"),  # 60x60
        
        # iPhone Settings
        (29, 2, "iphone", "29x29@2x"),  # 58x58
        (29, 3, "iphone", "29x29@3x"),  # 87x87
        
        # iPhone Spotlight
        (40, 2, "iphone", "40x40@2x"),  # 80x80
        (40, 3, "iphone", "40x40@3x"),  # 120x120
        
        # iPhone App
        (60, 2, "iphone", "60x60@2x"),  # 120x120
        (60, 3, "iphone", "60x60@3x"),  # 180x180
        
        # iPad Notifications
        (20, 1, "ipad", "20x20"),       # 20x20
        (20, 2, "ipad", "20x20@2x"),    # 40x40
        
        # iPad Settings
        (29, 1, "ipad", "29x29"),       # 29x29
        (29, 2, "ipad", "29x29@2x"),    # 58x58
        
        # iPad Spotlight
        (40, 1, "ipad", "40x40"),       # 40x40
        (40, 2, "ipad", "40x40@2x"),    # 80x80
        
        # iPad App
        (76, 1, "ipad", "76x76"),       # 76x76
        (76, 2, "ipad", "76x76@2x"),    # 152x152
        
        # iPad Pro App
        (83.5, 2, "ipad", "83.5x83.5@2x"),  # 167x167
        
        # App Store
        (1024, 1, "ios-marketing", "1024x1024"),  # 1024x1024
    ]
    
    return icon_sizes

def create_contents_json(icon_sizes):
    """Create the Contents.json file for the AppIcon.appiconset"""
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    for base_size, scale, idiom, filename in icon_sizes:
        actual_size = int(base_size * scale)
        image_entry = {
            "filename": f"icon_{actual_size}x{actual_size}.png",
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": f"{int(base_size)}x{int(base_size)}"
        }
        contents["images"].append(image_entry)
    
    return contents

def main():
    # Create base icon
    print("Creating base icon design...")
    base_icon = create_base_icon(1024)
    
    # Define output directory
    output_dir = "/Users/chromefang.exe/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Assets.xcassets/AppIcon.appiconset"
    
    # Ensure directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Get all required sizes
    icon_sizes = generate_icon_sizes()
    
    print(f"Generating {len(icon_sizes)} icon sizes...")
    
    # Generate each icon size
    for base_size, scale, idiom, size_name in icon_sizes:
        actual_size = int(base_size * scale)
        
        # Resize the base icon
        resized = base_icon.resize((actual_size, actual_size), Image.Resampling.LANCZOS)
        
        # Save with appropriate filename
        filename = f"icon_{actual_size}x{actual_size}.png"
        filepath = os.path.join(output_dir, filename)
        resized.save(filepath, "PNG", optimize=True)
        print(f"  ✓ Created {filename} ({idiom})")
    
    # Create Contents.json
    contents_json = create_contents_json(icon_sizes)
    contents_path = os.path.join(output_dir, "Contents.json")
    
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    
    print(f"\n✅ Successfully generated {len(icon_sizes)} app icons!")
    print(f"📁 Icons saved to: {output_dir}")
    print("\n📱 Next steps:")
    print("1. Open your project in Xcode")
    print("2. The icons should automatically appear in Assets.xcassets")
    print("3. Build and run to test the icon")
    print("\nNote: You can customize the icon design by modifying this script")
    
    # Also save the base 1024x1024 for reference
    base_path = "/Users/chromefang.exe/HobbyistSwiftUI/iOS/AppIcon_1024.png"
    base_icon.save(base_path, "PNG", optimize=True)
    print(f"\n🎨 Base 1024x1024 icon saved to: {base_path}")

if __name__ == "__main__":
    main()