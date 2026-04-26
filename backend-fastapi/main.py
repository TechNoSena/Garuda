from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Initialize Config & Firebase
import app.config

# Import Routers
from app.routers import auth, shipments, routing

app = FastAPI(
    title="Garuda Logistics Management Backend",
    description="Full Omnichannel Routing and Logistics Tracking Platform"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(shipments.router)
app.include_router(routing.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)