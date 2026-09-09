from fastapi import APIRouter

from app.models.validation_request import ValidationRequest
from app.models.validation_result import ValidationResult
from app.services.running_validation_service import RunningValidationService

router = APIRouter()
service = RunningValidationService()


@router.post("/validate-run", response_model=ValidationResult)
def validate_run(request: ValidationRequest) -> ValidationResult:
    return service.validate(request)
