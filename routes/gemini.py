import os
from google import genai
from google.genai import types
from PIL import Image
import base64
import io

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

def pil_to_base64(img):
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    return base64.b64encode(buf.getvalue()).decode()

def analyze_image(image_path):
    try:
        img = Image.open(image_path).convert('RGB')
        img_b64 = pil_to_base64(img)

        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=[
                types.Part.from_bytes(
                    data=base64.b64decode(img_b64),
                    mime_type='image/jpeg'
                ),
                """You are a sports media forensics expert.
Analyze this image and provide:
1. What sport or sports organization this relates to
2. Whether this looks like an official/professional media asset
3. Any visible logos, watermarks, or copyright indicators
4. Risk: is this image likely to be misused or pirated?
5. Verdict: PROTECTED ASSET or GENERIC CONTENT
Be concise. Max 6 lines."""
            ]
        )
        return response.text
    except Exception as e:
        return f"Analysis unavailable: {str(e)}"

def compare_images_ai(image_path1, image_path2):
    try:
        img1 = Image.open(image_path1).convert('RGB')
        img2 = Image.open(image_path2).convert('RGB')
        img1_b64 = pil_to_base64(img1)
        img2_b64 = pil_to_base64(img2)

        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=[
                types.Part.from_bytes(
                    data=base64.b64decode(img1_b64),
                    mime_type='image/jpeg'
                ),
                types.Part.from_bytes(
                    data=base64.b64decode(img2_b64),
                    mime_type='image/jpeg'
                ),
                """You are a sports media forensics expert comparing two images.
Analyze both and tell me:
1. Are these the same image or derived from the same source?
2. What differences do you notice?
3. Is the second image an unauthorized copy of the first?

Give verdict in this exact format:
VERDICT: [INFRINGEMENT / LIKELY INFRINGEMENT / NO INFRINGEMENT]
CONFIDENCE: [HIGH / MEDIUM / LOW]
REASON: [one line]"""
            ]
        )
        return response.text
    except Exception as e:
        return f"AI comparison unavailable: {str(e)}"