FROM python:3.9-slim

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the challenge manager script
COPY challenge-manager.py /app/

# Run the challenge manager
CMD ["python", "/app/challenge-manager.py"] 