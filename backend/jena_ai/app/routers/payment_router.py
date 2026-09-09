from fastapi import APIRouter

from app.models.payment_webhook import PaymentWebhookRequest, PaymentWebhookResult
from app.services.payment_webhook_service import PaymentWebhookService

router = APIRouter(prefix="/payments", tags=["payments"])
service = PaymentWebhookService()


@router.post("/webhook", response_model=PaymentWebhookResult)
def handle_payment_webhook(request: PaymentWebhookRequest) -> PaymentWebhookResult:
    return service.handle_webhook(request)
