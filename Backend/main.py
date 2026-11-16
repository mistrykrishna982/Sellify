from fastapi import FastAPI
from database import engine
from routes import categories
from routes import products
from routes import product_types
from routes import reports
from auth import router as auth_router
from fastapi.staticfiles import StaticFiles
from routes.products import router as products_router
from routes.categories import router as categories_router
from routes.classification_requests import router as classification_requests_router
from routes.notifications import router as notifications_router
from routes.cart import router as cart_router
from routes import favorites
from routes.chat import router as chat_router
from routes.admin_users import router as admin_users_router
from routes.admin_user_products import router as admin_user_products_router


app = FastAPI(
    title="Sellify API",
    description="Backend API for Sellify",
    version="1.0.0"
)

# Routers
app.include_router(auth_router)
app.include_router(products_router)
app.include_router(categories_router)
app.include_router(
    product_types.router, 
    prefix="/product-types")

app.include_router(reports.router)
app.include_router(
    classification_requests_router
)
app.include_router(notifications_router)
app.include_router(cart_router)
app.include_router(favorites.router)
app.include_router(chat_router)
app.include_router(admin_users_router)
app.include_router(admin_user_products_router)



# Uploaded files
app.mount(
    "/uploads",
    StaticFiles(directory="uploads"),
    name="uploads",
)


@app.get("/")
def home():

    try:
        connection = engine.connect()
        connection.close()

        return {
            "message": "Sellify API is running",
            "database": "MySQL connected"
        }

    except Exception as e:

        return {
            "message": "Database connection failed",
            "error": str(e)
        }