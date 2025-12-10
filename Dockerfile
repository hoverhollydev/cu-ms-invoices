# IMAGEN BASE
FROM python:3.11-alpine
 
# INSTRUCCIONES
WORKDIR /app

# Instalar Flask
RUN pip install flask

# Copiar el archivo de la aplicación
COPY app.py .

# Exponer el puerto 3000
EXPOSE 3000
 
# ENTRYPOINT
CMD ["python", "app.py"]