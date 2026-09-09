from pydantic import BaseModel, Field


class PaymentWebhookRequest(BaseModel):
    payment_intent_id: str
    pg_transaction_id: str
    status: str = Field(pattern="^(paid|failed|cancelled)$")
    amount: int = Field(gt=0)
    currency: str = "KRW"
    signature: str


class PaymentWebhookResult(BaseModel):
    accepted: bool
    payment_intent_id: str
    status: str
    reason: str
