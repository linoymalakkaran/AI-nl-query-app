FROM python:3.9

# Install certificates
RUN apt-get update && apt-get install -y ca-certificates openssl

# Set SSL environment variables
ENV PYTHONHTTPSVERIFY=0
ENV HF_HUB_DISABLE_SSL_VERIFICATION=1
ENV CURL_CA_BUNDLE=""
ENV REQUESTS_CA_BUNDLE=""
ENV SSL_CERT_FILE=""

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt

COPY . .

EXPOSE 5000

# Force requests to use unverified SSL
CMD ["python", "-c", "import requests; requests.packages.urllib3.disable_warnings(); import ssl; ssl._create_default_https_context = ssl._create_unverified_context; import app"]