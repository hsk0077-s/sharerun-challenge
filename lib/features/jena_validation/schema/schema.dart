/// SRC standard running payload schema consumed by the Jena AI validation engine.
///
/// Version: src.running.v1
///
/// Legal note: [SrcRunningPayload.biometrics] heart-rate and cadence series are
/// EPHEMERAL. They must never be written to Firestore or any durable store.
/// Only validation summaries (jenaVerified, decision, reward) may persist.
library;

export 'src_running_payload.dart';
export 'src_running_payload_normalizer.dart';
