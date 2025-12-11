FROM python:3.11-slim

WORKDIR /app

# Copiar dependencias primero (para aprovechar cache)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY app.py .

EXPOSE 3000

CMD ["python", "app.py"]
