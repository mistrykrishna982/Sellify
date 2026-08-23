import os
import smtplib
from email.message import EmailMessage
from dotenv import load_dotenv

load_dotenv()


def send_email_change_otp(
    recipient_email: str,
    otp: str,
):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_username = os.getenv("SMTP_USERNAME")
    smtp_password = os.getenv("SMTP_PASSWORD")

    print("========== EMAIL DEBUG ==========")
    print("SMTP HOST:", smtp_host)
    print("SMTP PORT:", smtp_port)
    print("SMTP USERNAME:", smtp_username)
    print("RECIPIENT:", recipient_email)
    print("OTP:", otp)
    print("=================================")

    message = EmailMessage()

    message["Subject"] = "Sellify - Email Change Verification"
    message["From"] = smtp_username
    message["To"] = recipient_email

    message.set_content(
        f"""
Hello,

You requested to change your Sellify email address.

Your verification code is:

{otp}

This OTP will expire in 10 minutes.

If you did not request this change, please ignore this email.

Sellify
"""
    )

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.set_debuglevel(1)

        server.starttls()

        server.login(
            smtp_username,
            smtp_password,
        )

        server.send_message(message)

    print("EMAIL SENT SUCCESSFULLY")