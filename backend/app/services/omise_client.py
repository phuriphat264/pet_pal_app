import httpx

from ..core.config import get_settings

OMISE_API_BASE = "https://api.omise.co"
_REQUEST_TIMEOUT_SECONDS = 15


def _auth() -> httpx.BasicAuth:
    return httpx.BasicAuth(get_settings().omise_secret_key, "")


async def create_card_charge(amount: int, currency: str, token: str, description: str) -> dict:
    async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT_SECONDS) as client:
        response = await client.post(
            f"{OMISE_API_BASE}/charges",
            auth=_auth(),
            data={"amount": amount, "currency": currency, "card": token, "description": description},
        )
        response.raise_for_status()
        return response.json()


async def create_promptpay_charge(amount: int, currency: str, description: str) -> dict:
    async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT_SECONDS) as client:
        source_response = await client.post(
            f"{OMISE_API_BASE}/sources",
            auth=_auth(),
            data={"amount": amount, "currency": currency, "type": "promptpay"},
        )
        source_response.raise_for_status()
        source_id = source_response.json()["id"]

        charge_response = await client.post(
            f"{OMISE_API_BASE}/charges",
            auth=_auth(),
            data={"amount": amount, "currency": currency, "source": source_id, "description": description},
        )
        charge_response.raise_for_status()
        return charge_response.json()


async def retrieve_charge(charge_id: str) -> dict:
    async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT_SECONDS) as client:
        response = await client.get(f"{OMISE_API_BASE}/charges/{charge_id}", auth=_auth())
        response.raise_for_status()
        return response.json()


async def create_refund(charge_id: str, amount: int) -> dict:
    async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT_SECONDS) as client:
        response = await client.post(
            f"{OMISE_API_BASE}/charges/{charge_id}/refunds",
            auth=_auth(),
            data={"amount": amount},
        )
        response.raise_for_status()
        return response.json()
