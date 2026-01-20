import os
import json
from google import genai
from google.genai import types

# Load keys
with open("E:\\Munajat App\\munajat_e_maqbool_app\\Hadith Translator Scripts\\api_keys.txt", "r") as f:
    keys = [line.strip() for line in f if line.strip()]

if not keys:
    print("No keys found!")
    exit()

api_key = keys[0] # Try the first key
print(f"Testing key: ...{api_key[-4:]}")

prompt = "Translate 'Hello world' to Burmese."

try:
    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model="gemini-1.5-flash",
        contents=prompt
    )
    print("Success!")
    print(response.text)
except Exception as e:
    print(f"Failed: {e}")
