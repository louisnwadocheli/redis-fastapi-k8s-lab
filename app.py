from fastapi import FastAPI, HTTPException, Request
import redis
import os

app = FastAPI()

# Redis connection settings.
# In Kubernetes, these values will come from ConfigMap and Secret.
# Locally, default values are used if environment variables are missing.
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")

# Create Redis client.
# decode_responses=False means Redis returns bytes, so we decode manually later.
r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=False
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    print(f"Incoming request path: {request.url.path}")
    response = await call_next(request)
    return response


@app.get("/")
def root():
    return {"message": "FastAPI is working"}


@app.post("/cache")
def store_value(key: str, value: str):
    try:
        r.set(key, value)
        return {"message": f"Stored key '{key}'"}
    except redis.RedisError as e:
        raise HTTPException(status_code=500, detail=f"Redis error: {str(e)}")


@app.get("/cache")
def get_value(key: str):
    try:
        value = r.get(key)

        if value is None:
            raise HTTPException(status_code=404, detail="Key not found")

        return {"key": key, "value": value.decode()}

    except redis.RedisError as e:
        raise HTTPException(status_code=500, detail=f"Redis error: {str(e)}")


@app.get("/secret-test")
def show_secret():
    return {"password": os.getenv("REDIS_PASSWORD")}
