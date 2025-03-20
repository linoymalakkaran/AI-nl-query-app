from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from flask import current_app

# Global model instance
model = None

def initialize_model(model_name):
    """Initialize and return the sentence transformer model"""
    print(f"Loading language model '{model_name}'...")
    global model
    model = SentenceTransformer(model_name)
    print("Model loaded successfully!")
    return model

def get_model():
    """Get the loaded model instance"""
    global model
    if model is None:
        model = initialize_model(current_app.config['MODEL_NAME'])
    return model

def encode_text(text):
    """Encode text into embeddings"""
    model = get_model()
    return model.encode([text])

def calculate_similarity(query_embedding, template_embeddings):
    """Calculate cosine similarity between embeddings"""
    return cosine_similarity(query_embedding, template_embeddings)[0]

def get_best_match(similarities):
    """Find the index and score of the best match"""
    best_match_idx = np.argmax(similarities)
    best_match_score = similarities[best_match_idx]
    return best_match_idx, best_match_score
