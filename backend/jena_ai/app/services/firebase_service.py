import os

import firebase_admin
from firebase_admin import credentials, firestore

from app.config import is_local_dev_mode


class FirebaseService:
    def __init__(self) -> None:
        if not firebase_admin._apps:
            project_id = os.getenv("GOOGLE_CLOUD_PROJECT", "demo-src-local")
            if is_local_dev_mode() or os.getenv("FIRESTORE_EMULATOR_HOST"):
                firebase_admin.initialize_app(options={"projectId": project_id})
            else:
                firebase_admin.initialize_app(credentials.ApplicationDefault())
        self.db = firestore.client()
