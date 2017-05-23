import Foundation
import enum Result.NoError

/// Represents the lifetime of an object, and provides a hook to observe when
/// the object deinitializes.
public final class Lifetime {
	private let disposables: CompositeDisposable

	/// A signal that sends a `completed` event when the lifetime ends.
	///
	/// - note: Consider using `Lifetime.observeEnded` if only a closure observer
	///         is to be attached.
	public var ended: Signal<Never, NoError> {
		return Signal { observer, lifetime in
			let disposable = (disposables += observer.sendCompleted)
			_ = (disposable?.dispose).map(lifetime.observeEnded)
		}
	}

	/// A flag indicating whether the lifetime has ended.
	public var hasEnded: Bool {
		return disposables.isDisposed
	}

	/// Initialize a `Lifetime` object with the supplied composite disposable.
	///
	/// - parameters:
	///   - signal: The composite disposable.
	internal init(_ disposables: CompositeDisposable) {
		self.disposables = disposables
	}

	/// Initialize a `Lifetime` from a lifetime token, which is expected to be
	/// associated with an object.
	///
	/// - important: The resulting lifetime object does not retain the lifetime
	///              token.
	///
	/// - parameters:
	///   - token: A lifetime token for detecting the deinitialization of the
	///            associated object.
	public convenience init(_ token: Token) {
		self.init(token.disposables)
	}

	/// Observe the termination of `self`.
	///
	/// - parameters:
	///   - action: The action to be invoked when `self` ends.
	///
	/// - returns: A disposable that detaches `action` from the lifetime, or `nil`
	///            if `lifetime` has already ended.
	@discardableResult
	public func observeEnded(_ action: @escaping () -> Void) -> Disposable? {
		return disposables += action
	}
}

extension Lifetime {
	/// Factory method for creating a `Lifetime` and its associated `Token`.
	///
	/// - returns: A `(lifetime, token)` tuple.
	public static func make() -> (lifetime: Lifetime, token: Token) {
		let token = Token()
		return (Lifetime(token), token)
	}

	/// A `Lifetime` that has already ended.
	public static let empty: Lifetime = {
		let disposables = CompositeDisposable()
		disposables.dispose()
		return Lifetime(disposables)
	}()
}

extension Lifetime {
	/// A token object which completes its signal when it deinitializes.
	///
	/// It is generally used in conjuncion with `Lifetime` as a private
	/// deinitialization trigger.
	///
	/// ```
	/// class MyController {
	///		private let (lifetime, token) = Lifetime.make()
	/// }
	/// ```
	public final class Token {
		/// A signal that sends a Completed event when the lifetime ends.
		fileprivate let disposables: CompositeDisposable

		public init() {
			disposables = CompositeDisposable()
		}

		deinit {
			disposables.dispose()
		}
	}
}
