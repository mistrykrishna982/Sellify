from services.email_service import (
    send_email_change_otp,
    send_forgot_password_otp,
)

import os
import uuid
import jwt
from fastapi import (
    APIRouter,
    HTTPException,
    UploadFile,
    File,
)

from sqlalchemy import text
from pydantic import BaseModel, EmailStr

from pwdlib import PasswordHash

from database import engine
from datetime import datetime, timedelta, timezone

from schemas.profile import (
    UpdateProfileRequest,
    RequestEmailChange,
    VerifyEmailChange,
)

from utils.otp import generate_otp, hash_otp, verify_otp


router = APIRouter()

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")

if not JWT_SECRET_KEY:
    raise RuntimeError("JWT_SECRET_KEY is not set in the .env file")

JWT_ALGORITHM = "HS256"

JWT_EXPIRATION_MINUTES = 60


def create_access_token(user_id: int, role: str):
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=JWT_EXPIRATION_MINUTES
    )

    payload = {
        "user_id": user_id,
        "role": role,
        "exp": expire
    }

    return jwt.encode(
        payload,
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM
    )


password_hash = PasswordHash.recommended()

class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: str
    location: str
    profile_image: str | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class VerifyForgotPasswordRequest(BaseModel):
    email: EmailStr
    otp: str


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str


@router.post("/register")
def register(user: RegisterRequest):

    try:
        with engine.begin() as connection:

            # Check if email already exists
            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": user.email
                }
            )

            existing_user = result.fetchone()

            if existing_user:
                raise HTTPException(
                    status_code=400,
                    detail="Email already registered"
                )

            # Hash password
            hashed_password = password_hash.hash(user.password)

            # Insert into USERS
            result = connection.execute(
                text("""
                    INSERT INTO USERS
                    (U_NAME, EMAIL, PASSWORD, ROLE)
                    VALUES
                    (:name, :email, :password, 'USER')
                """),
                {
                    "name": user.name,
                    "email": user.email,
                    "password": hashed_password
                }
            )

            # Get newly created U_ID
            user_id = result.lastrowid

            # Insert into USER_PROFILES
            connection.execute(
                text("""
                    INSERT INTO USER_PROFILES
                    (U_ID, PROFILE_IMAGE, PHONE, LOCATION)
                    VALUES
                    (:user_id, :profile_image, :phone, :location)
                """),
                {
                    "user_id": user_id,
                    "profile_image": user.profile_image,
                    "phone": user.phone,
                    "location": user.location
                }
            )

            return {
                "message": "Registration successful",
                "user_id": user_id
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )




@router.post("/login")
def login(user: LoginRequest):

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT U_ID, U_NAME, EMAIL, PASSWORD, ROLE
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": user.email
                }
            )

            existing_user = result.fetchone()

            if not existing_user:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid email or password"
                )

            password_is_correct = password_hash.verify(
                user.password,
                existing_user.PASSWORD
            )

            if not password_is_correct:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid email or password"
                )

            token = create_access_token(
                user_id=existing_user.U_ID,
                role=existing_user.ROLE
            )

            return {
                "message": "Login successful",
                "user_id": existing_user.U_ID,
                "name": existing_user.U_NAME,
                "email": existing_user.EMAIL,
                "role": existing_user.ROLE,
                "access_token": token,
                "token_type": "bearer"
        }
    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.post("/forgot-password/request")
def forgot_password_request(request: ForgotPasswordRequest):

    try:
        with engine.begin() as connection:

            # Find user by email
            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": request.email
                }
            )

            user = result.fetchone()

            # Do not reveal whether email exists
            if not user:
                return {
                    "message": "If an account exists, an OTP has been sent."
                }

            user_id = user.U_ID

            # Delete previous unused OTPs
            connection.execute(
                text("""
                    DELETE FROM forgot_password_otps
                    WHERE u_id = :user_id
                      AND verified = 0
                """),
                {
                    "user_id": user_id
                }
            )

            # Generate new OTP
            otp = generate_otp()

            # Hash OTP before storing
            otp_hash = hash_otp(otp)

            expires_at = datetime.utcnow() + timedelta(minutes=10)

            # Save OTP
            connection.execute(
                text("""
                    INSERT INTO forgot_password_otps
                    (
                        u_id,
                        otp_hash,
                        expires_at,
                        verified
                    )
                    VALUES
                    (
                        :user_id,
                        :otp_hash,
                        :expires_at,
                        0
                    )
                """),
                {
                    "user_id": user_id,
                    "otp_hash": otp_hash,
                    "expires_at": expires_at
                }
            )

            # Send OTP
            send_forgot_password_otp(
                recipient_email=request.email,
                otp=otp
            )

            return {
                "message": "If an account exists, an OTP has been sent."
            }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.post("/forgot-password/verify")
def forgot_password_verify(
    request: VerifyForgotPasswordRequest
):

    try:
        with engine.begin() as connection:

            # Find user by email
            user_result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": request.email
                }
            )

            user = user_result.fetchone()

            if not user:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid email or OTP."
                )

            # Get latest OTP for this user
            otp_result = connection.execute(
                text("""
                    SELECT
                        id,
                        otp_hash,
                        expires_at,
                        verified
                    FROM forgot_password_otps
                    WHERE u_id = :user_id
                    ORDER BY created_at DESC
                    LIMIT 1
                """),
                {
                    "user_id": user.U_ID
                }
            )

            otp_record = otp_result.fetchone()

            if not otp_record:
                raise HTTPException(
                    status_code=400,
                    detail="OTP not found."
                )

            # Check if OTP was already used
            if otp_record.verified:
                raise HTTPException(
                    status_code=400,
                    detail="OTP already used."
                )

            # Check expiration
            if datetime.utcnow() > otp_record.expires_at:
                raise HTTPException(
                    status_code=400,
                    detail="OTP has expired."
                )

            # Verify OTP
            if not verify_otp(
                request.otp,
                otp_record.otp_hash
            ):
                raise HTTPException(
                    status_code=400,
                    detail="Invalid OTP."
                )

            # Mark OTP as verified
            connection.execute(
                text("""
                    UPDATE forgot_password_otps
                    SET verified = 1
                    WHERE id = :otp_id
                """),
                {
                    "otp_id": otp_record.id
                }
            )

            return {
                "message": "OTP verified successfully."
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

@router.post("/forgot-password/reset")
def forgot_password_reset(
    request: ResetPasswordRequest
):

    try:
        with engine.begin() as connection:

            # Find user
            user_result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": request.email
                }
            )

            user = user_result.fetchone()

            if not user:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid request."
                )

            # Check that latest OTP was verified
            otp_result = connection.execute(
                text("""
                    SELECT id, verified
                    FROM forgot_password_otps
                    WHERE u_id = :user_id
                    ORDER BY created_at DESC
                    LIMIT 1
                """),
                {
                    "user_id": user.U_ID
                }
            )

            otp_record = otp_result.fetchone()

            if not otp_record:
                raise HTTPException(
                    status_code=400,
                    detail="OTP verification required."
                )

            if not otp_record.verified:
                raise HTTPException(
                    status_code=400,
                    detail="OTP verification required."
                )

            # Hash new password
            hashed_password = password_hash.hash(
                request.new_password
            )

            # Update password
            connection.execute(
                text("""
                    UPDATE USERS
                    SET PASSWORD = :password
                    WHERE U_ID = :user_id
                """),
                {
                    "password": hashed_password,
                    "user_id": user.U_ID
                }
            )

            # Consume the verified OTP
            connection.execute(
                text("""
                    DELETE FROM forgot_password_otps
                    WHERE id = :otp_id
                """),
                {
                    "otp_id": otp_record.id
                }
            )

            return {
                "message": "Password reset successfully."
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.get("/profile/{user_id}")
def get_profile(user_id: int):

    try:

        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        u.U_ID,
                        u.U_NAME,
                        u.EMAIL,
                        u.ROLE,
                        p.PHONE,
                        p.LOCATION,
                        p.PROFILE_IMAGE
                    FROM USERS u
                    LEFT JOIN USER_PROFILES p
                        ON u.U_ID = p.U_ID
                    WHERE u.U_ID = :user_id
                """),
                {
                    "user_id": user_id
                }
            )

            user = result.fetchone()

            if not user:
                raise HTTPException(
                    status_code=404,
                    detail="User not found"
                )

            return {
                "user_id": user.U_ID,
                "name": user.U_NAME,
                "email": user.EMAIL,
                "role": user.ROLE,
                "phone": user.PHONE,
                "location": user.LOCATION,
                "profile_image": user.PROFILE_IMAGE,
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@router.post("/profile/{user_id}/image")
async def upload_profile_image(
    user_id: int,
    file: UploadFile = File(...)
):
    try:

        # =====================================================
        # CHECK USER
        # =====================================================

        with engine.begin() as connection:

            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE U_ID = :user_id
                """),
                {
                    "user_id": user_id
                }
            )

            user = result.fetchone()

            if not user:
                raise HTTPException(
                    status_code=404,
                    detail="User not found"
                )

        # =====================================================
        # CHECK FILE TYPE
        # =====================================================

        allowed_types = {
            "image/jpeg": ".jpg",
            "image/jpg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
        }

        content_type = (file.content_type or "").lower()

        if content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail="Only JPG, PNG and WEBP images are allowed"
            )

        # =====================================================
        # READ FILE
        # =====================================================

        image_data = await file.read()

        # Maximum 5 MB
        max_size = 5 * 1024 * 1024

        if len(image_data) > max_size:
            raise HTTPException(
                status_code=400,
                detail="Image must be smaller than 5 MB"
            )

        if len(image_data) == 0:
            raise HTTPException(
                status_code=400,
                detail="Empty image file"
            )

        # =====================================================
        # CREATE UPLOAD DIRECTORY
        # =====================================================

        upload_directory = "uploads"

        os.makedirs(
            upload_directory,
            exist_ok=True
        )

        # =====================================================
        # GENERATE SAFE RANDOM FILE NAME
        # =====================================================

        extension = allowed_types[content_type]

        filename = f"{uuid.uuid4().hex}{extension}"

        file_path = os.path.join(
            upload_directory,
            filename
        )

        # =====================================================
        # SAVE IMAGE
        # =====================================================

        with open(file_path, "wb") as output_file:
            output_file.write(image_data)

        # =====================================================
        # IMAGE URL
        # =====================================================

        image_url = f"/uploads/{filename}"

        # =====================================================
        # SAVE PATH TO MYSQL
        # =====================================================

        with engine.begin() as connection:

            connection.execute(
                text("""
                    UPDATE USER_PROFILES
                    SET PROFILE_IMAGE = :profile_image
                    WHERE U_ID = :user_id
                """),
                {
                    "profile_image": image_url,
                    "user_id": user_id
                }
            )

        # =====================================================
        # RETURN RESPONSE
        # =====================================================

        return {
            "message": "Profile image updated successfully",
            "profile_image": image_url
        }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.put("/profile/{user_id}")
def update_profile(
    user_id: int,
    profile: UpdateProfileRequest
):

    try:
        with engine.begin() as connection:

            # Check user exists
            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE U_ID = :user_id
                """),
                {
                    "user_id": user_id
                }
            )

            existing_user = result.fetchone()

            if not existing_user:
                raise HTTPException(
                    status_code=404,
                    detail="User not found"
                )

            # Update name
            connection.execute(
                text("""
                    UPDATE USERS
                    SET U_NAME = :name
                    WHERE U_ID = :user_id
                """),
                {
                    "name": profile.name,
                    "user_id": user_id
                }
            )

            # Update phone + location
            result = connection.execute(
                text("""
                    UPDATE USER_PROFILES
                    SET PHONE = :phone,
                        LOCATION = :location
                    WHERE U_ID = :user_id
                """),
                {
                    "phone": profile.phone,
                    "location": profile.location,
                    "user_id": user_id
                }
            )

            return {
                "message": "Profile updated successfully",
                "name": profile.name,
                "phone": profile.phone,
                "location": profile.location
            }

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Failed to update profile"
        )




@router.post("/profile/{user_id}/email/request")
def request_email_change(
    user_id: int,
    request: RequestEmailChange
):
    try:
        with engine.begin() as connection:

            # Get current user
            result = connection.execute(
                text("""
                    SELECT U_ID, EMAIL
                    FROM USERS
                    WHERE U_ID = :user_id
                """),
                {
                    "user_id": user_id
                }
            )

            user = result.fetchone()

            if not user:
                raise HTTPException(
                    status_code=404,
                    detail="User not found"
                )

            # Check if new email is same as current email
            if user.EMAIL.lower() == request.new_email.lower():
                raise HTTPException(
                    status_code=400,
                    detail="New email is the same as your current email"
                )

            # Check whether new email already belongs to another user
            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                """),
                {
                    "email": request.new_email
                }
            )

            existing_email = result.fetchone()

            if existing_email:
                raise HTTPException(
                    status_code=400,
                    detail="Email is already registered"
                )

            # Generate OTP
            otp = generate_otp()

            # Hash OTP
            otp_hash = hash_otp(otp)

            # OTP expires after 10 minutes
            expires_at = datetime.utcnow() + timedelta(minutes=10)

            # Remove previous unverified OTPs
            connection.execute(
                text("""
                    DELETE FROM email_change_otps
                    WHERE u_id = :user_id
                      AND verified = 0
                """),
                {
                    "user_id": user_id
                }
            )

            # Save new OTP
            connection.execute(
                text("""
                    INSERT INTO email_change_otps
                    (
                        u_id,
                        new_email,
                        otp_hash,
                        expires_at,
                        verified
                    )
                    VALUES
                    (
                        :user_id,
                        :new_email,
                        :otp_hash,
                        :expires_at,
                        0
                    )
                """),
                {
                    "user_id": user_id,
                    "new_email": request.new_email,
                    "otp_hash": otp_hash,
                    "expires_at": expires_at
                }
            )

            # Send OTP to new email
            send_email_change_otp(
                recipient_email=request.new_email,
                otp=otp
            )

            return {
                "message": "OTP sent successfully"
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )



@router.post("/profile/{user_id}/email/verify")
def verify_email_change(
    user_id: int,
    request: VerifyEmailChange
):
    try:
        with engine.begin() as connection:

            # Get latest OTP request
            result = connection.execute(
                text("""
                    SELECT
                        id,
                        new_email,
                        otp_hash,
                        expires_at,
                        verified
                    FROM email_change_otps
                    WHERE u_id = :user_id
                      AND new_email = :new_email
                    ORDER BY created_at DESC
                    LIMIT 1
                """),
                {
                    "user_id": user_id,
                    "new_email": request.new_email
                }
            )

            otp_record = result.fetchone()

            if not otp_record:
                raise HTTPException(
                    status_code=400,
                    detail="No OTP request found"
                )

            # Already verified
            if otp_record.verified:
                raise HTTPException(
                    status_code=400,
                    detail="OTP has already been used"
                )

            # Check expiration
            if datetime.utcnow() > otp_record.expires_at:
                raise HTTPException(
                    status_code=400,
                    detail="OTP has expired"
                )

            # Verify OTP
            if not verify_otp(
                request.otp,
                otp_record.otp_hash
            ):
                raise HTTPException(
                    status_code=400,
                    detail="Invalid OTP"
                )

            # Make sure email hasn't been taken meanwhile
            result = connection.execute(
                text("""
                    SELECT U_ID
                    FROM USERS
                    WHERE EMAIL = :email
                      AND U_ID != :user_id
                """),
                {
                    "email": request.new_email,
                    "user_id": user_id
                }
            )

            existing_email = result.fetchone()

            if existing_email:
                raise HTTPException(
                    status_code=400,
                    detail="Email is already registered"
                )

            # Update email
            connection.execute(
                text("""
                    UPDATE USERS
                    SET EMAIL = :email
                    WHERE U_ID = :user_id
                """),
                {
                    "email": request.new_email,
                    "user_id": user_id
                }
            )

            # Mark OTP as verified
            connection.execute(
                text("""
                    UPDATE email_change_otps
                    SET verified = 1
                    WHERE id = :otp_id
                """),
                {
                    "otp_id": otp_record.id
                }
            )

            return {
                "message": "Email updated successfully",
                "email": request.new_email
            }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
