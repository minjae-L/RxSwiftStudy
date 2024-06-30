//
//  PHPhotoLibrary+rx.swift
//  RxSwiftStudy
//
//  Created by 이민재 on 6/30/24.
//

import Foundation
import RxSwift
import Photos

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        return Observable<Bool>.create { observer in
            DispatchQueue.main.async {
                if authorizationStatus() == .authorized {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    requestAuthorization { newStatus in
                        observer.onNext(newStatus == .authorized)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
}
