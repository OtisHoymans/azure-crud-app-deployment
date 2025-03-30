# Use Python 3.9 as the base image
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

RUN apt-get update && apt-get install -y \
    && apt-get clean

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Set the Flask app environment variable
ENV FLASK_APP=crudapp.py

# Set environment for Flask (Development/Production)
ENV FLASK_ENV=development  

# Initialize and migrate the database
RUN flask db init
RUN flask db migrate -m "entries table"
RUN flask db upgrade

# Expose port 80 for the app
EXPOSE 80

# Run the Flask application
CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]
