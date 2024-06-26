import UIKit
import RxSwift

public func example(of description: String, action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

example(of: "just, of, from") {
    let one = 1
    let two = 2
    let three = 3
    
    let observable = Observable.of(one, two, three)
    
}

example(of: "subscribe") {
    let one = 1
    let two = 2
    let three = 3
    
    let observable = Observable.of(one, two, three)
    observable.subscribe({ (event) in
        print(event)
    })
    observable.subscribe(onNext: { (element) in
        print(element)
    })
}

example(of: "Empty") {
    let observable = Observable<Void>.empty()
    
    observable.subscribe(
        onNext: { (element) in
            print(element)
        },
        onCompleted: {
            print("completed")
        }
    )
}

example(of: "never") {
    let observable = Observable<Any>.never()
    observable
        .subscribe(
            onNext: { (element) in
                print(element)
            },
            onCompleted: {
                print("Completed")
            }
        )
}

example(of: "range") {
    let observable = Observable<Int>.range(start: 1, count: 10)
    observable
        .subscribe(
            onNext: { (i) in
                let n = Double(i)
                let fibonacci = Int(((pow(1.61803, n) - pow(0.61803, n)) / 2.23606).rounded())
                print(fibonacci)
            }
        )
}
example(of: "dispose") {
    let observable = Observable.of("A","B","C")
    let subscription = observable.subscribe({ (event) in
        print(event)
    })
    subscription.dispose()
}

example(of: "disposeBag") {
    let disposeBag = DisposeBag()
    
    Observable.of("A","B","C")
        .subscribe{
            print($0)
        }
        .disposed(by: disposeBag)
}
enum MyError: Error {
    case anError
}
example(of: "create") {
    let disposeBag = DisposeBag()
    
    Observable<String>.create { (observer) -> Disposable in
        observer.onNext("1")
        observer.onError(MyError.anError)
        observer.onCompleted()
        observer.onNext("?")
        
        return Disposables.create()
    }
    .subscribe(
        onNext: { print($0) },
        onError: { print($0) },
        onCompleted: { print("Completed") },
        onDisposed: { print("Disposed") }
    )
    .disposed(by: disposeBag)
}

example(of: "deferred") {
    let disposeBag = DisposeBag()
    
    var flip = false
    
    let factory = Observable<Int>.deferred {
        flip = !flip
        
        if flip {
            return Observable.of(1,2,3)
        } else {
            return Observable.of(4,5,6)
        }
    }
    for _ in 0...3 {
        factory.subscribe(onNext: {
            print($0, terminator: "")
        })
        .disposed(by: disposeBag)
        
        print()
    }
}

example(of: "single") {
    let disposebag = DisposeBag()
    
    enum FailReadError: Error {
        case fileNotFound, unreadable, encodingFailed
    }
    
    func loadText(from name: String) -> Single<String> {
        return Single.create{ single in
            let disposable = Disposables.create()
            
            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                single(.failure(FailReadError.fileNotFound))
                return disposable
            }
            
            guard let data = FileManager.default.contents(atPath: path) else {
                single(.failure(FailReadError.unreadable))
                return disposable
            }
            
            guard let contents = String(data: data, encoding: .utf8) else {
                single(.failure(FailReadError.encodingFailed))
                return disposable
            }
            
            single(.success(contents))
            return disposable
        }
    }
    loadText(from: "CopyRight")
        .subscribe{
            switch $0 {
            case .success(let string):
                print(string)
            case .failure(let error):
                print(error)
            }
        }
        .disposed(by: disposebag)
}

example(of: "never") {
    let observable = Observable<Any>.never()
    let disposeBag = DisposeBag()

//    observable.do(
//        onSubscribe: { print("Subscribed")}
//    ).subscribe(
//        onNext: {
//            print("OnNext")
//            print($0)
//        },
//        onCompleted: { print("Completed")}
//    ).disposed(by: disposeBag)
    
//    observable.do(
//        onSubscribe: { print("Subscribed")}
//    ).debug("never 디버그")
//    .subscribe(
//        onNext: {
//            print("OnNext")
//            print($0)
//        },
//        onCompleted: { print("Completed")}
//    ).disposed(by: disposeBag)
    
    observable.do(
        onSubscribe: { print("Subscribed") }
    ).debug("never 디버그")
    .subscribe()
        .disposed(by: disposeBag)
    
}

example(of: "PublishSubject") {
    let subject = PublishSubject<String>()
    
    subject.onNext("Is anuone listening?")
    
    let subscriptionOne = subject
        .subscribe(onNext: { (string) in
            print(string)
        })
    subject.on(.next("1"))
    subject.onNext("2")
    let subscriptionTwo = subject
        .subscribe({ (event) in
            print("2)", event.element ?? event)
        })
    subject.onNext("3")
    
    subscriptionOne.dispose()
    subject.onNext("4")
    
    subject.onCompleted()
    
    subject.onNext("5")
    
    subscriptionTwo.dispose()
    
    let disposeBag = DisposeBag()
    
    subject
        .subscribe{
            print("3)", $0.element ?? $0)
        }
        .disposed(by: disposeBag)
    
    subject.onNext("?")
    
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    print(label, event.element ?? event.error ?? event)
}

example(of: "BehaviorSubject") {
    let subject = BehaviorSubject(value: "Initial value")
    let disposeBag = DisposeBag()
    
    subject.onNext("X")
    
    subject
        .subscribe{
            print(label: "1)", event: $0)
        }
        .disposed(by: disposeBag)
    
    subject.onError(MyError.anError)
    
    subject
        .subscribe{
            print(label: "2)", event: $0)
        }
        .disposed(by: disposeBag)
}

example(of: "ReplaySubject") {
    let subject = ReplaySubject<String>.create(bufferSize: 2)
    let disposeBag = DisposeBag()
    
    subject.onNext("1")
    subject.onNext("2")
    subject.onNext("3")
    
    subject
        .subscribe {
            print(label: "1)", event: $0)
        }
        .disposed(by: disposeBag)
    subject
        .subscribe {
            print(label: "2)", event: $0)
        }
        .disposed(by: disposeBag)
    
    subject.onNext("4")
    subject.onError(MyError.anError)
    subject.dispose()
    subject
        .subscribe{
            print(label: "3)", event: $0)
        }
        .disposed(by: disposeBag)
    
}

example(of: "ignoreElements") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .ignoreElements()
        .subscribe({ _ in
            print("You're out!")
        })
        .disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onCompleted()
}


example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .element(at: 2)
        .subscribe(onNext: { _ in
            print("You're out!")
        })
        .disposed(by: disposeBag)
    
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
}

example(of: "filter") {
    let disposeBag = DisposeBag()
    
    Observable.of(1,2,3,4,5,6)
        .filter({ (int) -> Bool in
            int % 2 == 0
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "skip") {
    let disposeBag = DisposeBag()
    
    Observable.of(1,2,3,4,5,6)
        .skip(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "skipWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2,2,3,4,4,2)
        .skip(while: {(int) -> Bool in
              int % 2 == 0
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "skipUntil") {
    let disposeBag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject
        .skip(until: trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    subject.onNext("A")
    subject.onNext("B")
    subject.onNext("C")
    
    trigger.onNext("X")
    
    subject.onNext("C")
}

example(of: "take") {
    let disposeBag = DisposeBag()
    
    Observable.of(1,2,3,4,5,6)
        .take(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "takeWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2,2,4,4,6,6)
        .enumerated()
        .take(while: {index, value in
            value % 2 == 0 && index < 3
        })
        .map { $0.element }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "takeUntil") {
    let disposeBag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    subject.take(until: trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    subject.onNext("1")
    subject.onNext("2")
    
    trigger.onNext("X")
    
    subject.onNext("3")
    
}

example(of: "distincUntilChanged") {
    let disposeBag = DisposeBag()
    
    Observable.of("A","A","B","B","A")
        .distinctUntilChanged()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

example(of: "distincUntileChanged(_:)") {
    let disposeBag = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(10,110,20,200,210,310)
        .distinctUntilChanged({ a, b in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
                  let bWords = formatter.string(from: b)?.components(separatedBy: " ") else { return false }
            var containsMatch = false
            for aWord in aWords {
                for bWord in bWords {
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }
            return containsMatch
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}
