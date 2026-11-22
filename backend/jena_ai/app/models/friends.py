"""Friend connection request and response models."""

from pydantic import BaseModel, Field


class FriendInviteResult(BaseModel):
    token: str
    # What the QR code carries: "sharerun-friend:<token>".
    qr_payload: str
    expires_at: str  # ISO 8601


class FriendAcceptRequest(BaseModel):
    # The format is checked by the service so a bad token gets the same
    # 400 "invalid" as a token that does not exist.
    token: str = Field(default="", max_length=256)


class FriendAcceptResult(BaseModel):
    status: str  # "added" | "already_friends"
    friend_uid: str


class FriendView(BaseModel):
    uid: str
    nickname: str
    created_at: str | None = None


class FriendList(BaseModel):
    friends: list[FriendView]


class FriendRemoveRequest(BaseModel):
    friend_uid: str = Field(default="", max_length=256)


class FriendRemoveResult(BaseModel):
    status: str  # "removed" | "not_friends"


class FriendBlockRequest(BaseModel):
    target_uid: str = Field(default="", max_length=256)
    report_reason: str | None = Field(default=None, max_length=64)


class FriendBlockResult(BaseModel):
    status: str  # "blocked"
