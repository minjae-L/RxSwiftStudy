import UIKit
import RxSwift

var start = 0
func getStartNumber() -> Int {
    start += 1
    return start
}

let number = Observable<Int>.create { observer in
    let start = getStartNumber()
    observer.onNext(start)
    observer.onNext(start+1)
    observer.onNext(start+2)
    observer.onCompleted()
    return Disposables.create()
}

number
    .subscribe(onNext: { el in
        print("element [\(el)]")
    },onCompleted: {
        print("--------------")
    })
number
    .subscribe(onNext: { el in
        print("element [\(el)]")
    },onCompleted: {
        print("--------------")
    })
print(start)
