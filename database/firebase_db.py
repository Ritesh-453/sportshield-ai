import firebase_admin
from firebase_admin import credentials, firestore
import os
from datetime import datetime

def init_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(os.getenv('FIREBASE_KEY'))
        firebase_admin.initialize_app(cred)
    return firestore.client()

def save_asset_firebase(name, filename, phash, dhash, ahash):
    try:
        db = init_firebase()
        doc_ref = db.collection('assets').document()
        doc_ref.set({
            'name': name,
            'filename': filename,
            'phash': phash,
            'dhash': dhash,
            'ahash': ahash,
            'uploaded_at': datetime.now().isoformat()
        })
        return doc_ref.id
    except Exception as e:
        print(f"Firebase save asset error: {e}")
        return None

def save_violation_firebase(asset_id, asset_name, similarity, filename):
    try:
        db = init_firebase()
        doc_ref = db.collection('violations').document()
        doc_ref.set({
            'asset_id': asset_id,
            'asset_name': asset_name,
            'similarity': similarity,
            'filename': filename,
            'detected_at': datetime.now().isoformat(),
            'risk_level': get_risk(similarity)
        })
        return doc_ref.id
    except Exception as e:
        print(f"Firebase save violation error: {e}")
        return None

def get_assets_firebase():
    try:
        db = init_firebase()
        docs = db.collection('assets').order_by(
            'uploaded_at',
            direction=firestore.Query.DESCENDING
        ).stream()
        return [{'id': d.id, **d.to_dict()} for d in docs]
    except Exception as e:
        print(f"Firebase get assets error: {e}")
        return []

def get_violations_firebase():
    try:
        db = init_firebase()
        docs = db.collection('violations').order_by(
            'detected_at',
            direction=firestore.Query.DESCENDING
        ).stream()
        return [{'id': d.id, **d.to_dict()} for d in docs]
    except Exception as e:
        print(f"Firebase get violations error: {e}")
        return []

def get_risk(similarity):
    if similarity >= 90:
        return 'CRITICAL'
    elif similarity >= 70:
        return 'HIGH'
    elif similarity >= 50:
        return 'MEDIUM'
    else:
        return 'LOW'