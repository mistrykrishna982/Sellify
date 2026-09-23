from fastapi import FastAPI
from database import engine
from routes import categories
from routes import products
from routes import product_types
from routes import unsupported_products
from auth import router as auth_router
from fastapi.staticfiles import StaticFiles
from routes.products import router as products_router
from routes.categories import router as categories_router

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
app.include_router(
    unsupported_products.router,
    prefix="/unsupported-products"
)

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