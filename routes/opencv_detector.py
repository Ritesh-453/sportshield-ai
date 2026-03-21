import cv2
import numpy as np
from PIL import Image
import os

def load_image_cv2(path):
    """Load image and convert to grayscale for SIFT"""
    try:
        img = cv2.imread(path)
        if img is None:
            pil_img = Image.open(path).convert('RGB')
            img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        return img, gray
    except Exception as e:
        print(f"Error loading image: {e}")
        return None, None

def sift_similarity(img1_path, img2_path):
    """
    Compare two images using SIFT feature matching.
    Returns similarity score 0-100
    """
    try:
        _, gray1 = load_image_cv2(img1_path)
        _, gray2 = load_image_cv2(img2_path)

        if gray1 is None or gray2 is None:
            return 0

        # Initialize SIFT detector
        sift = cv2.SIFT_create()

        # Find keypoints and descriptors
        kp1, des1 = sift.detectAndCompute(gray1, None)
        kp2, des2 = sift.detectAndCompute(gray2, None)

        if des1 is None or des2 is None:
            return 0
        if len(kp1) < 2 or len(kp2) < 2:
            return 0

        # FLANN matcher for fast matching
        FLANN_INDEX_KDTREE = 1
        index_params = dict(algorithm=FLANN_INDEX_KDTREE, trees=5)
        search_params = dict(checks=50)
        flann = cv2.FlannBasedMatcher(index_params, search_params)

        matches = flann.knnMatch(des1, des2, k=2)

        # Apply Lowe's ratio test to filter good matches
        good_matches = []
        for m, n in matches:
            if m.distance < 0.7 * n.distance:
                good_matches.append(m)

        # Calculate similarity score
        if len(kp1) == 0 or len(kp2) == 0:
            return 0

        # Score based on good matches relative to keypoints
        score = (len(good_matches) / min(len(kp1), len(kp2))) * 100
        score = min(100, score * 3)  # Scale up for better range

        return round(score, 2)

    except Exception as e:
        print(f"SIFT error: {e}")
        return 0

def orb_similarity(img1_path, img2_path):
    """
    Compare using ORB — faster than SIFT, good for real-time
    Returns similarity score 0-100
    """
    try:
        _, gray1 = load_image_cv2(img1_path)
        _, gray2 = load_image_cv2(img2_path)

        if gray1 is None or gray2 is None:
            return 0

        # Initialize ORB
        orb = cv2.ORB_create(nfeatures=500)

        kp1, des1 = orb.detectAndCompute(gray1, None)
        kp2, des2 = orb.detectAndCompute(gray2, None)

        if des1 is None or des2 is None:
            return 0
        if len(kp1) < 2 or len(kp2) < 2:
            return 0

        # Brute force matcher for ORB
        bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        matches = bf.match(des1, des2)
        matches = sorted(matches, key=lambda x: x.distance)

        # Take top 30% matches
        good_matches = matches[:int(len(matches) * 0.3)]

        score = (len(good_matches) / min(len(kp1), len(kp2))) * 100
        score = min(100, score * 4)

        return round(score, 2)

    except Exception as e:
        print(f"ORB error: {e}")
        return 0

def combined_opencv_score(img1_path, img2_path):
    """
    Combine SIFT + ORB for maximum accuracy
    Returns final score 0-100
    """
    sift_score = sift_similarity(img1_path, img2_path)
    orb_score = orb_similarity(img1_path, img2_path)

    # Weighted combination — SIFT is more accurate
    final = (sift_score * 0.6) + (orb_score * 0.4)
    return round(final, 2)

def get_keypoint_count(img_path):
    """Get number of unique features detected in image"""
    try:
        _, gray = load_image_cv2(img_path)
        if gray is None:
            return 0
        sift = cv2.SIFT_create()
        kp, _ = sift.detectAndCompute(gray, None)
        return len(kp)
    except:
        return 0