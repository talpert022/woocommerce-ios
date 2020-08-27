import Storage
import CoreData
import Combine

@available(iOS 13.0, *)
public final class DiffableResultsController: NSObject {

    public typealias Snapshot = NSDiffableDataSourceSnapshot<String, NSManagedObjectID>

    private let storage: StorageType

    private lazy var resultsController: NSFetchedResultsController<StorageOrder> = {
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
        try resultsController.performFetch()
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
