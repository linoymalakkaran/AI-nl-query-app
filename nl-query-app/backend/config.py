import os

class Config:
    """Base configuration class"""
    DEBUG = False
    TESTING = False
    
    # Database settings
    DB_HOST = os.getenv('DB_HOST', 'db')
    DB_NAME = os.getenv('DB_NAME', 'retail_db')
    DB_USER = os.getenv('DB_USER', 'postgres')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')
    
    # NLP model settings
    MODEL_NAME = 'all-MiniLM-L6-v2'
    EMBEDDING_SIMILARITY_THRESHOLD = 0.5

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True

class ProductionConfig(Config):
    """Production configuration"""
    pass

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DB_HOST = 'localhost'

# Configure based on environment variable
config_by_name = {
    'dev': DevelopmentConfig,
    'prod': ProductionConfig,
    'test': TestingConfig
}

# Default to development configuration
active_config = config_by_name[os.getenv('FLASK_ENV', 'dev')]
