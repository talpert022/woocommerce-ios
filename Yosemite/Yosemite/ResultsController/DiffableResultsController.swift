import Storage
import CoreData
import Combine

@available(iOS 13.0, *)
public final class DiffableResultsController: NSObject {

    public typealias Snapshot = NSDiffableDataSourceSnapshot<String, NSManagedObjectID>

    private let storage: StorageType

    private lazy var wrappedController: NSFetchedResultsController<StorageOrder> = {
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)
        let fetchRequest = NSFetchRequest<StorageOrder>(entityName: StorageOrder.entityName)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let resultsController = storage.createFetchedResultsController(fetchRequest: fetchRequest,
                                                                       sectionNameKeyPath: nil,
                                                                       cacheName: nil)
        resultsController.delegate = self
        return resultsController
    }()

    private let snapshotSubject = CurrentValueSubject<Snapshot, Never>(Snapshot())

    public var snapshot: AnyPublisher<Snapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    public init(storage: StorageType) {
        self.storage = storage
    }

    public func performFetch() throws {
        try wrappedController.performFetch()
    }

    /// Indicates if there are any Objects matching the specified criteria.
    ///
    public var isEmpty: Bool {
        return wrappedController.fetchedObjects?.isEmpty ?? true
    }

    /// Returns the fetched object at the given `indexPath`. Returns `nil` if the `indexPath`
    /// does not exist.
    ///
    public func object(at indexPath: IndexPath) -> Order? {
        guard !isEmpty else {
            return nil
        }
        guard let sections = wrappedController.sections, sections.count > indexPath.section else {
            return nil
        }

        let section = sections[indexPath.section]

        guard section.numberOfObjects > indexPath.row else {
            return nil
        }

        return wrappedController.object(at: indexPath).toReadOnly()
    }

    public func object(withID managedObjectID: NSManagedObjectID) -> Order? {
        #warning("we don't want NSManagedObjectID :D. Fix this later")
        let context = storage as! NSManagedObjectContext
        if let storageOrder = try? context.existingObject(with: managedObjectID) as? StorageOrder {
            return storageOrder.toReadOnly()
        } else {
            return nil
        }
    }
}

@available(iOS 13.0, *)
extension DiffableResultsController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as Snapshot
        snapshotSubject.send(snapshot)
    }
}
