from fastapi import APIRouter, HTTPException
from app.models import RegisterRequest, LoginRequest
from app.services import firebase_service

router = APIRouter(prefix="/v1/auth", tags=["Auth"])

@router.post("/register")
async def register(req: RegisterRequest):
    try:
        user_data = firebase_service.create_user(req)
        return {"status": "success", "user": user_data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
async def login(req: LoginRequest):
    try:
        token_data = firebase_service.login_user(req)
        return {"status": "success", "data": token_data}
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))
