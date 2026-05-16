import qrcode
from PIL import Image, ImageDraw, ImageFont

# ======================================
# SETTINGS
# ======================================

# Your APK / GitHub Release Link
url = "https://github.com/Kamalesh-Suresh-Kumar/VI-Mobile-Application-Development-Laboratory/releases/download/v2.0/app-release.apk"

# Logo path
logo_path = "assets\\icons\\schediq_foreground.png"

# Output
output_file = "SchedIQ_QR_InsideLogo.png"

# ======================================
# CREATE QR
# ======================================

qr = qrcode.QRCode(
    version=4,
    error_correction=qrcode.constants.ERROR_CORRECT_H,
    box_size=14,
    border=4,
)

qr.add_data(url)
qr.make(fit=True)

qr_img = qr.make_image(
    fill_color="black",
    back_color="white"
).convert("RGB")

qr_width, qr_height = qr_img.size

# ======================================
# ADD CENTER LOGO
# ======================================

logo = Image.open(logo_path).convert("RGBA")

# resize logo
logo_size = qr_width // 4
logo = logo.resize((logo_size, logo_size))

# create white background behind logo
logo_bg = Image.new(
    "RGBA",
    (logo_size + 30, logo_size + 30),
    "white"
)

# rounded corners
mask = Image.new("L", logo_bg.size, 0)
draw_mask = ImageDraw.Draw(mask)

draw_mask.rounded_rectangle(
    [(0, 0), logo_bg.size],
    radius=25,
    fill=255
)

logo_bg.putalpha(mask)

# paste logo in white box
logo_bg.paste(logo, (15, 15), logo)

# center position
pos_x = (qr_width - logo_bg.size[0]) // 2
pos_y = (qr_height - logo_bg.size[1]) // 2

qr_img.paste(logo_bg, (pos_x, pos_y), logo_bg)

# ======================================
# CREATE FINAL CARD
# ======================================

canvas_width = qr_width + 120
canvas_height = qr_height + 220

canvas = Image.new("RGB", (canvas_width, canvas_height), "white")

draw = ImageDraw.Draw(canvas)

# border
draw.rounded_rectangle(
    [(10, 10), (canvas_width - 10, canvas_height - 10)],
    radius=40,
    outline=(90, 70, 255),
    width=10
)

# paste QR
qr_x = (canvas_width - qr_width) // 2
qr_y = 40

canvas.paste(qr_img, (qr_x, qr_y))

# ======================================
# BRANDING TEXT
# ======================================

try:
    font = ImageFont.truetype("arial.ttf", 65)
except:
    font = ImageFont.load_default()

text = "SchedIQ"

bbox = draw.textbbox((0, 0), text, font=font)

text_width = bbox[2] - bbox[0]

text_x = (canvas_width - text_width) // 2
text_y = qr_height + 80

draw.text(
    (text_x, text_y),
    text,
    fill=(30, 20, 90),
    font=font
)

# ======================================
# SAVE
# ======================================

canvas.save(output_file)

print("Done!")
print("Saved as:", output_file)