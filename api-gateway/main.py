from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
from typing import Dict, Any

# Service URLs
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:3001")
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:3002")
ANALYTICS_SERVICE_URL = os.getenv("ANALYTICS_SERVICE_URL", "http://analytics-service:3004")

# Service routes configuration
SERVICE_ROUTES = {
    "auth": {
        "prefix": "/auth",
        "target": AUTH_SERVICE_URL,
    },
    "users": {
        "prefix": "/users",
        "target": USER_SERVICE_URL,
    },
    "analytics": {
        "prefix": "/analytics",
        "target": ANALYTICS_SERVICE_URL,
    }
}

app = FastAPI(title="API Gateway")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create HTTP client
http_client = httpx.AsyncClient()

@app.get("/")
async def read_root():
    return {
        "message": "API Gateway",
        "services": {
            "auth": f"{AUTH_SERVICE_URL}",
            "users": f"{USER_SERVICE_URL}",
            "analytics": f"{ANALYTICS_SERVICE_URL}"
        }
    }

@app.api_route("/{service_name}{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_request(service_name: str, path: str, request: Request):
    # Check if service exists
    if service_name not in SERVICE_ROUTES:
        raise HTTPException(status_code=404, detail=f"Service '{service_name}' not found")

    service_config = SERVICE_ROUTES[service_name]
    target_url = f"{service_config['target']}{path}"
    
    # Get request method
    method = request.method.lower()
    
    # Get request headers
    headers = dict(request.headers)
    headers.pop("host", None)
    
    # Get request body if it exists
    body = await request.body()
    
    # Forward the request to the appropriate service
    try:
        response = await http_client.request(
            method=method,
            url=target_url,
            headers=headers,
            content=body or None
        )
        
        # Return the response from the service
        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers)
        )
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Service '{service_name}' unavailable: {str(e)}")

@app.on_event("shutdown")
async def shutdown_event():
    await http_client.aclose()