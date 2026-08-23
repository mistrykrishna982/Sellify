from pydantic import BaseModel, EmailStr, Field


class UpdateProfileRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    phone: str = Field(min_length=5, max_length=30)
    location: str = Field(min_length=2, max_length=255)


class RequestEmailChange(BaseModel):
    new_email: EmailStr


class VerifyEmailChange(BaseModel):
    new_email: EmailStr
    otp: str = Field(min_length=6, max_length=6)