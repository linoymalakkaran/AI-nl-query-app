# monkey_patch.py
import ssl
import requests
from urllib3.exceptions import InsecureRequestWarning

# Disable SSL verification
ssl._create_default_https_context = ssl._create_unverified_context

# Disable warnings about insecure requests
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Monkey patch requests to always use verify=False
original_get = requests.get
original_post = requests.post
original_request = requests.request

def patched_get(*args, **kwargs):
    kwargs['verify'] = False
    return original_get(*args, **kwargs)

def patched_post(*args, **kwargs):
    kwargs['verify'] = False
    return original_post(*args, **kwargs)

def patched_request(*args, **kwargs):
    kwargs['verify'] = False
    return original_request(*args, **kwargs)

requests.get = patched_get
requests.post = patched_post
requests.request = patched_request

print("SSL verification disabled for all requests")