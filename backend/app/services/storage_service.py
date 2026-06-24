"""MinIO (S3-compatible) object storage for partner application documents
(ID cards, business licenses, shop photos). Uploads go directly from the
client to MinIO via presigned PUT URLs -- the backend never proxies file
bytes. The bucket is private: these documents contain real PII (ID cards),
so reads are also presigned (time-limited GET URLs) rather than a public
bucket policy, which would otherwise make every uploaded ID card readable
by anyone who guessed/intercepted its URL.
"""

import uuid

import aioboto3
from botocore.config import Config

from ..core.config import get_settings

settings = get_settings()

PRESIGNED_EXPIRY_SECONDS = 600

_session = aioboto3.Session()


def _client_kwargs() -> dict:
    return {
        "endpoint_url": settings.s3_endpoint_url,
        "aws_access_key_id": settings.s3_access_key,
        "aws_secret_access_key": settings.s3_secret_key,
        "region_name": settings.s3_region,
        "config": Config(signature_version="s3v4"),
    }


async def ensure_bucket() -> None:
    async with _session.client("s3", **_client_kwargs()) as s3:
        try:
            await s3.head_bucket(Bucket=settings.s3_bucket)
        except Exception:
            await s3.create_bucket(Bucket=settings.s3_bucket)
        try:
            # Revoke any public-read policy left over from an older deploy of
            # this app (or manual misconfiguration) -- the bucket must stay
            # private since it holds real ID documents.
            await s3.delete_bucket_policy(Bucket=settings.s3_bucket)
        except Exception:
            pass


def build_object_key(category: str, owner_id: uuid.UUID, filename: str) -> str:
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    return f"{category}/{owner_id}/{uuid.uuid4()}.{ext}"


async def presigned_put_url(key: str, content_type: str = "application/octet-stream") -> str:
    async with _session.client("s3", **_client_kwargs()) as s3:
        return await s3.generate_presigned_url(
            "put_object",
            Params={"Bucket": settings.s3_bucket, "Key": key, "ContentType": content_type},
            ExpiresIn=PRESIGNED_EXPIRY_SECONDS,
        )


async def presigned_get_url(key: str, expires_in: int = PRESIGNED_EXPIRY_SECONDS) -> str:
    async with _session.client("s3", **_client_kwargs()) as s3:
        return await s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket, "Key": key},
            ExpiresIn=expires_in,
        )
