FROM python:3.8-slim 

WORKDIR /notebooks

# install necessary build packages 
RUN apt-get update && apt-get install -y gcc libsndfile1-dev 

# Copy the current directory contents into the container
COPY requirements.txt /notebooks

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org --no-cache -r requirements.txt

EXPOSE 8888 
