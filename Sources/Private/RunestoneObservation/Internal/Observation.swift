final class Observation {
    private final class WeakObserver {
        private(set) weak var observer: (any Observer)?

        init(_ observer: some Observer) {
            self.observer = observer
        }
    }
    
    let id: ObservationId
    let propertyChangeId: PropertyChangeId
    let handler: AnyObservationChangeHandler

    private let weakObserver: WeakObserver

    init<T>(
        observer: some Observer,
        propertyChangeId: PropertyChangeId,
        handler: @escaping ObservationChangeHandler<T>
    ) {
        self.id = ObservationId()
        self.propertyChangeId = propertyChangeId
        self.weakObserver = WeakObserver(observer)
        self.handler = AnyObservationChangeHandler(handler)
    }

    func invokeCancelOnObserver() {
        weakObserver.observer?.cancelObservation(withId: id)
    }
}