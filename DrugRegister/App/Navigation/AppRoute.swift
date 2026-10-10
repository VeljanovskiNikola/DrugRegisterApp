/// Every screen you can push onto the stack.
/// The list already has the full drug, so the detail screen needs no extra request.
enum AppRoute: Hashable {
    case drugDetail(Drug)
    case document(DrugDocument)
    /// A saved medicine's drug. It loads fresh data and falls back to the snapshot.
    case savedDrug(DrugSnapshot)
}
