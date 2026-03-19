from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from database.db import get_db
from database.firebase_db import save_asset_firebase
from PIL import Image
import imagehash
import os
import uuid

assets_bp = Blueprint('assets', __name__)

def get_all_hashes(path):
    try:
        img = Image.open(path)
        return {
            'phash': str(imagehash.phash(img)),
            'dhash': str(imagehash.dhash(img)),
            'ahash': str(imagehash.average_hash(img))
        }
    except:
        return None

@assets_bp.route('/assets')
def list_assets():
    db = get_db(current_app.config['DATABASE'])
    assets = db.execute(
        'SELECT * FROM assets ORDER BY uploaded_at DESC'
    ).fetchall()
    db.close()
    return render_template('assets.html', assets=assets)

@assets_bp.route('/assets/upload', methods=['POST'])
def upload_asset():
    if 'image' not in request.files:
        flash('No file selected')
        return redirect(url_for('index'))

    file = request.files['image']
    name = request.form.get('name', file.filename)

    if file.filename == '':
        flash('No file selected')
        return redirect(url_for('index'))

    filename = f"{uuid.uuid4().hex}_{file.filename}"
    filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    hashes = get_all_hashes(filepath)
    if not hashes:
        flash('Could not process image')
        return redirect(url_for('index'))

    # Save to SQLite
    db = get_db(current_app.config['DATABASE'])
    db.execute(
        'INSERT INTO assets (name, filename, phash, dhash, ahash) VALUES (?, ?, ?, ?, ?)',
        (name, filename, hashes['phash'], hashes['dhash'], hashes['ahash'])
    )
    db.commit()
    db.close()

    # Save to Firebase (dual write)
    save_asset_firebase(name, filename, hashes['phash'], hashes['dhash'], hashes['ahash'])

    flash(f'Asset "{name}" registered successfully!')
    return redirect(url_for('assets.list_assets'))

@assets_bp.route('/assets/delete/<int:asset_id>', methods=['POST'])
def delete_asset(asset_id):
    db = get_db(current_app.config['DATABASE'])
    db.execute('DELETE FROM assets WHERE id = ?', (asset_id,))
    db.commit()
    db.close()
    flash('Asset deleted successfully.')
    return redirect(url_for('assets.list_assets'))