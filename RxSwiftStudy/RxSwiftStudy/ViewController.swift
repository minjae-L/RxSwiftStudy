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
    private let bag = DisposeBag()
    private var images = BehaviorRelay<[UIImage]>(value: [])
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images
            .subscribe(onNext: { [weak imagePreview] photos in
                guard let preview = imagePreview else { return }
                preview.image = UIImage.collage(images: photos, size: preview.frame.size)
            })
            .disposed(by: bag)
        
        images.asObservable()
            .subscribe(onNext: { [weak self] photos in
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
//                    self?.showMessage()
                    self?.actionClear(self?.clearButton)
                },
                onFailure: { [weak self] error in
//                    self?.showMessager()
                }
            )
            .disposed(by: bag)
    }
    @IBAction func actionClear(_ sender: Any) {
        images.accept([])
    }
    @IBAction func tappedAddItemsButton(_ sender: Any) {
        let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        photosViewController.selectedPhotos
            .subscribe(onNext: { [weak self] newImage in
                            guard let images = self?.images else { return }
                            images.accept(images.value + [newImage])
                        },
                       onDisposed: {
                            print("completed photo selection")
            })
            .disposed(by: bag)
        navigationController?.pushViewController(photosViewController, animated: true)
    }
    private func updateUI(photos: [UIImage]) {
        saveButton.isEnabled = photos.count > 0 && photos.count % 2 == 0
        clearButton.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}

