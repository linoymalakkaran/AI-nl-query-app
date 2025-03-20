from decimal import Decimal
import json
import datetime
import uuid

class CustomJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder that handles database types"""
    def default(self, obj):
        # Handle Decimal (money, numeric values)
        if isinstance(obj, Decimal):
            return float(obj)
        
        # Handle datetime and date objects
        elif isinstance(obj, datetime.datetime):
            return obj.isoformat()
        elif isinstance(obj, datetime.date):
            return obj.isoformat()
        elif isinstance(obj, datetime.time):
            return obj.isoformat()
        
        # Handle UUID objects (often used for IDs)
        elif isinstance(obj, uuid.UUID):
            return str(obj)
            
        # Handle bytes or bytearrays (binary data)
        elif isinstance(obj, (bytes, bytearray)):
            return obj.decode('utf-8', errors='replace')
            
        # Handle sets by converting to lists
        elif isinstance(obj, set):
            return list(obj)

        # Handle any other custom objects that might implement a to_json method
        elif hasattr(obj, 'to_json'):
            return obj.to_json()
            
        return super().default(obj)
