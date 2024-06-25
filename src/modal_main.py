import os
import sys

from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI

# Get the current script's directory
current_script_directory = os.path.dirname(os.path.abspath(__file__))
# Get the project root path
project_root = os.path.abspath(os.path.join(current_script_directory, os.pardir))

# Append the project root and current script directory to the system path
sys.path.append(project_root)
sys.path.append(current_script_directory)

# Import the API endpoints from the endpoints module
from src.api.endpoints import (
    docs, 
)

from modal import Image, Secret, Stub, Mount, asgi_app, web_endpoint

# Import the CustomLogger class from the logging configuration module
from src.utils.logging_config import CustomLogger

# Create a FastAPI application
app = FastAPI(swagger_ui_parameters={"tryItOutEnabled": True})

# Configure CORS
origins = [
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

image = Image.debian_slim(python_version='3.11').apt_install(
).pip_install(
    "httpx",
    "pytest",
    "black",
    "isort",
    "mypy",
    "fastapi",
    "uvicorn",
    "python-multipart",
    "python-dotenv",
    "requests",
    "Pillow",
    "colorlog",
    "modal"
)

stub = Stub(
    name="project-name",
    image=image,
    secrets=[Secret.from_name("project-name")]
)

# Include the router for endpoint
app.include_router(docs.router)

@stub.function(image=image, mounts=[Mount.from_local_dir(f"{project_root}/test", remote_path="/root/test")])
@asgi_app()
def fastapi_app():
    return app