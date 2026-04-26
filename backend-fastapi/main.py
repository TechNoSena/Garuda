from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from scalar_fastapi import get_scalar_api_reference

# Initialize Config & Firebase
import app.config

# Import Routers
from app.routers import auth, shipments, routing, risk, notifications, analytics, admin, intelligence

from fastapi.responses import RedirectResponse

app = FastAPI(
    title="Garuda Logistics Management Backend",
    description="Full Omnichannel Routing and Logistics Tracking Platform",
    docs_url=None,
    redoc_url=None
)

@app.get("/docs", include_in_schema=False)
async def redirected_docs():
    return RedirectResponse(url="/scalar")

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
app.include_router(risk.router)
app.include_router(notifications.router)
app.include_router(analytics.router)
app.include_router(admin.router)
app.include_router(intelligence.router)

@app.get("/scalar", include_in_schema=False)
async def scalar_html():
    return get_scalar_api_reference(
        openapi_url=app.openapi_url,
        title=app.title,
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)