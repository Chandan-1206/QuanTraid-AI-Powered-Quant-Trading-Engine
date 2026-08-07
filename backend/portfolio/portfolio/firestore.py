# backend/portfolio/firestore.py
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from core.firebase import db  # synchronous Firestore client from firebase_admin


def _portfolio_ref(uid: str):
    return db.collection("users").document(uid).collection("portfolio").document("holdings")


def _history_ref(uid: str):
    return db.collection("users").document(uid).collection("optimisation_history")


def save_portfolio(uid: str, holdings: List[Dict]) -> None:
    """Upsert user's holdings document in Firestore."""
    _portfolio_ref(uid).set({
        "holdings": holdings,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    })


def get_portfolio(uid: str) -> Optional[List[Dict]]:
    """Fetch user's holdings. Returns None if not found."""
    doc = _portfolio_ref(uid).get()
    if not doc.exists:
        return None
    return doc.to_dict().get("holdings", [])


def save_optimisation_result(uid: str, result: Dict[str, Any]) -> None:
    """Store optimisation result in history subcollection."""
    ts = datetime.now(timezone.utc).isoformat()
    _history_ref(uid).document(ts).set({**result, "created_at": ts})


def get_optimisation_history(uid: str, limit: int = 5) -> List[Dict]:
    """Fetch last `limit` optimisation results, newest first."""
    docs = (
        _history_ref(uid)
        .order_by("created_at", direction="DESCENDING")
        .limit(limit)
        .get()
    )
    return [d.to_dict() for d in docs]


def delete_portfolio(uid: str) -> None:
    """Delete user's holdings document."""
    _portfolio_ref(uid).delete()
