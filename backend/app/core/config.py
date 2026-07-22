from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    # Host port is 5433 (not the default 5432) to avoid clashing with other
    # local Postgres instances.
    database_url: str = "postgresql+asyncpg://petpal:petpal@localhost:5433/petpal"

    # Auth
    jwt_secret: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 14

    # Social login. google_client_id is the OAuth "Web application" client
    # ID from Google Cloud Console -- it's the expected audience on the ID
    # token, and must match the serverClientId the Flutter app requests.
    # facebook_app_id/secret come from the Facebook Developer Console app.
    google_client_id: str = ""
    facebook_app_id: str = ""
    facebook_app_secret: str = ""

    # Outgoing email (password reset codes). Leave blank in dev -- the code
    # is logged to the backend console instead of actually being sent, same
    # "never crashes, just tells you it's unconfigured" pattern as the OAuth
    # settings above.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "PetPal <no-reply@petpal.app>"
    smtp_use_tls: bool = True

    # Object storage (MinIO / S3-compatible)
    s3_endpoint_url: str = "http://localhost:9000"
    s3_access_key: str = "petpal"
    s3_secret_key: str = "petpal12345"
    s3_bucket: str = "petpal"
    s3_region: str = "us-east-1"
    s3_public_endpoint_url: str = "http://localhost:9000"

    # Camera credential encryption (Fernet key, 32 url-safe base64 bytes)
    camera_secret_key: str = "dev-camera-key-change-me-32-bytes-min!!"
    # Pre-filled in the technician's "add camera" form so every camera's RTSP
    # account uses the same username by convention -- only the password
    # varies per camera. Cuts down on typo-driven 401s from technicians
    # retyping a username per camera.
    camera_default_username: str = "petpal"

    # LiveKit (self-hosted, voice/video calls in chat). livekit_url is the
    # backend-internal address (the docker-compose service name); livekit_public_url
    # is what the Flutter app connects to -- same internal/public split as
    # s3_endpoint_url/s3_public_endpoint_url above.
    livekit_api_key: str = "devkey"
    livekit_api_secret: str = "dev-livekit-secret-change-me-min-32-bytes"
    livekit_url: str = "ws://livekit:7880"
    livekit_public_url: str = "ws://localhost:7880"

    # Gemini (existing AI Smart Match enrichment)
    gemini_api_key: str = ""
    match_cache_ttl_seconds: float = 600
    match_cache_maxsize: int = 500
    gemini_max_concurrent: int = 3
    match_timeout_seconds: float = 8.0

    # Embedding model (fastembed-supported, 384-dim, multilingual incl. Thai)
    embedding_model_name: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384

    # Omise (Opn Payments) -- payment gateway. Use pkey_test_/skey_test_ keys
    # from the Omise dashboard while developing; swap to pkey_live_/skey_live_
    # only once ready to take real money.
    omise_public_key: str = ""
    omise_secret_key: str = ""

    # Seed admin
    seed_admin_email: str = "admin@petpal.app"
    seed_admin_password: str = "ChangeMe123!"
    seed_technician_email: str = "technician@petpal.app"
    seed_technician_password: str = "ChangeMe123!"


@lru_cache
def get_settings() -> Settings:
    return Settings()
