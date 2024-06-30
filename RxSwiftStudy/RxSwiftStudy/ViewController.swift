//
//  ViewController.swift
//  RxSwiftTest
//
//  Created by 이민재 on 6/25/24.
//

import UIKit
import RxSwift
import RxRelay

class ViewController: UIViewController {
    // DisposeBag
    private let bag = DisposeBag()
    // image Relay 생성
    private var images = BehaviorRelay<[UIImage]>(value: [])
    
    private var imageCache = [Int]()
    // UI Property
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images
            .asObservable()
            .throttle(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak imagePreview] photos in
                guard let preview = imagePreview else { return }
                print("VC viewDidLoad subscribe")
                preview.image = UIImage.collage(images: photos, size: preview.frame.size)
            })
            .disposed(by: bag)
        // images를 구독하므로써, 새로운 값이 들어오면(on Next) preview.image가 변경됨
        images
            .asObservable()
            .subscribe(onNext: { [weak self] photos in
                print("VC viewDidLoad asObservable")
                self?.updateUI(photos: photos)
            })
            .disposed(by: bag)
    }
    
    @IBAction func actionSave(_ sender: Any) {
        guard let image = imagePreview.image else { return }
        
        PhotoWriter.save(image)
            .asSingle()
            .subscribe(
                onSuccess: { [weak self] id in
                    self?.actionClear(self?.clearButton)
                },
                onFailure: { [weak self] error in
                }
            )
            .disposed(by: bag)
    }
    @IBAction func actionClear(_ sender: Any) {
        images.accept([])
        imageCache = []
    }
    @IBAction func tappedAddItemsButton(_ sender: Any) {
        let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        let newPhotos = photosViewController.selectedPhotos.share()
        newPhotos
            .take(while: { [weak self] image in
                return (self?.images.value.count ?? 0) < 6
            })
            .filter({ newImage in
                return newImage.size.width > newImage.size.height
            })
            .filter({ [weak self] newImage in
                let len = newImage.pngData()?.count ?? 0
                guard self?.imageCache.contains(len) == false else { return false }
                self?.imageCache.append(len)
                return true
            })
            .subscribe(onCompleted: { [weak self] in
                self?.updateNavigationIcon()
            })
            .disposed(by: photosViewController.bag)
        
        photosViewController.selectedPhotos
            .subscribe(onNext: { [weak self] newImage in
                            guard let images = self?.images else { return }
                            print("VC selectedPhotos subscribe")
                            images.accept(images.value + [newImage])
                        },
                       onDisposed: {
                            print("completed photo selection")
            })
            .disposed(by: bag)
        navigationController?.pushViewController(photosViewController, animated: true)
    }
    private func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
    private func updateUI(photos: [UIImage]) {
        saveButton.isEnabled = photos.count > 0 && photos.count % 2 == 0
        clearButton.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}



extension UIViewController {
    func alert(title: String, text: String?) -> Completable {
        return Completable.create(subscribe: { [weak self] completable in
            let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .default, handler: { _ in
                completable(.completed)
            })
            alertVC.addAction(closeAction)
            self?.present(alertVC,animated: true, completion: nil)
            
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        })
    }
}
