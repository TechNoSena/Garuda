import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore, auth
import vertexai
from vertexai.generative_models import GenerativeModel, Tool, grounding

load_dotenv()

PROJECT_ID = os.getenv("PROJECT_ID")
GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_KEY")
LOCATION = os.getenv("LOCATION", "asia-south1")

# Initialize Vertex AI
try:
    vertexai.init(project=PROJECT_ID, location=LOCATION)
    model = GenerativeModel("gemini-2.5-flash")
    # Using the required 'google_search' field to avoid 400 errors
    search_tool = Tool.from_dict({"google_search": {}})
except Exception as e:
    print(f"Warning: Vertex AI not fully configured. {e}")
    model = None
    search_tool = None

# Initialize Firebase Admin
db = None
try:
    # Look for serviceAccountKey.json in the current directory or parent
    key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    if os.path.exists(key_path):
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase Admin SDK initialized successfully.")
    else:
        print(f"Warning: Firebase {key_path} not found. Running in mock/offline DB mode.")
except Exception as e:
    print(f"Warning: Firebase initialization failed. {e}")
