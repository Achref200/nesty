/// Turns a Postgres/PostgREST error into something worth showing a person.
///
/// The database is where Nesty's booking rules actually live — the exclusion
/// constraint that makes double-booking impossible, the trigger that refuses a
/// blocked date, the RLS policies. When one of them fires, the message that
/// comes back is written for a developer:
///
///   conflicting key value violates exclusion constraint
///   "reservations_no_active_overlap"
///
/// Showing that to an agency owner in Sousse is not an option. These map the
/// handful we can actually provoke onto plain sentences, and anything
/// unrecognised falls back to a neutral line rather than leaking internals.
///
/// Mirrors `describe()` in `nesty-web/src/lib/actions/reservations.ts` — keep
/// the two in step so both surfaces explain a refusal the same way.
library;

const _fallback = 'That didn\'t go through. Please try again.';

String describeDbError(String raw) {
  final low = raw.toLowerCase();

  // The no-double-booking guarantee.
  if (low.contains('exclusion') ||
      low.contains('overlap') ||
      low.contains('23p01')) {
    return 'Those dates overlap a booking that is already pending or confirmed.';
  }

  // The trigger guarding manually blocked periods.
  if (low.contains('blocked')) {
    return 'Those dates are blocked on this listing.';
  }

  // A migration hasn't been applied to this project yet.
  if (low.contains('does not exist') ||
      low.contains('schema cache') ||
      low.contains('could not find') ||
      low.contains('column')) {
    return 'This feature isn\'t available on your account yet. '
        'Contact Nesty and we\'ll switch it on.';
  }

  // RLS said no — the row exists but isn't theirs.
  if (low.contains('row-level') || low.contains('permission denied')) {
    return 'You don\'t have access to that.';
  }

  if (low.contains('violates check constraint')) {
    return 'That change isn\'t allowed at this stage of the booking.';
  }

  if (low.contains('network') ||
      low.contains('socket') ||
      low.contains('timeout') ||
      low.contains('failed host lookup')) {
    return 'We couldn\'t reach Nesty. Check your connection and try again.';
  }

  return _fallback;
}
