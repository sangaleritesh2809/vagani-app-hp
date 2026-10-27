from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from app.config import settings
from app.routers.api_router import api_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Professional backend for Vargani Collection App matching SRS v1.0 specifications. Integrates FastAPI with Supabase PostgreSQL.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable CORS for Flutter Web, Desktop, and Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")

if __name__ == "__main__":
    import uvicorn
    print(f"Starting Vargani Pro FastAPI server at http://{settings.HOST}:{settings.PORT}")
    print(f"Swagger API Docs available at http://{settings.HOST}:{settings.PORT}/docs")
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
