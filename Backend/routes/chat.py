
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text

from database import engine
from auth import get_current_user

router = APIRouter(prefix="/chats", tags=["Chats"])


class SendMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=5000)


def get_user_id(current_user: dict) -> int:
    user_id = current_user.get("U_ID") or current_user.get("user_id")

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid user session",
        )

    return int(user_id)


def get_chat_for_user(connection, chat_id: int, user_id: int):
    result = connection.execute(
        text("""
            SELECT chat_id, product_id, buyer_id, seller_id
            FROM chats
            WHERE chat_id = :chat_id
              AND (buyer_id = :user_id OR seller_id = :user_id)
            LIMIT 1
        """),
        {"chat_id": chat_id, "user_id": user_id},
    )

    chat = result.mappings().first()

    if not chat:
        raise HTTPException(
            status_code=404,
            detail="Conversation not found",
        )

    return chat


@router.post("/product/{product_id}")
def get_or_create_chat(
    product_id: int,
    current_user=Depends(get_current_user),
):
    user_id = get_user_id(current_user)

    with engine.begin() as connection:
        result = connection.execute(
            text("""
                SELECT P_ID, U_ID
                FROM PRODUCTS
                WHERE P_ID = :product_id
                  AND STATUS = 'ACTIVE'
                LIMIT 1
            """),
            {"product_id": product_id},
        )

        product = result.mappings().first()

        if not product:
            raise HTTPException(
                status_code=404,
                detail="Product not found",
            )

        seller_id = int(product["U_ID"])

        if seller_id == user_id:
            raise HTTPException(
                status_code=400,
                detail="You cannot chat about your own product",
            )

        connection.execute(
            text("""
                INSERT INTO chats (product_id, buyer_id, seller_id)
                VALUES (:product_id, :buyer_id, :seller_id)
                ON DUPLICATE KEY UPDATE
                    chat_id = LAST_INSERT_ID(chat_id)
            """),
            {
                "product_id": product_id,
                "buyer_id": user_id,
                "seller_id": seller_id,
            },
        )

        result = connection.execute(
            text("""
                SELECT chat_id, product_id, buyer_id, seller_id
                FROM chats
                WHERE product_id = :product_id
                  AND buyer_id = :buyer_id
                  AND seller_id = :seller_id
                LIMIT 1
            """),
            {
                "product_id": product_id,
                "buyer_id": user_id,
                "seller_id": seller_id,
            },
        )

        chat = result.mappings().first()

        return {"chat": dict(chat)}



@router.get("/{chat_id}/messages")
def get_messages(
    chat_id: int,
    current_user=Depends(get_current_user),
):
    user_id = get_user_id(current_user)

    with engine.begin() as connection:
        get_chat_for_user(connection, chat_id, user_id)

        # Mark the other participant's messages as read.
        # This runs when the recipient opens or refreshes the chat.
        connection.execute(
            text("""
                UPDATE chat_messages
                SET is_read = 1
                WHERE chat_id = :chat_id
                  AND sender_id != :user_id
                  AND is_read = 0
                  AND deleted_at IS NULL
            """),
            {
                "chat_id": chat_id,
                "user_id": user_id,
            },
        )

        result = connection.execute(
            text("""
                SELECT
                    message_id,
                    chat_id,
                    sender_id,
                    message,
                    is_read,
                    message_type,
                    file_url,
                    file_name,
                    file_mime_type,
                    file_size,
                    deleted_at,
                    created_at
                FROM chat_messages
                WHERE chat_id = :chat_id
                ORDER BY created_at ASC, message_id ASC
            """),
            {"chat_id": chat_id},
        )

        messages = []

        for row in result.mappings().all():
            is_deleted = row["deleted_at"] is not None

            messages.append({
                "message_id": row["message_id"],
                "chat_id": row["chat_id"],
                "sender_id": row["sender_id"],
                "message": (
                    "Message unsent"
                    if is_deleted
                    else row["message"]
                ),
                "is_read": bool(row["is_read"]),
                "message_type": row["message_type"],
                "file_url": (
                    None if is_deleted else row["file_url"]
                ),
                "file_name": (
                    None if is_deleted else row["file_name"]
                ),
                "file_mime_type": (
                    None if is_deleted else row["file_mime_type"]
                ),
                "file_size": (
                    None if is_deleted else row["file_size"]
                ),
                "is_deleted": is_deleted,
                "created_at": (
                    row["created_at"].isoformat()
                    if row["created_at"] else None
                ),
            })

        return {"messages": messages}


@router.post("/{chat_id}/messages")
def send_message(
    chat_id: int,
    request: SendMessageRequest,
    current_user=Depends(get_current_user),
):
    user_id = get_user_id(current_user)
    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty",
        )

    with engine.begin() as connection:
        get_chat_for_user(connection, chat_id, user_id)

        result = connection.execute(
            text("""
                INSERT INTO chat_messages
                    (chat_id, sender_id, message)
                VALUES
                    (:chat_id, :sender_id, :message)
            """),
            {
                "chat_id": chat_id,
                "sender_id": user_id,
                "message": message,
            },
        )

        message_id = result.lastrowid

        connection.execute(
            text("""
                UPDATE chats
                SET updated_at = CURRENT_TIMESTAMP
                WHERE chat_id = :chat_id
            """),
            {"chat_id": chat_id},
        )

        return {
            "message": "Message sent successfully",
            "message_id": message_id,
            "chat_id": chat_id,
        }




@router.delete("/{chat_id}/messages/{message_id}")
def unsend_message(
    chat_id: int,
    message_id: int,
    current_user=Depends(get_current_user),
):
    user_id = get_user_id(current_user)

    with engine.begin() as connection:
        # Verify that this user belongs to the conversation.
        get_chat_for_user(connection, chat_id, user_id)

        # Only the sender can unsend their own unread message.
        result = connection.execute(
            text("""
                UPDATE chat_messages
                SET deleted_at = CURRENT_TIMESTAMP
                WHERE message_id = :message_id
                  AND chat_id = :chat_id
                  AND sender_id = :user_id
                  AND is_read = 0
                  AND deleted_at IS NULL
            """),
            {
                "message_id": message_id,
                "chat_id": chat_id,
                "user_id": user_id,
            },
        )

        if result.rowcount == 0:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Message cannot be unsent. "
                    "It may already be read, deleted, "
                    "or not belong to you."
                ),
            )

        connection.execute(
            text("""
                UPDATE chats
                SET updated_at = CURRENT_TIMESTAMP
                WHERE chat_id = :chat_id
            """),
            {"chat_id": chat_id},
        )

        return {
            "message": "Message unsent successfully",
            "message_id": message_id,
        }




@router.get("")
def list_chats(
    current_user=Depends(get_current_user),
):
    user_id = get_user_id(current_user)

    with engine.connect() as connection:
        result = connection.execute(
            text("""
                SELECT
                    c.chat_id,
                    c.product_id,
                    c.buyer_id,
                    c.seller_id,
                    p.TITLE AS product_title,
                    p.PRICE AS product_price,

                    CASE
                        WHEN c.buyer_id = :user_id
                            THEN c.seller_id
                        ELSE c.buyer_id
                    END AS other_user_id,

                    other_user.U_NAME AS other_user_name,

                    
                    (
                        SELECT m.message
                        FROM chat_messages m
                        WHERE m.chat_id = c.chat_id
                            AND m.deleted_at IS NULL
                        ORDER BY m.message_id DESC
                        LIMIT 1
                    ) AS last_message,


                    c.updated_at

                FROM chats c

                JOIN PRODUCTS p
                    ON p.P_ID = c.product_id

                LEFT JOIN users other_user
                    ON other_user.U_ID = CASE
                        WHEN c.buyer_id = :user_id
                            THEN c.seller_id
                        ELSE c.buyer_id
                    END

                WHERE c.buyer_id = :user_id
                   OR c.seller_id = :user_id

                ORDER BY c.updated_at DESC
            """),
            {"user_id": user_id},
        )

        chats = []

        for row in result.mappings().all():
            chats.append({
                "chat_id": row["chat_id"],
                "product_id": row["product_id"],
                "buyer_id": row["buyer_id"],
                "seller_id": row["seller_id"],
                "other_user_id": row["other_user_id"],
                "other_user_name": row["other_user_name"],
                "product_title": row["product_title"],
                "product_price": float(row["product_price"]),
                "last_message": row["last_message"],
                "updated_at": (
                    row["updated_at"].isoformat()
                    if row["updated_at"] else None
                ),
            })

        return {"chats": chats}
