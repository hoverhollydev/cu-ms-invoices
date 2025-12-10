# IMAGEN BASE
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias necesarias
RUN pip install requests

# Copiar archivo
COPY app.py .

EXPOSE 3000

CMD ["python", "app.py"]
