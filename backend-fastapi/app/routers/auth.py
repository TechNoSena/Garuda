from fastapi import APIRouter, HTTPException
from app.models import RegisterRequest, LoginRequest, ResetPasswordRequest
from app.services import firebase_service

router = APIRouter(prefix="/v1/auth", tags=["🔐 Auth"])

@router.post("/register", summary="Register New User",
             description="Create a new account. Roles: SUPPLIER, LOGISTICS, DELIVERY_MAN, CONSUMER")
async def register(req: RegisterRequest):
    try:
        user_data = firebase_service.create_user(req)
        return {"status": "success", "user": user_data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", summary="Login",
             description="Returns Firebase idToken + user profile with role")
async def login(req: LoginRequest):
    try:
        token_data = firebase_service.login_user(req)
        return {"status": "success", "data": token_data}
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@router.post("/reset-password", summary="Reset Password",
             description="Send a password reset email to the user")
async def reset_password(req: ResetPasswordRequest):
    try:
        result = firebase_service.reset_password(req.email)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/profile/{uid}", summary="Get User Profile",
            description="Fetch full user profile from Firestore by UID")
async def get_profile(uid: str):
    try:
        return firebase_service.get_user_profile(uid)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))
