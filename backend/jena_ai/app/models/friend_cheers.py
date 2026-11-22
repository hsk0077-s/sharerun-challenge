"""Friend cheer request and response models."""

from pydantic import BaseModel, Field


class FriendRunView(BaseModel):
    activity_id: str
    friend_uid: str
    nickname: str
    distance_km: float
    duration_seconds: int
    kst_date: str
    my_reaction: str | None = None


class FriendRunList(BaseModel):
    runs: list[FriendRunView]


class CheerSendRequest(BaseModel):
    friend_uid: str = Field(default="", max_length=256)
    activity_id: str = Field(default="", max_length=256)
    reaction: str = Field(default="", max_length=32)


class CheerSendResult(BaseModel):
    status: str  # "sent"


class CheerView(BaseModel):
    from_uid: str
    nickname: str
    activity_id: str
    reaction: str
    created_at: str | None = None


class CheerInbox(BaseModel):
    cheers: list[CheerView]
    unread_count: int


class CheerSeenResult(BaseModel):
    status: str  # "ok"


class CheerSettingsRequest(BaseModel):
    mute_all: bool | None = None
    friend_uid: str | None = Field(default=None, max_length=256)
    muted: bool | None = None


class CheerSettings(BaseModel):
    mute_all: bool
    muted_friends: list[str]
