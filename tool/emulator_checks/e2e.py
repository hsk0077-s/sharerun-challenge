import os, sys, traceback
from types import SimpleNamespace
from datetime import datetime, timezone, timedelta
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../backend/jena_ai'))
from google.cloud import firestore
from fastapi import HTTPException
from app.services.secured_action_service import SecuredActionService
from app.services.ops_service import OpsService
from app.models.secured_actions import JoinTournamentRequest

db = firestore.Client(project='demo-sr')
fs = SimpleNamespace(db=db)
svc = SecuredActionService(firebase_service=fs)
svc._ensure_email_verified = lambda uid: None
svc.ensure_signup_free_ticket = lambda uid: None
ops = OpsService(firebase_service=fs)
out = []
def check(name, cond, extra=''):
    out.append(('PASS ' if cond else 'FAIL ') + name + (' ' + str(extra) if not cond else ''))

now = datetime.now(timezone.utc)
db.document('users/w').set({'gradeRank': 12, 'tier': 1, 'authCreatedAt': (now - timedelta(days=90)).isoformat(),
    'wallet': {'shareBalance': 5000, 'freeShareBalance': 5000, 'paidShareBalance': 0,
               'diamondBalance': 50, 'freeDiamondBalance': 0, 'paidDiamondBalance': 50, 'valueTokenBalance': 0}})
# 1. ticket purchase: paid dia refused
try:
    svc.purchase_shop_item('w', 'challenge_ticket', 'req-dia-0001', 'dia'); check('paid DIA refused', False)
except HTTPException as e:
    check('paid DIA refused', e.status_code == 400, e.detail)
r = svc.purchase_shop_item('w', 'challenge_ticket', 'req-share-0001', 'share')
check('buy with SHARE', r.status == 'purchased' and r.share_balance == 3800, r)
r2 = svc.purchase_shop_item('w', 'challenge_ticket', 'req-share-0001', 'share')
check('retry charges once', r2.status == 'already_purchased' and db.document('users/w').get().to_dict()['wallet']['shareBalance'] == 3800)
check('inventory 1', db.document('users/w/shopInventory/challenge_ticket').get().to_dict()['quantity'] == 1)
# 2. tournaments through ops
ops.create_ranked_tournament('up', kind='tier', title='말 5km', target_distance_km=5, tier_animal=4, entry_fee_share=100)
ops.create_ranked_tournament('same', kind='tier', title='늑대 5km', target_distance_km=5, tier_animal=3, entry_fee_share=100)
ops.create_ranked_tournament('low', kind='tier', title='말티즈', target_distance_km=5, tier_animal=2, entry_fee_share=100)
def join(tid, uid='w'):
    return svc.join_tournament(uid, JoinTournamentRequest(tournament_id=tid))
try: join('low'); check('lower tournament refused', False)
except HTTPException as e: check('lower tournament refused', e.status_code == 403, e.detail)
r = join('up')
check('one step up joins with ticket', r.status == 'joined', r)
check('ticket spent', db.document('users/w/shopInventory/challenge_ticket').get().to_dict()['quantity'] == 0)
check('marked challengedUp', db.document('tournaments/up/participants/w').get().to_dict().get('challengedUp') is True)
# 3. settle with real batch writes
ids = [f'p{i}' for i in range(9)]
for i, u in enumerate(ids):
    db.document(f'users/{u}').set({'gradeRank': 17, 'authCreatedAt': (now - timedelta(days=90)).isoformat()})
    db.document(f'tournaments/up/participants/{u}').set({'uid': u, 'verifiedFinish': True, 'durationSeconds': 1000 + i, 'distanceKm': 5})
db.document('tournaments/up/participants/w').update({'verifiedFinish': True, 'durationSeconds': 1500, 'distanceKm': 5})
db.document('tournaments/up').update({'status': 'active'})
res = ops.settle_company_tournament('up')
check('settled 10 finishers', res.status == 'settled' and res.finisher_count == 10, res)
led = db.document('promotion' + 'Ledger/up__p0').get().to_dict()
check('winner 40x1.0x1.0 points', led and led['points'] == 40, led)
w = db.document('promotionLedger/up__w').get().to_dict()
check('challenger bonus 1.2x', w and w['points'] == int(3 * 1.0 * 1.0 * 1.2), w)
check('winner state saved', db.document('users/p0').get().to_dict()['promotion']['points'] >= 0)
again = ops.settle_company_tournament('up')
check('second settle is a no-op', again.status == 'already_settled')
n = len(list(db.collection('promotionLedger').where('tournamentId', '==', 'up').stream()))
check('ledger rows == 10', n == 10, n)
print('\n'.join(out))
sys.exit(0 if all(l.startswith('PASS') for l in out) else 1)
