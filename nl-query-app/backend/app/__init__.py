from flask import Flask
from flask_cors import CORS
import nltk
from app.utils.monkey_patch import apply_monkey_patch
from app.models.custom_types import CustomJSONEncoder
from app.nlp.embeddings import initialize_model
from config import active_config

# Apply monkey patch at the start
apply_monkey_patch()

# Initialize global objects
nlp_model = None

def create_app(config=active_config):
    """Application factory function"""
    # Create the Flask app
    app = Flask(__name__)
    app.config.from_object(config)
    
    # Apply custom JSON encoder
    app.json_encoder = CustomJSONEncoder
    
    # Enable CORS
    CORS(app)
    
    # Download NLTK resources
    try:
        nltk.download('punkt', quiet=True)
        nltk.download('stopwords', quiet=True)
    except:
        print("NLTK download failed, but continuing...")
    
    # Initialize NLP model
    global nlp_model
    nlp_model = initialize_model(app.config['MODEL_NAME'])
    
    # Register API blueprint
    from app.api.routes import api_bp
    app.register_blueprint(api_bp)
    
    return app
