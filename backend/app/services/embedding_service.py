"""Local text embeddings for semantic hotel matching.

Uses fastembed (ONNX runtime, no PyTorch) with a small multilingual model
that handles Thai well. Embeddings are computed locally -- no network call,
no API quota -- so matching stays fast even under load.
"""

from functools import lru_cache

from fastembed import TextEmbedding

from ..core.config import get_settings

settings = get_settings()


@lru_cache
def _model() -> TextEmbedding:
    return TextEmbedding(model_name=settings.embedding_model_name)


def embed_passage(text: str) -> list[float]:
    vector = next(iter(_model().embed([text])))
    return vector.tolist()


def embed_query(text: str) -> list[float]:
    vector = next(iter(_model().embed([text])))
    return vector.tolist()


def embed_hotel_text(
    name: str, description: str, tags: list[str] | None, ai_tags: list[str] | None
) -> list[float]:
    combined = " | ".join(
        filter(None, [name, description, ", ".join(tags or []), ", ".join(ai_tags or [])])
    )
    return embed_passage(combined)
