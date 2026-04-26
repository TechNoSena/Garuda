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
VERTEX_PROJECT_ID = os.getenv("VERTEX_PROJECT_ID", PROJECT_ID)

# Set GCP credentials for Vertex AI (if a separate key file is provided)
gcp_creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
if not gcp_creds_path:
    # Fallback: try to use the same Firebase key (works if both projects share the same key)
    firebase_key = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    if not os.path.exists(firebase_key):
        firebase_key = os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json")
    if os.path.exists(firebase_key):
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.abspath(firebase_key)

# Initialize Vertex AI (uses separate GCP project if configured)
try:
    vertexai.init(project=VERTEX_PROJECT_ID, location=LOCATION)
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
    # Look for serviceAccountKey.json in the CWD or app root
    key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    # Fallback to absolute path relative to this file
    if not os.path.exists(key_path):
        key_path = os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json")

    if os.path.exists(key_path):
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase Admin SDK initialized successfully.")
    else:
        print(f"Warning: Firebase {key_path} not found. Running in mock/offline DB mode.")
except Exception as e:
    print(f"Warning: Firebase initialization failed. {e}")
