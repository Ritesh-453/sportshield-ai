import cv2
import os
import uuid
import numpy as np
from PIL import Image
from flask import current_app

def extract_keyframes(video_path, interval_seconds=2):
    """
    Extract keyframes from video every N seconds
    Returns list of (timestamp, frame_path) tuples
    """
    keyframes = []
    temp_dir = os.path.join('uploads', 'video_frames')
    os.makedirs(temp_dir, exist_ok=True)

    try:
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            print(f"Could not open video: {video_path}")
            return []

        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / fps if fps > 0 else 0

        print(f"Video: {duration:.1f}s, {fps:.1f}fps, {total_frames} frames")

        frame_interval = int(fps * interval_seconds)
        if frame_interval < 1:
            frame_interval = 1

        frame_count = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            if frame_count % frame_interval == 0:
                timestamp = frame_count / fps if fps > 0 else 0
                frame_filename = f"frame_{uuid.uuid4().hex}.jpg"
                frame_path = os.path.join(temp_dir, frame_filename)
                cv2.imwrite(frame_path, frame)
                keyframes.append({
                    'timestamp': round(timestamp, 2),
                    'path': frame_path,
                    'filename': frame_filename,
                    'time_str': format_timestamp(timestamp)
                })

            frame_count += 1

        cap.release()
        print(f"Extracted {len(keyframes)} keyframes")
        return keyframes

    except Exception as e:
        print(f"Keyframe extraction error: {e}")
        return []

def format_timestamp(seconds):
    """Convert seconds to MM:SS format"""
    mins = int(seconds // 60)
    secs = int(seconds % 60)
    return f"{mins:02d}:{secs:02d}"

def scan_video(video_path, assets, db_path, upload_folder):
    """
    Scan video for violations against registered assets
    Returns list of violations with timestamps
    """
    from routes.opencv_detector import combined_opencv_score
    from routes.deeplearning_detector import fast_mobilenet_similarity
    import imagehash

    violations = []

    # Extract keyframes
    keyframes = extract_keyframes(video_path, interval_seconds=2)
    if not keyframes:
        return violations

    print(f"Scanning {len(keyframes)} frames against {len(assets)} assets...")

    for asset in assets:
        asset_path = os.path.join(upload_folder, asset['filename'])
        if not os.path.exists(asset_path):
            continue

        asset_violations = []

        for frame in keyframes:
            try:
                # Hash comparison
                img1 = Image.open(asset_path)
                img2 = Image.open(frame['path'])
                hash1 = imagehash.phash(img1)
                hash2 = imagehash.phash(img2)
                hash_score = max(0, (1 - (hash1 - hash2) / 64) * 100)

                # OpenCV comparison
                opencv_score = combined_opencv_score(
                    asset_path, frame['path']
                )

                # MobileNet comparison
                dl_score = fast_mobilenet_similarity(
                    asset_path, frame['path']
                )

                # Combined score
                if dl_score > 0 and opencv_score > 0:
                    final_score = (hash_score * 0.2) + \
                                  (opencv_score * 0.3) + \
                                  (dl_score * 0.5)
                elif opencv_score > 0:
                    final_score = (hash_score * 0.3) + \
                                  (opencv_score * 0.7)
                else:
                    final_score = hash_score

                final_score = round(final_score, 2)

                if final_score > 65:
                    print(f"Match at {frame['time_str']}: {final_score}%")
                    asset_violations.append({
                        'timestamp': frame['timestamp'],
                        'time_str': frame['time_str'],
                        'frame_path': frame['path'],
                        'frame_filename': frame['filename'],
                        'similarity': final_score,
                        'asset_name': asset['name'],
                        'asset_id': asset['id']
                    })

            except Exception as e:
                print(f"Frame scan error: {e}")
                continue

        if asset_violations:
            # Get highest match
            best = max(asset_violations, key=lambda x: x['similarity'])
            violations.extend(asset_violations)
            print(f"Found {len(asset_violations)} violations for {asset['name']}")

    # Clean up frames
    cleanup_frames(keyframes, keep_violations=violations)

    return violations

def cleanup_frames(keyframes, keep_violations=None):
    """Remove temporary frame files except violation frames"""
    keep_paths = set()
    if keep_violations:
        keep_paths = {v['frame_path'] for v in keep_violations}

    for frame in keyframes:
        if frame['path'] not in keep_paths:
            try:
                if os.path.exists(frame['path']):
                    os.remove(frame['path'])
            except:
                pass